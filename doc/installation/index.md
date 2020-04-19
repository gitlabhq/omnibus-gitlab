---
comments: false
---

# Installing GitLab with Omnibus packages

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
  like sendmail. Alternatively, you can use other [third party SMTP servers](../settings/smtp.md).

## Installation and Configuration

These configuration settings are commonly used when configuring GitLab Omnibus.
For a complete list of settings, see the [README](../README.md#configuring) file.

- [Installing GitLab](https://about.gitlab.com/install/)
  - [Manually downloading and installing a GitLab package](../manual_install.md)
- [Setting up a domain name/URL](../settings/configuration.md#configuring-the-external-url-for-gitlab)
  for the GitLab Instance so that it can be accessed easily.
- [Enabling HTTPS](../settings/nginx.md#enable-https)
- [Enabling notification emails](../settings/smtp.md#smtp-settings)
- [Enabling replying via email](https://docs.gitlab.com/ee/administration/reply_by_email.html#set-it-up)
  - [Installing and configuring postfix](https://docs.gitlab.com/ee/administration/reply_by_email_postfix_setup.html)
- [Enabling container registry on GitLab](https://docs.gitlab.com/ee/administration/packages/container_registry.html#container-registry-domain-configuration)
  - You will require SSL certificates for the domain used for container registry.
- [Enabling GitLab Pages](https://docs.gitlab.com/ee/administration/pages/)
  - If you want HTTPS enabled, you will have to get wildcard certificates.
- [Enabling Elasticsearch](https://docs.gitlab.com/ee/integration/elasticsearch.html)
- [GitLab Mattermost](../gitlab-mattermost/README.md) Set up the Mattermost messaging app that ships with Omnibus GitLab package.
- [GitLab Prometheus](https://docs.gitlab.com/ee/administration/monitoring/performance/prometheus.html)
  Set up the Prometheus monitoring included in the Omnibus GitLab package.
- [GitLab High Availability Roles](../roles/README.md)

## Using docker image

You can also use the docker images provided by GitLab to install and configure a GitLab instance.
Check the [documentation](../docker/README.md) to know more.
