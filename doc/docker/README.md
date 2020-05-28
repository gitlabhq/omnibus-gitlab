# GitLab Docker images

The GitLab Docker images are monolithic images of GitLab running all the necessary
services in a single container.

Both GitLab CE and EE are in Docker Hub:

- [GitLab CE Docker image](https://hub.docker.com/r/gitlab/gitlab-ce/)
- [GitLab EE Docker image](https://hub.docker.com/r/gitlab/gitlab-ee/)

NOTE: **Note:**
To install GitLab on Kubernetes, take a look at
[GitLab Helm Charts](https://docs.gitlab.com/charts/).

In the following examples we are using the image of GitLab CE. To use GitLab EE
instead of GitLab CE, replace the image name to `gitlab/gitlab-ee:latest`.

If you want to use the latest RC image, use `gitlab/gitlab-ce:rc` or
`gitlab/gitlab-ee:rc` for GitLab CE and GitLab EE respectively.

Docker installation is required, see the [official installation docs](https://docs.docker.com/install/).

CAUTION: **Caution:**
Docker for Windows is not officially supported. There are known issues with volume
permissions, and potentially other unknown issues. If you are trying to run on Docker
for Windows, see the [getting help page](https://about.gitlab.com/get-help/) for links
to community resources (IRC, forum, etc.) to seek help from other users.

## Installation

The GitLab Docker images can be run in multiple ways:

- [Using Docker Engine](#install-gitlab-using-docker-engine)
- [Using Docker Compose](#install-gitlab-using-docker-compose)
- [Using Docker swarm mode](#install-gitlab-using-docker-swarm-mode)

### Install GitLab using Docker Engine

Before setting everything else, configure a new enviroment variable `$GITLAB_HOME`
pointing to the folder where the configuration, logs, and data files will reside.
Ensure that the folder exists and appropriate permission have been granted.

For Linux users set the path to `/srv`:

```shell
export GITLAB_HOME=/srv
```

For Mac OS users, use the user's `$HOME` folder:

```shell
export GITLAB_HOME=$HOME
```

The GitLab container uses host mounted volumes to store persistent data:

| Local location | Container location | Usage |
| -------------- | ------------------ | ----- |
| `$GITLAB_HOME/gitlab/data`  | `/var/opt/gitlab` | For storing application data |
| `$GITLAB_HOME/gitlab/logs`  | `/var/log/gitlab` | For storing logs |
| `$GITLAB_HOME/gitlab/config`| `/etc/gitlab`     | For storing the GitLab configuration files |

You can fine tune these directories to meet your requirements.
Once you've set up the `GITLAB_HOME` variable, you can run the image:

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/gitlab/config:/etc/gitlab \
  --volume $GITLAB_HOME/gitlab/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest
```

This will download and start a GitLab CE container and publish ports needed to
access SSH, HTTP and HTTPS. All GitLab data will be stored as subdirectories of
`$GITLAB_HOME/gitlab`. The container will automatically `restart` after a system reboot.

If you are on SELinux, then run this instead:

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/gitlab/config:/etc/gitlab:Z \
  --volume $GITLAB_HOME/gitlab/logs:/var/log/gitlab:Z \
  --volume $GITLAB_HOME/gitlab/data:/var/opt/gitlab:Z \
  gitlab/gitlab-ce:latest
```

This will ensure that the Docker process has enough permissions to create the
config files in the mounted volumes.

NOTE: **Note:**
You will also need to publish your Kerberos port (e.g., `--publish 8443:8443`)
if you are using the [Kerberos
integration](https://docs.gitlab.com/ee/integration/kerberos.html) **(STARTER ONLY)**.
Failure to do so will prevent Git operations via Kerberos.

The initialization process may take a long time. You can track this
process with:

```shell
sudo docker logs -f gitlab
```

After starting a container you can visit `gitlab.example.com` (or
`http://192.168.59.103` if you used boot2docker on macOS). It might take a while
before the Docker container starts to respond to queries.
The very first time you visit GitLab, you will be asked to set up the admin
password. After you change it, you can login with username `root` and the
password you set up.

### Install GitLab using Docker Compose

With [Docker Compose](https://docs.docker.com/compose/) you can easily configure,
install, and upgrade your Docker-based GitLab installation:

1. [Install Docker Compose](https://docs.docker.com/compose/install/).
1. Create a `docker-compose.yml` file (or [download an example](https://gitlab.com/gitlab-org/omnibus-gitlab/raw/master/docker/docker-compose.yml)):

   ```yaml
   web:
     image: 'gitlab/gitlab-ce:latest'
     restart: always
     hostname: 'gitlab.example.com'
     environment:
       GITLAB_OMNIBUS_CONFIG: |
         external_url 'https://gitlab.example.com'
         # Add any other gitlab.rb configuration here, each on its own line
     ports:
       - '80:80'
       - '443:443'
       - '22:22'
     volumes:
       - '$GITLAB_HOME/gitlab/config:/etc/gitlab'
       - '$GITLAB_HOME/gitlab/logs:/var/log/gitlab'
       - '$GITLAB_HOME/gitlab/data:/var/opt/gitlab'
   ```

1. Make sure you are in the same directory as `docker-compose.yml` and start
   GitLab:

   ```shell
   docker-compose up -d
   ```

TIP: **Tip:**
Read the ["Pre-configure Docker container"](#pre-configure-docker-container) section
to see how the `GITLAB_OMNIBUS_CONFIG` variable works.

Below is another `docker-compose.yml` example with GitLab running on a custom
HTTP and SSH port. Notice how the `GITLAB_OMNIBUS_CONFIG` variables match the
`ports` section:

```yaml
web:
  image: 'gitlab/gitlab-ce:latest'
  restart: always
  hostname: 'gitlab.example.com'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'http://gitlab.example.com:8929'
      gitlab_rails['gitlab_shell_ssh_port'] = 2224
  ports:
    - '8929:8929'
    - '2224:22'
  volumes:
    - '$GITLAB_HOME/gitlab/config:/etc/gitlab'
    - '$GITLAB_HOME/gitlab/logs:/var/log/gitlab'
    - '$GITLAB_HOME/gitlab/data:/var/opt/gitlab'
```

This is the same as using `--publish 8929:8929 --publish 2224:22`.

### Install GitLab using Docker swarm mode

With [Docker swarm mode](https://docs.docker.com/engine/swarm/), you can easily
configure and deploy your
Docker-based GitLab installation in a swarm cluster.

In swarm mode you can leverage [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
and [Docker configs](https://docs.docker.com/engine/swarm/configs/) to efficiently and securely deploy your GitLab instance.
Secrets can be used to securely pass your initial root password without exposing it as an environment variable.
Configs can help you to keep your GitLab image as generic as possible.

Here's an example that deploys GitLab with four runners as a [stack](https://docs.docker.com/get-started/part5/), using secrets and configs:

1. [Set up a Docker swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/).
1. Create a `docker-compose.yml` file:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: gitlab/gitlab-ce:latest
       ports:
         - "22:22"
         - "80:80"
         - "443:443"
       volumes:
         - $GITLAB_HOME/gitlab/data:/var/opt/gitlab
         - $GITLAB_HOME/gitlab/logs:/var/log/gitlab
         - $GITLAB_HOME/gitlab/config:/etc/gitlab
       environment:
         GITLAB_OMNIBUS_CONFIG: "from_file('/omnibus_config.rb')"
       configs:
         - source: gitlab
           target: /omnibus_config.rb
       secrets:
         - gitlab_root_password
     gitlab-runner:
       image: gitlab/gitlab-runner:alpine
       deploy:
         mode: replicated
         replicas: 4
   configs:
     gitlab:
       file: ./gitlab.rb
   secrets:
     gitlab_root_password:
       file: ./root_password.txt
   ```

   For simplicity reasons, the `network` configuration was omitted.
   More information can be found in the official [Compose file reference](https://docs.docker.com/compose/compose-file/).

1. Create a `gitlab.rb` file:

   ```ruby
   external_url 'https://my.domain.com/'
   gitlab_rails['initial_root_password'] = File.read('/run/secrets/gitlab_root_password')
   ```

1. Create a `root_password.txt` file:

   ```plaintext
   MySuperSecretAndSecurePass0rd!
   ```

1. Make sure you are in the same directory as `docker-compose.yml` and run:

   ```shell
   docker stack deploy --compose-file docker-compose.yml mystack
   ```

## Configuration

This container uses the official Omnibus GitLab package, so all configuration
is done in the unique configuration file `/etc/gitlab/gitlab.rb`.

To access GitLab's configuration file, you can start a shell session in the
context of a running container. This will allow you to browse all directories
and use your favorite text editor:

```shell
sudo docker exec -it gitlab /bin/bash
```

You can also just edit `/etc/gitlab/gitlab.rb`:

```shell
sudo docker exec -it gitlab editor /etc/gitlab/gitlab.rb
```

Once you open `/etc/gitlab/gitlab.rb` make sure to set the `external_url` to
point to a valid URL.

To receive e-mails from GitLab you have to configure the
[SMTP settings](../settings/smtp.md) because the GitLab Docker image doesn't
have an SMTP server installed. You may also be interested in
[enabling HTTPS](../settings/nginx.md#enable-https).

After you make all the changes you want, you will need to restart the container
in order to reconfigure GitLab:

```shell
sudo docker restart gitlab
```

NOTE: **Note:**
GitLab will reconfigure itself whenever the container starts.

For more options about configuring GitLab, check the
[configuration documentation](../settings/configuration.md).

### Pre-configure Docker container

You can pre-configure the GitLab Docker image by adding the environment
variable `GITLAB_OMNIBUS_CONFIG` to Docker run command. This variable can
contain any `gitlab.rb` setting and will be evaluated before loading the
container's `gitlab.rb` file. That way you can easily configure GitLab's
external URL, make any database configuration or any other option from the
[Omnibus GitLab template](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).

NOTE: **Note:**
The settings contained in `GITLAB_OMNIBUS_CONFIG` will not be written to the
`gitlab.rb` configuration file, they're evaluated on load.

Here's an example that sets the external URL and enables LFS while starting
the container:

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://my.domain.com/'; gitlab_rails['lfs_enabled'] = true;" \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/gitlab/config:/etc/gitlab \
  --volume $GITLAB_HOME/gitlab/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest
```

Note that every time you execute a `docker run` command, you need to provide
the `GITLAB_OMNIBUS_CONFIG` option. The content of `GITLAB_OMNIBUS_CONFIG` is
_not_ preserved between subsequent runs.

### Use tagged versions of GitLab

Tagged versions of the GitLab Docker images are also provided.
To see all available tags see:

- [GitLab CE tags](https://hub.docker.com/r/gitlab/gitlab-ce/tags/)
- [GitLab EE tags](https://hub.docker.com/r/gitlab/gitlab-ee/tags/)

To use a specific tagged version, replace `gitlab/gitlab-ce:latest` with
the GitLab version you want to run, for example `gitlab/gitlab-ce:12.1.3-ce.0`.

### Run GitLab on a public IP address

You can make Docker to use your IP address and forward all traffic to the
GitLab container by modifying the `--publish` flag.

To expose GitLab CE on IP `198.51.100.1`:

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --publish 198.51.100.1:443:443 \
  --publish 198.51.100.1:80:80 \
  --publish 198.51.100.1:22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/gitlab/config:/etc/gitlab \
  --volume $GITLAB_HOME/gitlab/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest
```

You can then access your GitLab instance at `http://198.51.100.1/` and `https://198.51.100.1/`.

### Expose GitLab on different ports

GitLab will occupy [some ports](../package-information/defaults.md)
inside the container.

If you want to use a different host port than `80` (HTTP) or `443` (HTTPS),
you need to add a separate `--publish` directive to the `docker run` command.

For example, to expose the web interface on the host's port `8929`, and the SSH service on
port `2289`:

1. Use the following `docker run` command:

   ```shell
   sudo docker run --detach \
     --hostname gitlab.example.com \
     --publish 8929:8929 --publish 2289:22 \
     --name gitlab \
     --restart always \
     --volume $GITLAB_HOME/gitlab/config:/etc/gitlab \
     --volume $GITLAB_HOME/gitlab/logs:/var/log/gitlab \
     --volume $GITLAB_HOME/gitlab/data:/var/opt/gitlab \
     gitlab/gitlab-ce:latest
   ```

   NOTE: **Note:**
   The format for publishing ports is `hostPort:containerPort`. Read more in
   Docker's documentation about
   [exposing incoming ports](https://docs.docker.com/engine/reference/run/#/expose-incoming-ports).

1. Enter the running container:

   ```shell
   sudo docker exec -it gitlab /bin/bash
   ```

1. Open `/etc/gitlab/gitlab.rb` with your editor and set `external_url`:

   ```ruby
   # For HTTP
   external_url "http://gitlab.example.com:8929"

   or

   # For HTTPS (notice the https)
   external_url "https://gitlab.example.com:8929"
   ```

   NOTE: **Note:**
   The port specified in this URL must match the port published to the host by Docker.
   Additionally, if the NGINX listen port is not explicitly set in
   `nginx['listen_port']`, it will be pulled from the `external_url`.
   For more information see the [NGINX documentation](../settings/nginx.md).

1. Set `gitlab_shell_ssh_port`:

   ```ruby
   gitlab_rails['gitlab_shell_ssh_port'] = 2289
   ```

1. Finally, reconfigure GitLab:

   ```shell
   gitlab-ctl reconfigure
   ```

Following the above example, you will be able to reach GitLab from your
web browser under `<hostIP>:8929` and push using SSH under the port `2289`.

A `docker-compose.yml` example that uses different ports can be found in the
[Docker compose](#install-gitlab-using-docker-compose) section.

## Update

In most cases, updating GitLab is as easy as downloading the newest Docker
[image tag](#use-tagged-versions-of-gitlab).

### Update GitLab using Docker Engine

To update GitLab that was [installed using Docker Engine](#install-gitlab-using-docker-engine):

1. Take a [backup](#back-up-gitlab).
1. Stop the running container:

   ```shell
   sudo docker stop gitlab
   ```

1. Remove the existing container:

   ```shell
   sudo docker rm gitlab
   ```

1. Pull the new image. For example, the latest GitLab CE image:

   ```shell
   sudo docker pull gitlab/gitlab-ce:latest
   ```

1. Create the container once again with the
[previously specified](#install-gitlab-using-docker-engine) options:

   ```shell
   sudo docker run --detach \
   --hostname gitlab.example.com \
   --publish 443:443 --publish 80:80 --publish 22:22 \
   --name gitlab \
   --restart always \
   --volume $GITLAB_HOME/gitlab/config:/etc/gitlab \
   --volume $GITLAB_HOME/gitlab/logs:/var/log/gitlab \
   --volume $GITLAB_HOME/gitlab/data:/var/opt/gitlab \
   gitlab/gitlab-ce:latest
   ```

On the first run, GitLab will reconfigure and update itself.

NOTE: **Note:**
Refer to the GitLab [Upgrade recommendations](https://docs.gitlab.com/ee/policy/maintenance.html#upgrade-recommendations)
when upgrading between major versions.

### Update GitLab using Docker compose

To update GitLab that was [installed using Docker Compose](#install-gitlab-using-docker-compose):

1. Take a [backup](#back-up-gitlab).
1. Download the newest release and update your GitLab instance:

   ```shell
   docker-compose pull
   docker-compose up -d
   ```

   NOTE: **Note:**
   If you have used [tags](#use-tagged-versions-of-gitlab) instead, you'll need
   to first edit `docker-compose.yml`.

## Back up GitLab

You can create a GitLab backup with:

```shell
docker exec -t <container name> gitlab-backup create
```

Read more on how to [back up and restore GitLab](https://docs.gitlab.com/ee/raketasks/backup_restore.html).

## Troubleshooting

The following information will help if you encounter problems using Omnibus GitLab and Docker.

### Diagnose potential problems

Read container logs:

```shell
sudo docker logs gitlab
```

Enter running container:

```shell
sudo docker exec -it gitlab /bin/bash
```

From within the container you can administer the GitLab container as you would
normally administer an
[Omnibus installation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md)

### 500 Internal Error

When updating the Docker image you may encounter an issue where all paths
display a `500` page. If this occurs, restart the container to try to rectify the
issue:

```shell
sudo docker restart gitlab
```

### Permission problems

When updating from older GitLab Docker images you might encounter permission
problems. This happens when users in previous images were not
preserved correctly. There's script that fixes permissions for all files.

To fix your container, execute `update-permissions` and restart the
container afterwards:

```shell
sudo docker exec gitlab update-permissions
sudo docker restart gitlab
```

### Windows/Mac: `Error executing action run on resource ruby_block[directory resource: /data/GitLab]`

This error occurs when using Docker Toolbox with VirtualBox on Windows or Mac,
and making use of Docker volumes. The `/c/Users` volume is mounted as a
VirtualBox Shared Folder, and does not support the all POSIX filesystem features.
The directory ownership and permissions cannot be changed without remounting, and
GitLab fails.

Our recommendation is to switch to using the native Docker install for your
platform, instead of using Docker Toolbox.

If you cannot use the native Docker install (Windows 10 Home Edition, or Windows 7/8),
then an alternative solution is to setup NFS mounts instead of VirtualBox shares for
Docker Toolbox's boot2docker.

### Linux ACL issues

If you are using file ACLs on the Docker host, the `docker` group requires full access to the volumes in order for GitLab to work:

```shell
getfacl $GITLAB_HOME/gitlab

# file: $GITLAB_HOME/gitlab
# owner: XXXX
# group: XXXX
user::rwx
group::rwx
group:docker:rwx
mask::rwx
default:user::rwx
default:group::rwx
default:group:docker:rwx
default:mask::rwx
default:other::r-x
```

If these are not correct, set them with:

```shell
sudo setfacl -mR default:group:docker:rwx $GITLAB_HOME/gitlab
```

NOTE: **Note:**
`docker` is the default group, if you've changed this, update your commands accordingly.
