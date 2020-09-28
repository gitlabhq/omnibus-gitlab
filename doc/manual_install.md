---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Manually download and install a GitLab package

NOTE: **Note:**
The [package repository](https://about.gitlab.com/install/) is recommended over
a manual installation.

If for some reason you don't use the official repositories, it is possible to
download the package and install it manually. The exact same method can be
used to manually update GitLab.

## Requirements

Before installing GitLab, it is of critical importance to review the system
[requirements](https://docs.gitlab.com/ee/install/requirements.html). The system
requirements include details on the minimum hardware, software, database, and
additional requirements to support GitLab.

## Download a GitLab Package

All GitLab packages are posted to GitLab's [package server](https://packages.gitlab.com/gitlab/)
and can be downloaded. Five repositories are maintained:

- [GitLab EE](https://packages.gitlab.com/gitlab/gitlab-ee): for official
  [Enterprise Edition](https://about.gitlab.com/pricing/) releases.
- [GitLab CE](https://packages.gitlab.com/gitlab/gitlab-ce): for official Community Edition releases.
- [Unstable](https://packages.gitlab.com/gitlab/unstable): for release candidates and other unstable versions.
- [Nighty Builds](https://packages.gitlab.com/gitlab/nightly-builds): for nightly builds.
- [Raspberry Pi](https://packages.gitlab.com/gitlab/raspberry-pi2): for official Community Edition releases built for [Raspberry Pi](https://www.raspberrypi.org) packages.

To download GitLab:

1. Browse to the repository for the type of package you would like to see the
   list of packages that are available. There are multiple packages for a
   single version, one for each supported distribution type. Next to the filename
   is a label indicating the distribution, as the file names may be the same.

   ![Package Listing](img/package_list.png)

1. Find the package version you wish to install and click on it.
1. Click the **Download** button in the upper right corner to download the package.

## Install or update a GitLab Package

After the GitLab package is downloaded, install it using the following commands:

- For GitLab Community Edition:

  ```shell
  # GitLab Community Edition
  # Debian/Ubuntu
  dpkg -i gitlab-ce-<version>.deb

  # CentOS/RHEL
  rpm -Uvh gitlab-ce-<version>.rpm
  ```

- For GitLab [Enterprise Edition](https://about.gitlab.com/pricing/):

  ```shell
  # Debian/Ubuntu
  dpkg -i gitlab-ee-<version>.deb

  # CentOS/RHEL
  rpm -Uvh gitlab-ee-<version>.rpm
  ```

TIP: **Tip:**
If you are installing for the first time, you can pass the
`EXTERNAL_URL="<GitLab URL>"` variable to set your preferred domain name. Installation will
automatically configure and start GitLab at that URL. Enabling HTTPS requires
[additional configuration](settings/nginx.md#enable-https) to specify the certificates.

## Browse to the hostname and login

On your first visit, you'll be redirected to a password reset screen. Provide
the password for the initial administrator account and you will be redirected
back to the login screen. Use the default account's username `root` to login.

See our [documentation for detailed instructions on installing and configuration](installation/index.md#installation-and-configuration).
