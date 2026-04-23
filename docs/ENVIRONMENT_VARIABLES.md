[Japanese version is here](ENVIRONMENT_VARIABLES.ja.md)

# Environment Variables

Annabelle uses two main categories of environment variables: those related to application behavior, and those related to deployment. For development and test environments, deployment-related variables are not required and can be ignored. Likewise, if you create your own Kamal deployment configuration, you do not need to use the deployment-related environment variables described here.

If you are using dotenv, rename one of the sample files and use it as your environment file. Three sample `.env` files are provided for production, staging, and development environments. These are not generic templates, but starting points. Review the explanation for each environment variable below and set the values as needed.

| File Name | Purpose / Description |
|---|---|
| dot.env.development.sample | Sample for development. No deployment-related environment variables are included. |
| dot.env.staging.sample | Intended for building a staging environment. Contains the variables needed for the configuration described in DEPLOY.md and pairs with `config/deploy.staging.yml`. |
| dot.env.production.sample | Intended for production use. It is almost the same as the staging sample, except for the `proxy.ssl` settings. Use it as a reference. |

**Important:**
Many of the environment variables described below contain sensitive information such as passwords, encryption keys, and API secrets. Never commit them to your repository or share them publicly.

## Application Settings

These environment variables control application behavior.

### SMTP Settings

Set the following variables for SMTP configuration:

```
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_DOMAIN=example.com
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password
```

In development or staging environments, you may leave `SMTP_USERNAME` and `SMTP_PASSWORD` empty if they are not required.

### Mailer Settings

User login and registration are implemented using the devise gem. Set the sender email address for emails sent from devise.

```
DEVISE_MAILER_SENDER=admin@example.com
```

### App Host

These variables are also used to indicate the application's location in outgoing emails.

```
APP_HTTP_HOST=www.example.com
APP_HTTP_PORT=443
APP_HTTP_PROTOCOL=https
```

### SECRET_KEY_BASE

Required in production and staging environments. `SECRET_KEY_BASE` is used for encrypting sessions, cookies, and other sensitive data. Once set, do not change this key, as it will invalidate all existing sessions and encrypted data.

Use a sufficiently long random string for security, for example, 64 hexadecimal characters (256 bits) or a 32-byte base64 string. Generate one with the command below:

```bash
$ bin/rails secret
7f1bbba9cbbd1999fd641b80861ac989807eb8fbdd...
$
```

Set the generated value like this:

```
SECRET_KEY_BASE=7f1bbba9cbbd1999fd641b80861ac989807eb8fbdd...
```

### Two-Factor Authentication

Set this variable to enable two-factor authentication. If you enable two-factor authentication, you must also set the Active Record encryption variables described in the next section.

```
ENABLE_2FA=1
```

### Active Record Encryption

Active Record encryption configuration is required for the two-factor authentication implementation. These values can be generated using `bin/rails db:encryption:init`. Copy the strings output to the screen and set them to these environment variables:

```
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=1a2b3c4d5e6f7g8h9i0j...
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=0j9i8h7g6f5e4d3c2b1a...
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=abcdef1234567890...
```

### OAuth (GitHub Authentication)

To use GitHub OAuth authentication, first create an OAuth App for your project on GitHub. You will be asked to enter a callback URL path. For development environments, use the following path, replacing the hostname and port as appropriate for your environment:

```
http://127.0.0.1:3000/users/auth/github/callback
```

After creating the app, set the following variables using the Client ID and Client Secret provided by GitHub:

```
GITHUB_CLIENT_ID=Ov23abcde...
GITHUB_CLIENT_SECRET=abcdef0123456789abcdef...
```

### Client-side Request Size Limit

This application does not enforce request size limits internally. Instead, it assumes that such limits are handled by the proxy server.

However, to provide immediate feedback to users before a request is actually sent, the client performs a size check when submitting forms. Set the maximum allowed size in bytes for this client-side check.

This value should align with `DEPLOY_PROXY_BUFFERING_MAX_REQUEST_BODY`, but for safety, set it slightly lower to allow some margin.

```
MAX_REQUEST_BODY=10485760
```

### Basic Authentication

Setting these values enables Basic Authentication.

```
ENABLED_BASIC_AUTH=1
BASIC_AUTH_PAIRS=guest:annabelle,readonly:readonlypass
```

`ENABLED_BASIC_AUTH` controls whether Basic Authentication is enabled. When enabled, `BASIC_AUTH_PAIRS` is required for credentials.

`BASIC_AUTH_PAIRS` supports multiple `username:password` pairs separated by commas.

### Rack::Attack Configuration

These variables control optional Rack::Attack-based throttling and blocking. At the moment this is intended as a demo-oriented defensive feature, not as a full production-grade rate limiting design.

```
ENABLED_RACK_ATTACK=1
RACK_ATTACK_GET_THROTTLE_LIMIT=300
RACK_ATTACK_WRITE_THROTTLE_LIMIT=60
RACK_ATTACK_THROTTLE_PERIOD_SECONDS=60
RACK_ATTACK_BAN_DURATION_SECONDS=600
```

`ENABLED_RACK_ATTACK` enables or disables Rack::Attack entirely.

`RACK_ATTACK_GET_THROTTLE_LIMIT` is the maximum number of GET or HEAD requests allowed from a single IP during one throttle period.

`RACK_ATTACK_WRITE_THROTTLE_LIMIT` is the maximum number of non-GET and non-HEAD requests allowed from a single IP during one throttle period.

