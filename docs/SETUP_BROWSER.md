[Japanese version is here](SETUP_BROWSER.ja.md)

# Install and Set Up the Chromium Browser

This document explains how Chromium is provided for RSpec system tests in the Docker-based development environment.

## Background

This project uses a shared Dockerfile for development, CI, staging, and production. Chromium is needed for system specs and local browser debugging, but it should not be included in the production-oriented runtime image.

To balance those requirements, the Dockerfile exposes multiple final targets. Docker Compose uses `runtime-dev`, and CI uses `runtime-test`. Both targets include Chromium, while the deployment target `runtime` does not.

## Prerequisites

- The development environment uses the top-level `Dockerfile` and `compose.yml`
- The container is already running

```bash
$ docker compose up
```

## Availability

No manual installation is required in the current Docker workflow.

- `docker compose build web` builds the `runtime-dev` target, which already includes Chromium
- GitHub Actions builds the `runtime-test` target, which also includes Chromium
- The deployment target `runtime` intentionally excludes Chromium

If you changed the Dockerfile or are updating from an older image, rebuild the container image:

```bash
$ docker compose build web
```

## Using It with RSpec

By default, RSpec runs the browser in headless mode, so no extra setup is required.

```bash
$ docker compose exec web bash -lc "bundle exec rspec spec/system"
```

You can disable headless mode with the environment variable `HEADLESS=0`, but in that case an X display is required, so set it up with VNC as described in [docs/SETUP_VNC.md](/docs/SETUP_VNC.md).

## Troubleshooting

- Chromium cannot be found or does not start
  Rebuild the `web` image so that the `runtime-dev` target is recreated:

  ```bash
  $ docker compose build --no-cache web
  ```