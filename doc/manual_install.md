# Manually Downloading and Installing a GitLab Package

If you do not want to use the official GitLab [package repository](https://about.gitlab.com/installation), you can download and install a Omnibus Gitlab package manually.

## Downloading a GitLab Package

All GitLab packages are posted to our [package server](https://packages.gitlab.com/gitlab/) and can be downloaded. We maintain five repos:

* [GitLab EE](https://packages.gitlab.com/gitlab/gitlab-ee): for official Enterprise Edition releases
* [GitLab CE](https://packages.gitlab.com/gitlab/gitlab-ce): for official Community Edition releases
* [Unstable](https://packages.gitlab.com/gitlab/unstable): for release candidates and other unstable versions
* [Nighty Builds](https://packages.gitlab.com/gitlab/nightly-builds): for nightly builds
* [Raspberry Pi 2](https://packages.gitlab.com/gitlab/raspberry-pi2): for [Raspberry Pi 2](https://www.raspberrypi.org) packages

Browse to the repository for the type of package you would like, in order to see the list of packages that are available. There are multiple packages for a single version, one for each supported distribution type. Next to the filename is a label indicating the distribution, as the file names may be the same.

![Package Listing](img/package_list.png)

Locate the desired package for the version and distribution you want to use, and click on the filename to download.

## Installing the GitLab Package

With the desired package downloaded, use your systems package management tool to install it. For example:

* DEB based (Ubuntu, Debian, Raspberry Pi): `sudo dpkg -i gitlab-ee-9.5.2-ee.0_amd64.deb`
* RPM based (CentOS, RHEL, Oracle, Scientific, openSUSE, SLES): `sudo rpm -i gitlab-ee-9.5.2-ee.0.el7.x86_64.rpm`

Installation may take a few minutes to complete. Once installed, GitLab should now be configured.

## Configuring GitLab

With GitLab installed, the next step is to configure it and start the services. The settings for GitLab are contained in `/etc/gitlab/gitlab.rb`. There are a variety of settings which [can be configured](settings/configuration.md), but the most important is setting the [external URL](settings/configuration.md#configuring-the-external-url-for-gitlab).

> **Note:** Enabling HTTPS will require [additional configuration](settings/nginx.html#enable-https) to specify the certificates.

To configure the external URL:
1. Edit `/etc/gitlab/gitlab.rb` in your favorite text editor
2. Find the line near the top for `external_url`
3. Change the URL to be the URL of your GitLab server
4. Save the file and exit your text editor.

With the required settings configured, GitLab can now be started. To do this run:

```bash
sudo gitlab-ctl reconfigure
```

This command will read the settings and apply them to the GitLab installation, then start all services. This will take a few minutes to complete, and you will see lines of white and green text appear.

Once finished, your GitLab server is now ready to be accessed by the URL you configured.
