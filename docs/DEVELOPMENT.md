[Japanese version is here](DEVELOPMENT.ja.md)

# Development Environment

You can set up the development environment in two ways:

- (A) Using Docker Compose (recommended if you have Docker installed)
- (B) Without Docker (for environments where Docker is not available)

After cloning the repository, choose one of the following methods to set up your environment.

## (A) Using Docker Compose

With the Compose settings, the current directory on the host is mounted as the top-level application directory inside the container. This means that any changes made to the source code on the host are immediately reflected in the application running inside the container.

### A-1. Build and start the container

This starts a Rails console inside the container, which is used only to keep the container running.
The Rails server does not start automatically, so continue operating inside the container as described below.

```
$ docker compose up --build
```

### A-2. Run Rails commands

Before running the application, make sure to set the required environment variables. Most essential settings are already configured at build time, but see [/docs/ENVIRONMENT_VARIABLES.md](/docs/ENVIRONMENT_VARIABLES.md) for details.

Rails-related commands should be run inside the container. In the examples below, the commands are executed from the host shell by using `docker compose exec web ...`.

On the first run, set up the database manually as follows:

```
$ docker compose exec web bin/rails db:prepare
```

Depending on your development needs, you can run any Rails command inside the container, such as starting the server or running migrations.

```
# Start the server
$ docker compose exec web bin/rails s -b 0.0.0.0 -p 3000
```

```
# Run migrations or other Rails commands
$ docker compose exec web bin/rails db:migrate
```

### A-3. Access from your browser on the host

```
# Application
http://127.0.0.1:3000/

# MailCatcher Web UI
http://127.0.0.1:1080/
```

### A-4. Optional: GUI browser for debugging via VNC

If you need to debug system specs or visually inspect the browser locally, you can install Chromium and a VNC server inside the container and use them. See the following documents for detailed instructions:

- [/docs/SETUP_BROWSER.md](/docs/SETUP_BROWSER.md)
- [/docs/SETUP_VNC.md](/docs/SETUP_VNC.md)

## (B) Without Docker

### B-1. Prepare the database

First, set up the database:

```
$ bin/rails db:prepare
```

### B-2. Environment variables

Set the necessary environment variables to run the application. See [/docs/ENVIRONMENT_VARIABLES.md](/docs/ENVIRONMENT_VARIABLES.md).

### B-3. Run the application

Once everything is configured, start the web server with the following command:

```
$ bin/rails s -b 0.0.0.0 -p 3000
```

Then access the homepage in your browser.

## Change the Admin Password

When initializing the database, the seed process creates an administrator user in the `users` table. Change the administrator user's password using the Rails console or a similar method:

```
$ bin/rails c
> user = User.admin_user
> user.password = 'YOU MUST CHANGE THIS!'
> user.save!
```

Note: In the current version, do not change any values other than the password.

## Build Tailwind CSS

This project uses Tailwind for CSS. Before starting the server for the first time, build the CSS files with the following command:

```
$ bin/rails tailwindcss:build
```

Whenever you make changes to the CSS, you need to rebuild it. During development, it is convenient to run `bin/rails tailwindcss:watch` concurrently for automatic Tailwind CSS builds. You can also use `bin/dev` to launch multiple processes at once.

-----

# Customization Guide

If you plan to use this application as a base for your own extensions, use this section as a reference guide.

## Project Structure

This project follows the standard Ruby on Rails directory structure and conventions. If you want to add new features or customize the application, follow the Rails way for controllers, models, views, and configuration.

If custom features that deviate from the standard are added in the future, they will be documented in this section.

## I18n (Locales)

This application follows the [internationalization section of the Rails Guides](https://guides.rubyonrails.org/i18n.html) for internationalization setup. For per-request locale selection, URL parameters are used, and locale is mandatory in routing.

```
scope ":locale", locale: /en|ja/ do
  ...
```

The default locale is `en`.

Translations are available for both `en` and `ja`. When adding new items, update both translation files.

A rake task is provided to check whether other language translation items are sufficient or excessive compared with the default locale.

```
$ rails -T | grep locale
bin/rails locale:check                       # Check locale file structure consistency
bin/rails locale:diff                        # Show locale structure differences
$ bin/rails locale:check
[SUCCESS] All app-defined locale files have consistent structure
$ bin/rails locale:diff
Base locale (en) has 95 keys (app-defined only)
============================================================

JA locale:
  Total keys: 95
  [Perfect] match with base locale
$
```

For implementation details around locales, see [/docs/LOCALE_SYSTEM_DESCRIPTION.md](/docs/LOCALE_SYSTEM_DESCRIPTION.md).

## Flash Messages

For flash messages, the gem `flash_unified` is used. This gem was originally developed experimentally in this project and then extracted and published as a standalone gem.

For more details, see the gem's project page: [https://github.com/hiroaki/flash-unified](https://github.com/hiroaki/flash-unified).

## Testing

RSpec tests are provided. Since Capybara uses cuprite as its `javascript_driver`, Google Chrome is required in the test environment.

```
$ bin/rspec
```

For OAuth (GitHub) tests, you cannot simultaneously test both contexts, enabled and disabled. This is because the enabled or disabled state is determined during Rails initialization. Therefore, you need to run the RSpec tests twice in separate processes.

To test with OAuth enabled, run RSpec as usual. To test with OAuth disabled, set the environment variable `RSPEC_DISABLE_OAUTH_GITHUB` to `1` and specify the directory `spec/system/oauth_github_disabled/` as the target. You may run all spec files, but currently only the tests placed in `spec/system/oauth_github_disabled/` are for the OAuth-disabled context.

```
$ RSPEC_DISABLE_OAUTH_GITHUB=1 bin/rspec spec/system/oauth_github_disabled/
```

When writing tests affected by this context, add the tags `oauth_github_required` and `oauth_github_disabled` to the relevant blocks. Tests with the `oauth_github_required` tag run only when OAuth is enabled, and tests with the `oauth_github_disabled` tag are skipped. The reverse also applies.

When you run RSpec, a coverage report is generated by SimpleCov as `coverage/index.html`. Check the results there. Also, when you run the test suite twice using `RSPEC_DISABLE_OAUTH_GITHUB`, the coverage results are automatically merged if you run them consecutively.

If you want to observe the browser during system spec debugging, you can disable headless mode by setting the `HEADLESS` environment variable to `0` when running RSpec. You can also set the `SLOWMO` environment variable to add a delay in seconds between each step. Insert `binding.pry` where you want execution to pause, and run the following command:

```
$ HEADLESS=0 SLOWMO=0.5 bin/rspec ./spec/system/something_spec.rb:123
```

This idea was inspired by [Upgrading from Selenium to Cuprite](https://janko.io/upgrading-from-selenium-to-cuprite/). Thank you.