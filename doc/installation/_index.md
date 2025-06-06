---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Install GitLab with the Linux package
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

## Prerequisites

- [Installation Requirements](https://docs.gitlab.com/install/requirements/).
- If you want to access your GitLab instance by using a domain name, like `mygitlabinstance.com`,
  make sure the domain correctly points to the IP of the server where GitLab is being
  installed. You can check this using the command `host mygitlabinstance.com`.
- If you want to use HTTPS on your GitLab instance, make sure you have the SSL
  certificates for the domain ready. (Note that certain components like
  Container Registry which can have their own subdomains requires certificates for
  those subdomains also.)
- If you want to send notification emails, install and configure a mail server (MTA)
  like Sendmail or Postfix. Alternatively, you can use other [third party SMTP servers](../settings/smtp.md).

## Installation and Configuration

These configuration settings are commonly used when configuring a Linux package installation.
For a complete list of settings, see the [README](../_index.md#configuring) file.

- [Installing GitLab](https://about.gitlab.com/install/).
  - [Manually downloading and installing a GitLab package](https://docs.gitlab.com/update/package/#download-a-package-manually).
- [Setting up a domain name/URL](../settings/configuration.md#configure-the-external-url-for-gitlab)
  for the GitLab Instance so that it can be accessed easily.
- [Enabling HTTPS](../settings/nginx.md#enable-https).
- [Enabling notification emails](../settings/smtp.md).
- [Enabling replying by email](https://docs.gitlab.com/administration/reply_by_email/#set-it-up).
  - [Installing and configuring Postfix](https://docs.gitlab.com/administration/reply_by_email_postfix_setup/).
- [Enabling container registry on GitLab](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-domain-configuration).
  - You require SSL certificates for the domain used for container registry.
- [Enabling GitLab Pages](https://docs.gitlab.com/administration/pages/).
  - If you want HTTPS enabled, you must get wildcard certificates.
- [Enabling Elasticsearch](https://docs.gitlab.com/integration/advanced_search/elasticsearch/).
- [GitLab Mattermost](https://docs.gitlab.com/integration/mattermost/). Set up the Mattermost messaging app that ships with the Linux package.
- [GitLab Prometheus](https://docs.gitlab.com/administration/monitoring/prometheus/)
  Set up the Prometheus monitoring included in the Linux package.
- [GitLab High Availability Roles](../roles/_index.md).

### Set up the initial account

By default, a Linux package installation automatically generates a password for the
initial administrator user account (`root`) and stores it to
`/etc/gitlab/initial_root_password` for at least 24 hours. For security reasons,
after 24 hours, this file is automatically removed by the first `gitlab-ctl reconfigure`.

The default account is tied to a randomly-generated email address. To override
this, pass the `GITLAB_ROOT_EMAIL` environment variable to the installation command.

{{< alert type="note" >}}

If GitLab can't detect a valid hostname for the server during the
installation, a reconfigure does not run.

{{< /alert >}}

To provide a custom initial root password, you have two options:

- Pass the `GITLAB_ROOT_PASSWORD` environment variable to the
  [installation command](https://about.gitlab.com/install/) provided
  the hostname for the server is set up correctly:

  ```shell
  sudo GITLAB_ROOT_EMAIL="<gitlab_admin@example.com>" GITLAB_ROOT_PASSWORD="<strongpassword>" EXTERNAL_URL="http://gitlab.example.com" apt install gitlab-ee
  ```

  If during the installation GitLab doesn't automatically perform a
  reconfigure, you have to pass the `GITLAB_ROOT_PASSWORD` or `GITLAB_ROOT_EMAIL`
  variable to the first `gitlab-ctl reconfigure` run.

- Before the first reconfigure, edit `/etc/gitlab/gitlab.rb` (create it if it
  doesn't exist) and set:

  ```ruby
  gitlab_rails['initial_root_password'] = '<my_strong_password>'
  ```

Both of these methods apply only during the initial database seeding, which happens
during the first reconfigure. For subsequent reconfigure runs, neither of
the aforementioned methods have any effect. In that case, use the random
password in `/etc/gitlab/initial_root_password` to sign in, or
[reset the root password](https://docs.gitlab.com/security/reset_user_password/).

## Using Docker image

You can also use the Docker images provided by GitLab to install and configure a GitLab instance.
Check the [documentation](https://docs.gitlab.com/install/docker/) to know more.

## Uninstall the Linux package (Omnibus)

To uninstall the Linux package, you can opt to either keep your data (repositories,
database, configuration) or remove all of them:

1. Optional. To remove
   [all users and groups created by the Linux package](../settings/configuration.md#disable-user-and-group-account-management)
   before removing the package (with `apt` or `yum`):

   ```shell
   sudo gitlab-ctl stop && sudo gitlab-ctl remove-accounts
   ```

   {{< alert type="note" >}}

If you have problems removing accounts or groups, run `userdel` or `groupdel` manually
   to delete them. You might also want to manually remove the leftover user home directories
   from `/home/`.

   {{< /alert >}}

1. Choose whether to keep your data or remove all of them:

   - To preserve your data (repositories, database, configuration), stop GitLab and
     remove its supervision process:

     ```shell
     sudo systemctl stop gitlab-runsvdir
     sudo systemctl disable gitlab-runsvdir
     sudo rm /usr/lib/systemd/system/gitlab-runsvdir.service
     sudo systemctl daemon-reload
     sudo systemctl reset-failed
     sudo gitlab-ctl uninstall
     ```

   - To remove all data:

     ```shell
     sudo gitlab-ctl cleanse && sudo rm -r /opt/gitlab
     ```

1. Uninstall the package (replace with `gitlab-ce` if you have GitLab FOSS installed):

   ```shell
   # Debian/Ubuntu
   sudo apt remove gitlab-ee

   # RedHat/CentOS
   sudo yum remove gitlab-ee
   ```
