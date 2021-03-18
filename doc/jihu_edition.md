---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# JiHu Edition

NOTE:
This section is only relevant if you are a customer in the Chinese market.

GitLab licensed its technology to a new independent Chinese company, called JiHu.
This independent company will help drive adoption of the GitLab complete DevOps
platform in China and foster the GitLab community and open source contributions.

For more information, see the
[blog post announcement](https://about.gitlab.com/blog/2021/03/18/gitlab-licensed-technology-to-new-independent-chinese-company/)
and the [FAQ](https://about.gitlab.com/pricing/faq-jihu/).

## Prerequisites

Before installing GitLab JiHu Edition, it is of critical importance to review the system [requirements](https://docs.gitlab.com/ee/install/requirements.html). The system requirements include details on the minimum hardware, software, database, and additional requirements to support GitLab.

Once you have contracted with JiHu, a JiHu representative will contact you to supply you with a license
that you can use as part of the installation process.

## Available JiHu Edition (JH) packages

The deb/rpm packages are hosted in Amazon S3:

| OS | URL |
| Ubuntu 20.04 | <https://omnibus.gitlab.cn/ubuntu/focal/gitlab-jh_13.10.0-jh.0_amd64.deb> |
| Ubuntu 18.04 | <https://omnibus.gitlab.cn/ubuntu/bionic/gitlab-jh_13.10.0-jh.0_amd64.deb> |
| Ubuntu 16.04 | <https://omnibus.gitlab.cn/ubuntu/xenial/gitlab-jh_13.10.0-jh.0_amd64.deb> |
| Debian 10 | <https://omnibus.gitlab.cn/debian/buster/gitlab-jh_13.10.0-jh.0_amd64.deb> |
| Debian 9 | <https://omnibus.gitlab.cn/debian/stretch/gitlab-jh_13.10.0-jh.0_amd64.deb> |
| CentOS 8 | <https://omnibus.gitlab.cn/el/8/gitlab-jh-13.10.0-jh.0.el8.x86_64.rpm> |
| CentOS 7 | <https://omnibus.gitlab.cn/el/7/gitlab-jh-13.10.0-jh.0.el7.x86_64.rpm> |

The Docker image is [hosted on GitLab.com](https://gitlab.com/gitlab-jh/omnibus-gitlab/container_registry/1772325):

```shell
registry.gitlab.com/gitlab-jh/omnibus-gitlab/gitlab-jh:13.10.0
```

## Install or update a JiHu Edition package

NOTE:
If you are installing for the first time, you have to pass the
`EXTERNAL_URL="<GitLab URL>"` variable to set your preferred domain name. Installation
automatically configures and starts GitLab at that URL. Enabling HTTPS requires
[additional configuration](settings/nginx.md#enable-https) to specify the certificates.

To install or update the JiHu Edition package, use one of the following methods
based on your distribution. Replace `<url>` with the URL of the
[package](#available-jihu-edition-jh-packages) you download:

**For Debian/Ubuntu**

```shell
curl --output gitlab-jh.deb <url>
sudo dpkg -i gitlab-jh.deb
```

**For CentOS/RHEL**

```shell
curl --output gitlab-jh.rpm <url>
sudo rpm -Uvh gitlab-jh.rpm
```

**For Docker**

Follow the [Docker installation guide](docker/README.md)
and replace `gitlab/gitlab-ee:latest` with the following:

```shell
registry.gitlab.com/gitlab-jh/omnibus-gitlab/gitlab-jh:<version>
```

You can find the version in the [Container Registry](https://gitlab.com/gitlab-jh/omnibus-gitlab/container_registry/1772325).

### Set initial password and apply license

The first time GitLab JiHu Edition is installed, you are redirected to a password reset screen. Provide
the password for the initial administrator account and you are redirected
back to the login screen. Use the default account's username `root` to log in.

For detailed instructions, see [installation and configuration](installation/index.md#installation-and-configuration).

Additionally, you can navigate to the GitLab administration panel of your server and
[upload your JiHu Edition license file](https://docs.gitlab.com/ee/user/admin_area/license.html#uploading-your-license).

## Update GitLab Enterprise Edition to JiHu Edition

To update an existing GitLab Enterprise Edition (EE) server installed using the Omnibus GitLab
packages to GitLab JiHu Edition (JH), you install the JiHu Edition (JH)
package on top of EE.

The available options are:

- (Recommended) Updating from the same version of EE to JH.
- Updating from a lower version of EE to a higher version of JH, provided that this is a supported [upgrade path](https://docs.gitlab.com/ee/update/index.html#upgrade-paths) (for example, EE 13.5.4 to JH 13.10.0).

In the following steps we assume that
you are updating the same version (for example, EE 13.10.0 to JH 13.10.0).

To update EE to JH:

- If you installed GitLab using a deb/rpm package:

  1. Take a [backup](https://docs.gitlab.com/ee/raketasks/backup_restore.html#back-up-gitlab).
  1. Find the currently installed GitLab version:

     **For Debian/Ubuntu**

     ```shell
     sudo apt-cache policy gitlab-ee | grep Installed
     ```

     The output should be similar to `Installed: 13.10.0-ee.0`, so the installed
     version is `13.10.0-ee.0`.

     **For CentOS/RHEL**

     ```shell
     sudo rpm -q gitlab-ee
     ```

     The output should be similar to `gitlab-ee-13.10.0-ee.0.el8.x86_64`, so
     the installed version is `13.10.0-ee.0`.

  1. Follow the same steps as when
     [installing the JiHu Edition package](#install-or-update-a-jihu-edition-package) for
     your operating system, and make sure to pick the same version as the one
     noted in the previous step. Replace `<url>` with the URL of your package.

  1. Reconfigure GitLab:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

  1. Go to the GitLab administration panel of your server (`/admin/license/new`) and
     upload your JiHu Edition license file. If you have an EE license already installed
     prior to updating to JiHu, the EE license is automatically deactivated when JH
     is installed.

  1. Confirm that GitLab is working as expected, then remove the old
     Enterprise Edition repository:

     **For Debian/Ubuntu**

     ```shell
     sudo rm /etc/apt/sources.list.d/gitlab_gitlab-ee.list
     ```

     **For CentOS/RHEL**

     ```shell
     sudo rm /etc/yum.repos.d/gitlab_gitlab-ee.repo
     sudo dnf config-manager --disable gitlab_gitlab-ee
     ```

- If you installed GitLab using Docker:

   1. Follow the [Docker update guide](docker/README.md#update)
      and replace `gitlab/gitlab-ee:latest` with the following:

      ```shell
      registry.gitlab.com/gitlab-jh/omnibus-gitlab/gitlab-jh:<version>
      ```

      Where `<version>` is the currently installed GitLab version, which
      you can find with:

      ```shell
      sudo docker ps | grep gitlab/gitlab-ee | awk '{print $2}'
      ```

      The output should be similar to: `gitlab/gitlab-ee:13.10.0-ee.0`, so
      in this case, `<version>` equals to `13.10.0`.

   1. Go to the GitLab administration panel of your server (`/admin/license/new`) and
      upload your JiHu Edition license file. If you have an EE license already installed
      prior to updating to JiHu, the EE license is automatically deactivated when JH
      is installed.

That's it! You can now use GitLab JiHu Edition! To update to a newer
version, see [Install or update a JiHu Package](#install-or-update-a-jihu-edition-package).

## Go back to GitLab Enterprise Edition

To downgrade the JiHu Edition installation to GitLab Enterprise Edition (EE), install the same version of the Enterprise Edition package on top of the currently installed one.

Depending on the preferred installation method for GitLab EE, either:

- Use the official GitLab package repository and [install GitLab EE](https://about.gitlab.com/install/?version=ee), or
- Download the GitLab EE package and [manually install it](manual_install.md).