`RACK_ATTACK_THROTTLE_PERIOD_SECONDS` is the period length in seconds used by both throttles.

`RACK_ATTACK_BAN_DURATION_SECONDS` is the ban duration in seconds applied when a request probes `/.env` or `/.env.*`.

Current default behavior:

- GET and HEAD requests are throttled per IP.
- Non-GET and non-HEAD requests are throttled per IP.
- Requests to `/.env` or `/.env.*` are immediately banned.
- The health check path `/up` is excluded from GET and HEAD throttling.

**Note:** With the current configuration, Rack::Attack state is effectively scoped to a single host. This setup is useful for single-host deployments, but if you later scale out to multiple application hosts, revisit the cache design and consider a shared external store such as Redis.

### Image Processing Backend

This project uses the `image_processing` gem for Active Storage image and video processing.

For development environments, ImageMagick is used by default to improve compatibility with older operating systems and setups. You must have ImageMagick installed on your system. If you want to use libvips instead, install libvips and set the environment variable `ANNABELLE_VARIANT_PROCESSOR` to `vips` before starting the application.

In production and staging environments, vips is installed during the Docker build process. Therefore, set `ANNABELLE_VARIANT_PROCESSOR` to `vips` at deployment time. The sample `config/deploy.staging.yml.sample` and `config/deploy.production.yml.sample` files already include this setting.

```
ANNABELLE_VARIANT_PROCESSOR=vips
```

## Deployment Settings

This section explains the environment variables you need to set when using the sample Kamal configuration files `config/deploy.*.yml.sample` for actual deployment.

Since deployment environments can vary greatly depending on the user, this project provides a sample Kamal configuration file for a specific deployment scenario. The sample is designed to be configured using the environment variables described below.

If your deployment environment differs from this example, feel free to create your own Kamal configuration file tailored to your environment. In that case, the environment variables described below are not required, and you can specify the values directly in your Kamal configuration file.

All deployment-related environment variables are prefixed with `DEPLOY_`.

**Important:**
Many of the environment variables described below contain sensitive information such as passwords, encryption keys, and API secrets. Never commit them to your repository or share them publicly.

### Container Registry Settings

When deploying with Kamal, the built Docker image is first pushed to a container registry. Therefore, you need a container registry that allows write access.

You can use a remote external service for the container registry, such as GitHub or Docker Hub, or you can use a local registry running on the Docker host machine.

To use a local registry on the host machine, specify `localhost`. Kamal will automatically create the local registry for you.

```
DEPLOY_REGISTRY_SERVER=localhost:5555
```

Alternatively, if you use an external container registry, set the account information accordingly. For the password, enter a personal access token or authentication token issued by the registry service.

```
DEPLOY_REGISTRY_SERVER=ghcr.io
DEPLOY_REGISTRY_USERNAME=yourname
DEPLOY_REGISTRY_PASSWORD=abcdefghijklmnopqrstuvwxyz_0123456789ABC
```

### Docker Image Name

Specify the name to use for the image when uploading it to the container registry.

```
DEPLOY_IMAGE=yourname/annabelle-production
```

### Deployment Hosts

Specify a comma-separated list of hosts where the application will be deployed.

```
DEPLOY_SERVERS_WEB_HOSTS="www1.example.com"
```

### SSH Settings

These settings are used to log in to the deployment target hosts via SSH. The specified user must belong to the `docker` group on the target host. See [/docs/DEPLOY.md](/docs/DEPLOY.md) for details. `DEPLOY_SSH_KEYS` is a comma-separated list of private key file paths used for public-key or host-based authentication.

```
DEPLOY_SSH_PORT=22
DEPLOY_SSH_USER=operator
DEPLOY_SSH_KEYS="/home/operator/.ssh/id_rsa"
```

### Persistent Volumes

Specify the directory on the deployment host to be mounted as a volume in the Docker container. Annabelle stores both the SQLite3 database file and user-uploaded files in this directory.

```
DEPLOY_VOLUMES_STORAGE=/home/operator/data
```

To back up your data, simply back up this directory.

### Proxy Settings

Set `DEPLOY_PROXY_HOST` to the host where `kamal-proxy` is deployed. This value should be specified as the domain name that matches the Common Name in your SSL or TLS server certificate.

```
DEPLOY_PROXY_HOST=www.example.com
```

`DEPLOY_PROXY_BUFFERING_MAX_REQUEST_BODY` sets the maximum request size in bytes allowed by the proxy. If a request exceeds this size, the proxy returns HTTP status 413 and the request does not reach the application. The value of `MAX_REQUEST_BODY` mentioned earlier should be based on this value.

```
DEPLOY_PROXY_BUFFERING_MAX_REQUEST_BODY=10485760
```

To use a custom SSL or TLS certificate, set the contents of the PEM-formatted certificate and private key directly in the corresponding environment variables.

```
DEPLOY_CERTIFICATE_PEM="-----BEGIN CERTIFICATE-----
...
...
-----END CERTIFICATE-----
"

DEPLOY_PRIVATE_KEY_PEM="-----BEGIN PRIVATE KEY-----
...
...
-----END PRIVATE KEY-----
"
```

### MailCatcher Host

In the sample configuration for staging deployment, MailCatcher is set up as the SMTP service. MailCatcher is also configured to be deployed as an accessory with Kamal, so you need to specify the address of the host where MailCatcher will be deployed.

```
DEPLOY_ACCESSORIES_MAILCATCHER_HOST=
```