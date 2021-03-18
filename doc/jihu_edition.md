---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# JiHu Edition

## Prerequisites

Before installing GitLab JiHu Edition, it is of critical importance to review the system [requirements](https://docs.gitlab.com/ee/install/requirements.html). The system requirements include details on the minimum hardware, software, database, and additional requirements to support GitLab.

Once you have contracted with JiHu, a JiHu representative will contact you to supply you with a license
that you can use as part of the installation process.

## Download a JiHu Edition (JH) package

Download the JiHu Edition package that matches your distribution or installation method:

- Ubuntu 16.04 - `https://gitlab-omnibus-gitlab-jh.s3.amazonaws.com/ubuntu-xenial/gitlab-jh_13.10.0-rc40.jh.0_amd64.deb`
- Ubuntu 18.04 - `https://gitlab-omnibus-gitlab-jh.s3.amazonaws.com/ubuntu-bionic/gitlab-jh_13.10.0-rc40.jh.0_amd64.deb`
- Ubuntu 20.04 - `https://gitlab-omnibus-gitlab-jh.s3.amazonaws.com/ubuntu-focal/gitlab-jh_13.10.0-rc40.jh.0_amd64.deb`
- Debian 9 - `https://gitlab-omnibus-gitlab-jh.s3.amazonaws.com/debian-stretch/gitlab-jh_13.10.0-rc40.jh.0_amd64.deb`
- Debian 10 - `https://gitlab-omnibus-gitlab-jh.s3.amazonaws.com/debian-buster/gitlab-jh_13.10.0-rc40.jh.0_amd64.deb`
- CentOS 7 - `https://gitlab-omnibus-gitlab-jh.s3.amazonaws.com/el-7/gitlab-jh-13.10.0-rc40.jh.0.el7.x86_64.rpm`
- CentOS 8 - `https://gitlab-omnibus-gitlab-jh.s3.amazonaws.com/el-8/gitlab-jh-13.10.0-rc40.jh.0.el8.x86_64.rpm`

## Install or update a JiHu Edition package

To install or upgrade the JiHu Edition package:

**For Debian/Ubuntu**

```shell
dpkg -i gitlab-jh-<version>.deb
```

**For CentOS/RHEL**

```shell
rpm -Uvh gitlab-jh-<version>.rpm
```

NOTE:
If you are installing for the first time, you have to pass the
`EXTERNAL_URL="<GitLab URL>"` variable to set your preferred domain name. Installation
automatically configures and starts GitLab at that URL. Enabling HTTPS requires
[additional configuration](settings/nginx.md#enable-https) to specify the certificates.

### Set initial password and apply license

The first time GitLab JiHu Edition is installed, you are redirected to a password reset screen. Provide
the password for the initial administrator account and you are redirected
back to the login screen. Use the default account's username `root` to log in.

For detailed instructions, see [installation and configuration](installation/index.md#installation-and-configuration).

Additionally, you can navigate to the GitLab administration panel of your server (`/admin/license/new`) and
upload your JiHu Edition license file.

## Update GitLab Enterprise Edition to JiHu Edition

To update an existing GitLab Enterprise Edition (EE) server installed using the Omnibus GitLab
packages to GitLab JiHu Edition (JH), you install the JiHu Edition (JH)
package on top of EE.

The available options are:

- (Recommended) Updating from the same version of EE to JH.
- Upgrading from a lower version of EE to a higher version of JH, provided that this is a supported [upgrade path](https://docs.gitlab.com/ee/update/index.html#upgrade-paths) (for example, EE 13.5 to JH 13.10).

In the following steps we assume that
you are updating the same version (for example, EE 13.10 to JH 13.10).

NOTE:
If you have an EE license already installed prior to upgrading to JiHu, the EE license is
automatically deactivated when JH is installed.

To update EE to JE:

1. Find the currently installed GitLab version:

   **For Debian/Ubuntu**

   ```shell
   sudo apt-cache policy gitlab-ee | grep Installed
   ```

   The output should be similar to: `Installed: 13.10.0-ee.0`. Write this value down.

   **For CentOS/RHEL**

   ```shell
   sudo rpm -q gitlab-ee
   ```

   The output should be similar to: `gitlab-ee-13.10.0-ee.0.el8.x86_64`. Write this value down.

1. Download the JiHu Edition package for your operating system. For detailed instructions see [Download a JiHu package](#download-a-jihu-edition-jh-package).

1. Install the `gitlab-jh` package. Note that this will automatically
   uninstall the `gitlab-ee` package on your GitLab server. Then [reconfigure](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure)
   GitLab right after the `gitlab-jh` package is installed.

   **For Debian/Ubuntu**

   ```shell
   dpkg -i gitlab-jh-<version>.deb
   ```

   **For CentOS/RHEL**

   ```shell
   rpm -Uvh gitlab-jh-<version>.rpm
   ```

1. Go to the GitLab administration panel of your server (`/admin/license/new`) and
   upload your JiHu Edition license file.

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

That's it! You can now use GitLab JiHu Edition! To update to a newer
version, see [Install or update a JiHu Package](#install-or-update-a-jihu-edition-package).

## Downgrade to EE

To downgrade the JiHu Edition installation to GitLab Enterprise Edition (EE), install the same version of the Enterprise Edition package on top of the currently installed one.

Depending on the preferred installation method for GitLab EE, either:

- Use the official GitLab package repository and [install GitLab EE](https://about.gitlab.com/install/?version=ee), or
- Download the GitLab EE package and [manually install the GitLab EE 
package](manual_install.html).
