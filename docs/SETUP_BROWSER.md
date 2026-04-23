[Japanese version is here](SETUP_BROWSER.ja.md)

# Install and Set Up the Chromium Browser

This document explains how to install the Chromium browser used in RSpec system tests into the development container.

## Background

This project uses a shared Dockerfile for both development and deployment-oriented environments. Chromium is needed only for specific development tasks such as system specs and visual browser debugging, so it is treated as an optional tool rather than a default dependency.

Keeping Chromium out of the base image helps keep the shared image smaller, reduces build time, and avoids increasing the maintenance surface of the default container environment. For that reason, the browser is not included in the image by default and is instead installed afterward only when needed.

## Prerequisites

- The development environment uses the top-level `Dockerfile` and `compose.yml`
- The container is already running

```bash
$ docker compose up
```

## Steps

Install as the root user. A batch script is provided for this:

```bash
$ docker compose exec --user root web bash -lc \
  "/bin/bash /rails/scripts/install-browser-chromium.sh"
```

This script does the following:

- Installs `chromium` itself and basic fonts such as Liberation and Noto
- Creates compatibility symlinks from `/usr/bin/google-chrome` and `/usr/bin/chromium-browser` to `chromium`

## Using It with RSpec

By default, RSpec runs the browser in headless mode, so no extra setup is required.

```bash
$ docker compose exec web bash -lc "bundle exec rspec spec/system"
```

You can disable headless mode with the environment variable `HEADLESS=0`, but in that case an X display is required, so set it up with VNC as described in [docs/SETUP_VNC.md](/docs/SETUP_VNC.md).

## Troubleshooting

- Chromium cannot be found or does not start
  Re-run the installer after updating `apt`:

  ```bash
  $ docker compose exec --user root web bash -lc "apt-get update -qq && /bin/bash /rails/scripts/install-browser-chromium.sh"
  ```