[Japanese version is here](SETUP_VNC.ja.md)

# Install TigerVNC and Control Chromium Through a GUI

This document explains how to install a VNC server (TigerVNC/Xvnc) inside the container so that you can control Chromium and similar applications through a GUI from the host machine.

VNC is optional. If you only need to use the browser in headless mode, or if you do not need a GUI for other reasons, you do not need to follow these steps. The browser installation procedure is documented in [docs/SETUP_BROWSER.md](/docs/SETUP_BROWSER.md).

## Background

Chrome or Chromium is required for RSpec system tests, but the tests can run in headless mode even without a GUI.

However, during failure investigation or manual verification, there are times when you want to see the browser window directly. For that purpose, this setup uses lightweight TigerVNC (Xvnc) and Fluxbox so that you can open a GUI session only when needed.

## Prerequisites

- The development environment uses the top-level `Dockerfile` and `compose.yml`
- The container is already running

```bash
$ docker compose up
```

## Expose the Port

VNC uses TCP port 5901. For security reasons, it is recommended to expose this port only on the host's loopback address. Also, because VNC uses plaintext communication, consider using an SSH tunnel or VNC over TLS if you need a more secure connection.

Create a personal `compose.override.yml` file in the top-level directory and do not commit it to the repository. Docker Compose loads it automatically when starting the container.

Example `compose.override.yml`:

```yaml
services:
  web:
    ports:
      - "127.0.0.1:5901:5901"
```

## 1. Install VNC-related packages

Install as the root user. A batch script is provided for this:

```bash
$ docker compose exec --user root web bash -lc \
  "/bin/bash /rails/scripts/install-vnc-tigervnc.sh"
```

This script does the following:

- Installs `tigervnc-standalone-server`, `tigervnc-common`, `tigervnc-tools`, `fluxbox`, and `autocutsel`
- Creates the `rails` user if it does not already exist
- Prepares `/tmp/.X11-unix`

## 2. Start the VNC server

Start it with an arbitrary password using the provided batch script:

```bash
$ docker compose exec web bash -lc \
  "VNC_PASSWORD='set-your-vnc-pass' VNC_DISPLAY_NUMBER=1 VNC_GEOMETRY='1280x800' /bin/bash /rails/scripts/vnc-start.sh"
```

Batch scripts are also available to stop the server and check its status:

```bash
$ docker compose exec web bash -lc "/bin/bash /rails/scripts/vnc-stop.sh"
$ docker compose exec web bash -lc "/bin/bash /rails/scripts/vnc-status.sh"
```

`vnc-start.sh` copies `scripts/xstartup.template` to `~/.vnc/xstartup` before starting. You can edit that template if you need to customize the session.

## 3. Connect from the host

- Destination: `127.0.0.1:5901`
- Password: the password specified when starting the VNC server

TigerVNC can be used as the VNC client, but its stability may vary. That may be related to the author's older macOS version, Monterey, but one confirmed working version was `TigerVNC Viewer 1.12.0.app`. Even in that version, opening the `Option...` menu sometimes caused a crash. The newer `TigerVNC Viewer 1.15.0.app` could open `Option...`, but crashed when connecting. As a result, the author used 1.15.0 to set options and 1.12.0 to actually connect.

The macOS built-in Screen Sharing app can also be used, although clipboard support is not available. However, the connection is stable, so if that clipboard limitation is acceptable, it is a practical option.

## 4. Run RSpec and Cuprite while watching the screen

If you want to watch the browser screen while running system tests, specify `HEADLESS=0` and `DISPLAY=:1`. The use of the `HEADLESS` environment variable is defined in `spec/support/capybara.rb`, along with other cuprite driver options.

```bash
$ docker compose exec web bash -lc "HEADLESS=0 DISPLAY=:1 bundle exec rspec spec/system"
```

## Troubleshooting

- Cannot connect
  Check whether the port mapping in `compose.override.yml` is active with `docker compose ps`.
  On the container side, run `vncserver -list` or `pgrep -a Xvnc` to confirm that the process is alive.

- The screen is completely black
  Check whether `fluxbox` and `chromium` are installed, and try running `/rails/scripts/vnc-start.sh` manually.

- Password-related problems
  Check the permissions of `~/.vnc/passwd` so that they are `600`, and confirm that the file is not empty.
  Stop VNC, rerun the installation script as root to ensure `vncpasswd` is available, then restart VNC.