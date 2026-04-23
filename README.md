![Coveralls](https://img.shields.io/coverallsCoverage/github/hiroaki/Annabelle?branch=develop)

[日本語版はこちら](README.ja.md)

# Annabelle

Annabelle is a lightweight message board developed as part of my personal Ruby on Rails training. It is intended for exchanging files and messages between PCs and smartphones on a local area network (LAN). As it includes experimental features, it is not recommended for public use or access by the general public.

## Features

### Realtime Messaging

Messages posted or deleted by other users are instantly reflected on the screen via Action Cable. It can also be used like a chat interface.

### File Upload

Multiple files can be selected and uploaded at once as message attachments. (Note: Currently, uploaded files are saved unencrypted on the local disk.)

### Layout

The screen layout is designed for quick and easy preview of uploaded media such as images and videos. On desktop screens, the right half of the screen is used for previews, while on mobile devices, previews are shown in a modal window.

### Preview Features

Supported media for preview. More media types will be supported in future updates:
- Text
- Images (with location shown on OpenStreetMap if available)
- Videos
- GPX (location and tracks shown on OpenStreetMap)

### User Authentication

Users can sign in using either their email address or via OAuth (currently, only GitHub is supported). OAuth is optional. Even when registering via OAuth, the user account will be created based on the email address retrieved during authentication.

### Two Factor Authentication

An additional option for user authentication is available: two-factor authentication (2FA) using time-based one-time passwords (TOTP).

This implementation is based on an article by James Ridgway, which was extremely helpful. Thank you.

[Implementing OTP two-factor authentication as a second login step with Rails and Devise](https://www.jamesridgway.co.uk/implementing-a-two-step-otp-u2f-login-workflow-with-rails-and-devise/)

### Basic Authentication

In addition to user authentication, Basic Authentication can also be enabled. While user authentication allows registered users to access the site, enabling Basic Authentication provides an extra layer of access control for the entire site.

## Requirements

### Image Processing Library

This project uses the image_processing gem for Active Storage image and video processing.

For better compatibility with older operating systems and environments, ImageMagick is selected as the default backend. Therefore, you need to have ImageMagick installed. However, if you can use libvips, you may install and use it instead of ImageMagick.

### Video Processing

To generate previews (thumbnails) or perform transcoding for video files uploaded via Active Storage, you must have `ffmpeg` installed on your system.

### SMTP Server

A valid email address is required for sign-up, and the email address serves as the account identifier. Therefore, SMTP server configuration is required.

### Google Chrome Browser

For testing, this project uses the cuprite (gem) as the driver for Capybara. Therefore, the test environment requires the Google Chrome browser.

### Database

This project uses SQLite3 as its database. No separate database server process is required.

### GitHub Account

To enable GitHub OAuth authentication, a GitHub OAuth App must be created for the project.

## Environment Setup

### Development Environment

See [/docs/DEVELOPMENT.md](/docs/DEVELOPMENT.md). If you have Docker Compose available, you can start the development environment simply by building:

```
$ docker compose up --build
```

### Staging Environment

See [/docs/DEPLOY.md](/docs/DEPLOY.md)

## Operation

### Session information Cleanup

Session information is stored in the database using [activerecord-session_store](https://github.com/rails/activerecord-session_store). Since old session records will remain unless cleaned up, please make sure to delete them periodically. A rake task is provided for this purpose, which deletes sessions older than 30 days by default. To specify a different threshold, set the number of days via the SESSION_DAYS_TRIM_THRESHOLD environment variable before running the task.

```
$ SESSION_DAYS_TRIM_THRESHOLD=30 bin/rails db:sessions:trim
```

### Active Storage Cleanup

A rake task is available to safely clean up orphaned Active Storage blobs (for example, when a message is deleted but its attachments are not physically removed).

```bash
# Dry run (no deletion)
$ bin/rake active_storage:cleanup

# Execute deletion (enqueue purge_later)
$ bin/rake active_storage:cleanup FORCE=true

# Target orphaned blobs older than 7 days (default: 2)
$ bin/rake active_storage:cleanup FORCE=true DAYS_OLD=7
```

## License

This project is licensed under the Zero-Clause BSD License (0BSD). See the [LICENSE](LICENSE) file for details.
