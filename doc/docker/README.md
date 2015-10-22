# GitLab Docker images

The GitLab CE docker image is [available on Docker Hub](https://registry.hub.docker.com/u/gitlab/gitlab-ce/).

The GitLab EE docker image is [available on Docker Hub](https://registry.hub.docker.com/u/gitlab/gitlab-ee/).

To use GitLab EE instead of GitLab CE replace image name to `gitlab/gitlab-ee:latest`.

## Run the image

Run the image:
```bash
sudo docker run --detach \
	--hostname gitlab.example.com \
	--publish 8443:443 --publish 8080:80 --publish 2222:22 \
	--name gitlab \
	--restart always \
	--volume /srv/gitlab/config:/etc/gitlab \
	--volume /srv/gitlab/logs:/var/log/gitlab \
	--volume /srv/gitlab/data:/var/opt/gitlab \
	gitlab/gitlab-ce:latest
```

This will download and start GitLab CE container and publish ports needed to access SSH, HTTP and HTTPS.
All GitLab data will be stored as subdirectories of `/srv/gitlab/`.
The container will automatically `restart` after system reboot.

After this you can login to the web interface as explained above in 'After starting a container'.

## Where is the data stored?

The GitLab container uses host mounted volumes to store persistent data:
- `/srv/gitlab/data` mounted as `/var/opt/gitlab` in the container is used for storing *application data*
- `/srv/gitlab/logs` mounted as `/var/log/gitlab` in the container is used for storing *logs*
- `/srv/gitlab/config` mounted as `/etc/gitlab` in the container is used for storing *configuration*

You can fine tune these directories to meet your requirements.

### Configure GitLab

This container uses the official Omnibus GitLab package, so all configuration is done in the unique configuration file `/etc/gitlab/gitlab.rb`.

To access GitLab configuration, you can start an bash in a context of running container. This will allow you to browse all directories and use your favorite text editor:
```bash
sudo docker exec -it gitlab /bin/bash
```

You can also edit just `/etc/gitlab/gitlab.rb`:
```bash
sudo docker exec -it gitlab vi /etc/gitlab/gitlab.rb
```

**You should set the `external_url` to point to a valid URL.**

**You may also be interested in [Enabling HTTPS](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/nginx.md#enable-https).**

**To receive e-mails from GitLab you have to configure the [SMTP settings](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/smtp.md),
because Docker image doesn't have a SMTP server.**

**Note** that GitLab will reconfigure itself **at each container start.** You will need to restart the container to reconfigure your GitLab:

```bash
sudo docker restart gitlab
```

For more options for configuring the container please check [Omnibus GitLab documentation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md#configuration).

## Diagnose potential problems

Read container logs:
```bash
sudo docker logs gitlab
```

Enter running container:
```bash
sudo docker exec -it gitlab /bin/bash
```

From within container you can administrer GitLab container as you would normally administer Omnibus installation: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md.

## After starting a container

After starting a container you can go to [http://localhost/](http://localhost/) or [http://192.168.59.103/](http://192.168.59.103/) if you use boot2docker.

It might take a while before the docker container is responding to queries.

You can check the status with something like `sudo docker logs -f gitlab`.

You can login to the web interface with username `root` and password `5iveL!fe`.

Next time, you can just use docker start and stop to run the container.

### Upgrade GitLab to newer version

To upgrade GitLab to new version you have to do:

1. stop running container,
   ```bash
   sudo docker stop gitlab
   ```
   
2. remove existing container,
   ```bash
   sudo docker rm gitlab
   ```

3. pull new image,
   ```bash
   sudo docker pull gitlab/gitlab-ce:latest
   ```

4. create the container once again with previously specified options.
   ```bash
   sudo docker run --detach \
	--hostname gitlab.example.com \
	--publish 8443:443 --publish 8080:80 --publish 2222:22 \
	--name gitlab \
	--restart always \
	--volume /srv/gitlab/config:/etc/gitlab \
	--volume /srv/gitlab/logs:/var/log/gitlab \
	--volume /srv/gitlab/data:/var/opt/gitlab \
	gitlab/gitlab-ce:latest
   ```

On the first run GitLab will reconfigure and update itself.

### Use tagged versions of GitLab

We provide tagged version of GitLab docker images.

To see all available tags check [GitLab-CE Tags](https://hub.docker.com/r/gitlab/gitlab-ce/tags/) and [GitLab-EE Tags](https://hub.docker.com/r/gitlab/gitlab-ce/tags/).

To use specific tagged version replace `gitlab/gitlab-ce:latest` with `gitlab/gitlab-ce:8.0.2`.

### Run GitLab CE on public IP address

You can make Docker to use your IP address and forward all traffic to the GitLab CE container.
You can do that by modifying the `--publish` ([Binding container ports to the host](https://docs.docker.com/articles/networking/#binding-ports)):

> --publish=[] : Publish a container᾿s port or a range of ports to the host format: ip:hostPort:containerPort | ip::containerPort | hostPort:containerPort | containerPort

To expose GitLab CE on IP 1.1.1.1:

```bash
sudo docker run --detach \
	--hostname gitlab.example.com \
	--publish 1.1.1.1:443:443 --publish 1.1.1.1:80:80 --publish 1.1.1.1:22:22 \
	--name gitlab \
	--restart always \
	--volume /srv/gitlab/config:/etc/gitlab \
	--volume /srv/gitlab/logs:/var/log/gitlab \
	--volume /srv/gitlab/data:/var/opt/gitlab \
	gitlab/gitlab-ce:latest
```

You can then access GitLab instance at http://1.1.1.1/ and https://1.1.1.1/.

## Troubleshooting

### Permission problems

When updating from older GitLab Docker images you might encounter permission problems.
This happens due to a fact that users in previous images were not preserved correctly.
There's script that fixes permissions for all files.

To fix your container, simply execute `update-permissions` script and restart container afterwards:
```
sudo docker exec gitlab update-permissions
sudo docker restart gitlab
```
