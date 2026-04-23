[Japanese version is here](DEPLOY.ja.md)

# Deploy

Deployment environments can vary greatly depending on the user, so it is not possible to provide a universal, step-by-step guide. However, this project includes Kamal (installed via Bundler) as a deployment tool, and you can use Kamal for deployment.

## Dockerfile

The Dockerfile located at the top level of the project is intended for both staging and production environments. You can use it to build Docker images for deployment. Please note that this Dockerfile is designed for the environment described in the "Configuration" section below. If your requirements differ, feel free to customize it as needed.

**Note:**
When building this Dockerfile, you must specify the `RAILS_ENV` build argument as either "staging" or "production". This argument is not automatically set from your environment variables, so be sure to specify it explicitly as shown below:

```
# Production
$ docker build --build-arg RAILS_ENV=production -t annabelle-production:latest .
```

```
# Staging
$ docker build --build-arg RAILS_ENV=staging -t annabelle-staging:latest .
```

**Important:**
The build context will include all files in the current directory, including files not tracked by git. Be careful not to include any sensitive information in your image.

---

# Example: Deploying a Staging Environment with Kamal

Below is an example procedure for deploying to a staging environment using Kamal.

## Configuration

This example assumes the following architecture:

```
                   User (Developer)
==================================================================
      |                    |                       |      Local PC
      v deploy             |                       |
 +------------------+      |                       |
 | kamal            |      |                       |
 | -docker-registry |      |                       |
 +------------------+      |                       |
   |                       |                       |
==[22]===================[443]==================[1080]============
   |                       |                       |       Staging
   |                       v access                |
   | pull       +-------------+                    |
   +----------->| kamal-proxy |                    |
   |            +-------------+                    |
   |               |                               |
   |               v forward                       |
   | pull         3001                             v access
   |    +----------------+     send mail      +-------------+
   +--> | thruster       |-------------> 1025 | MailCatcher |
        |  -> 3000 Rails |    "kamal"         +-------------+
        +----------------+    Network              ^ pull
===================================================|==============
                                                   |      Internet
                                            +~~~~~~~~~~~~+
                                            | Docker Hub |
                                            +~~~~~~~~~~~~+
```

- The "Developer" and "User" represent a developer who tests the staging environment and performs deployments and service access.
- The entry point is `kamal-proxy`, which also acts as the SSL terminator (port 443).
- The application server uses `thruster` as a wrapper for Puma, listening on port 3001.
- Mail sent from Rails is handled by MailCatcher (SMTP), with communication over the internal Docker network "kamal".
- The MailCatcher web interface is exposed directly on port 1080, without passing through the proxy.
- In this staging setup, all roles are deployed on a single host, even though the diagram shows them separately.

  ```
    proxy.ssl.host = servers.web.host = accessories.host
    +----------------------------------------------------+
    | +-----------+   +----------------+   +-----------+ |
    | |kamal-proxy|   |thruster + Rails|   |MailCatcher| |
    | +-----------+   +----------------+   +-----------+ |
    +----------------------------------------------------+
  ```

## Docker Engine on the Target Host

This example assumes that Docker Engine is already running on the target server.

Kamal can install Docker automatically, but this requires logging in as the `root` user via SSH and continued root access. In this example, the SSH user for deployment is specified via the `DEPLOY_SSH_USER` environment variable and is assumed to be a regular user.

To allow a regular user to create Docker containers, ensure that the user belongs to the `docker` group. If not, add the user as follows:

```sh
$ sudo usermod -aG docker <username>
```

If Docker Engine is not yet installed, you can install it as shown below (example for Rocky Linux 9). Note: Rootless mode is untested; please perform the installation as a privileged user.

```sh
# Example for Rocky Linux 9
$ sudo dnf install -y dnf-plugins-core
$ sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
$ sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
$ sudo systemctl enable --now docker
```

## Persistent Volumes

You need to create a directory to be used as a volume for the application's Docker container, and set its path in the `DEPLOY_VOLUMES_STORAGE` environment variable.

```sh
$ mkdir $HOME/data
```

This directory must be created before the first deployment. If you forget to create it, the application may fail to start after deployment. In that case, please check that the application has write permissions to the directory and adjust the permissions if necessary.

## config/deploy.yml

The Kamal configuration file `config/deploy.yml` contains only the setting `require_destination: true`. This indicates that a separate configuration file is required for each deployment target, and you must specify the destination when running Kamal.

For staging, a sample file `config/deploy.staging.yml.sample` is provided. Copy it to `config/deploy.staging.yml` and customize as needed.

In this example configuration, no changes are required. All values to be changed are read from environment variables, which are described later.

## .kamal/secrets

Sensitive information referenced in `config/deploy.staging.yml` is managed separately in `.kamal/secrets`. There is also a separate secrets file for each deployment target; for staging, use `.kamal/secrets.staging`.

If you have not modified `config/deploy.staging.yml`, you do not need to change `.kamal/secrets.staging` either. All values are read from environment variables.

## Container Registry

In Kamal deployments, the built image is pushed to a container registry.

Starting with Kamal version 2.8, you can specify a local Docker container registry running on the host machine, so using an external container registry service is no longer strictly required.

If you use an external service, you will need an account for that service. If you use a local container registry, Kamal will set it up automatically during deployment, so no additional configuration is needed.

## SSL (TLS) Certificates and hosts File

Kamal can automatically generate and renew certificates using Let's Encrypt. However, for a LAN-based staging environment, this example uses `mkcert` to create a local root CA, which must be installed on both the user's and the deployment target's environments.

The Common Name (hostname) must be resolvable, so register it in `/etc/hosts` if necessary. If you have a DNS server for your LAN, that is also sufficient.

## Environment Variables

Set the required environment variables for application and deployment configuration.

For details on application and deployment environment variables, see [/docs/ENVIRONMENT_VARIABLES.md](/docs/ENVIRONMENT_VARIABLES.md).

## Running the Deployment

After setting the environment variables in your shell, proceed with deployment. For the initial deployment, deploy the accessory first, then deploy the main application:

```
$ bundle exec kamal accessory boot mailcatcher --destination=staging
```

Next, deploy the main application:

```
$ bundle exec kamal deploy --destination=staging
```

If you are using dotenv, you can specify the `.env.staging` file as follows:

```
$ dotenv -f .env.staging bundle exec kamal accessory boot mailcatcher --destination=staging
$ dotenv -f .env.staging bundle exec kamal deploy --destination=staging
```

If your directory is not under git control, specify the version with the `--version ...` option:

```
$ dotenv -f .env.staging bundle exec kamal deploy --destination=staging --version=12345
```