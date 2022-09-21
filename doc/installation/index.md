---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
comments: false
---

# Installing GitLab with Omnibus packages **(FREE SELF)**

## Prerequisites

- [Installation Requirements](https://docs.gitlab.com/ee/install/requirements.html).
- If you want to access your GitLab instance via a domain name, like `mygitlabinstance.com`,
  make sure the domain correctly points to the IP of the server where GitLab is being
  installed. You can check this using the command `host mygitlabinstance.com`.
- If you want to use HTTPS on your GitLab instance, make sure you have the SSL
  certificates for the domain ready. (Note that certain components like
  Container Registry which can have their own subdomains requires certificates for
  those subdomains also.)
- If you want to send notification emails, install and configure a mail server (MTA)
  like Sendmail or Postfix. Alternatively, you can use other [third party SMTP servers](../settings/smtp.md).

## Installation and Configuration

These configuration settings are commonly used when configuring Omnibus GitLab.
For a complete list of settings, see the [README](../index.md#configuring) file.

- [Installing GitLab](https://about.gitlab.com/install/).
  - [Manually downloading and installing a GitLab package](../manual_install.md).
- [Setting up a domain name/URL](../settings/configuration.md#configure-the-external-url-for-gitlab)
  for the GitLab Instance so that it can be accessed easily.
- [Enabling HTTPS](../settings/nginx.md#enable-https).
- [Enabling notification emails](../settings/smtp.md#smtp-settings).
- [Enabling replying via email](https://docs.gitlab.com/ee/administration/reply_by_email.html#set-it-up).
  - [Installing and configuring Postfix](https://docs.gitlab.com/ee/administration/reply_by_email_postfix_setup.html).
- [Enabling container registry on GitLab](https://docs.gitlab.com/ee/administration/packages/container_registry.html#container-registry-domain-configuration).
  - You require SSL certificates for the domain used for container registry.
- [Enabling GitLab Pages](https://docs.gitlab.com/ee/administration/pages/).
  - If you want HTTPS enabled, you must get wildcard certificates.
- [Enabling Elasticsearch](https://docs.gitlab.com/ee/integration/elasticsearch.html).
- [GitLab Mattermost](https://docs.gitlab.com/ee/integration/mattermost/) Set up the Mattermost messaging app that ships with Omnibus GitLab package.
- [GitLab Prometheus](https://docs.gitlab.com/ee/administration/monitoring/prometheus/index.html)
  Set up the Prometheus monitoring included in the Omnibus GitLab package.
- [GitLab High Availability Roles](../roles/index.md).

### Set up the initial password

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5331) in Omnibus GitLab 14.0.

By default, Omnibus GitLab automatically generates a password for the
initial administrator user account (`root`) and stores it to
`/etc/gitlab/initial_root_password` for at least 24 hours. For security reasons,
after 24 hours, this file is automatically removed by the first `gitlab-ctl reconfigure`.

NOTE:
If GitLab can't detect a valid hostname for the server during the
installation, a reconfigure does not run.

To provide a custom initial root password, you have two options:

- Pass the `GITLAB_ROOT_PASSWORD` environment variable to the
  [installation command](https://about.gitlab.com/install/) provided
  the hostname for the server is set up correctly.
  If during the installation GitLab doesn't automatically perform a
  reconfigure, you have to pass the `GITLAB_ROOT_PASSWORD` variable to the
  first `gitlab-ctl reconfigure` run.
- Before the first reconfigure, edit `/etc/gitlab/gitlab.rb` (create it if it
  doesn't exist) and set:

  ```ruby
  gitlab_rails['initial_root_password'] = '<my_strong_password>'
  ```

Both of these methods apply only during the initial database seeding, which happens
during the first reconfigure. For subsequent reconfigure runs, neither of
the aforementioned methods have any effect. In that case, use the random
password in `/etc/gitlab/initial_root_password` to log in, or
[reset the root password](https://docs.gitlab.com/ee/security/reset_user_password.html).

## Using Docker image

You can also use the Docker images provided by GitLab to install and configure a GitLab instance.
Check the [documentation](https://docs.gitlab.com/ee/install/docker.html) to know more.
