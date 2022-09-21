---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Grafana Dashboard Service **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3487) in GitLab 11.9.

[Grafana](https://grafana.com/) is a powerful dashboard building system that
you can use to visualize performance metrics from the [embedded Prometheus](prometheus.md)
monitoring system.

## Enabling Grafana

Starting with GitLab 15.3, Grafana is not enabled by default. To enable it:

1. Edit `/etc/gitlab/gitlab.rb` and add/edit the following lines:

   ```ruby
   ## Set to true/false to enable/disable respectively
   grafana['enable'] = true
   ```

1. Save the file and [reconfigure](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure) GitLab for the changes to take effect.
1. Once enabled, Grafana will be available on `https://gitlab.example.com/-/grafana`
   and SSO with GitLab is automatically configured.

## Enable login using username and password

NOTE:
The admin account's username is `admin`.

Logging in to Grafana using username/password combo is disabled, and only
GitLab SSO is available by default. However, to access the admin account, you
need to enable login using username/password. For that, add the following line
to `/etc/gitlab/gitlab.rb` file and [reconfigure](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure):

```ruby
grafana['disable_login_form'] = false
```

## Specifying an admin password

NOTE:
The admin password must be specified before the first reconfigure after
installation. After this, the `admin_password` setting doesn't have any effect,
and you'll have to [reset the password manually](#resetting-the-admin-password).
Also, to access the admin account, you have to [enable login using username and password](#enable-login-using-username-and-password).

To specify an admin password, add the following line to `/etc/gitlab/gitlab.rb`
file and [reconfigure](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure):

```ruby
grafana['admin_password'] = 'foobar'
```

If no admin password is provided, Omnibus GitLab will automatically generate a
random password for the `admin` user as a security measure. However, in that case
you will have to [reset the password manually](#resetting-the-admin-password)
to access the `admin` user.

## Enable Grafana alerts

Grafana can provide the ability to [create alerts](https://grafana.com/docs/grafana/next/alerting/alerting-rules/)
based on rules that you configure in your dashboard. By default, alerts are disabled in the bundled Grafana instance.

To enable Grafana alerts:

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   grafana['alerting_enabled'] = true
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Disabling Grafana

1. Edit `/etc/gitlab/gitlab.rb` and add/edit the following lines:

   ```ruby
   ## Set to true/false to enable/disable respectively
   grafana['enable'] = false
   ```

1. Save the file and [reconfigure](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure) GitLab for the changes to take effect.

## Authentication

If you want to give a user access to Grafana, you have two options.

### Using Grafana's authentication system

To allow users to create their own accounts in Grafana:

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines:

   ```ruby
   grafana['allow_user_sign_up'] = true
   ```

1. Save the file and [reconfigure](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure) GitLab for the changes to take effect.

### Using GitLab as an OAuth provider

NOTE:
If you're using GitLab 12.0 or later, this is automatically configured. You
can skip this section.

To use GitLab as an OAuth provider so that users of your GitLab instance
have access to Grafana:

1. First, [create an application ID and secret](https://docs.gitlab.com/ee/integration/oauth_provider.html).

1. Set the callback URL based on your `external_url`. For example `https://gitlab.example.com/-/grafana/login/gitlab`.

1. Then, edit `/etc/gitlab/gitlab.rb` and add the following lines:

   ```ruby
   grafana['gitlab_application_id'] = 'GITLAB_APPLICATION_ID'
   grafana['gitlab_secret'] = 'GITLAB_SECRET'
   ```

   Where `GITLAB_APPLICATION_ID` and `GITLAB_SECRET` the application ID and its
   secret that you created in the previous step.

1. Optionally, you can select a list of GitLab groups allowed to log in:

   ```ruby
   grafana['allowed_groups'] = [my_group, group_one/group_two]
   ```

1. Save the file and [reconfigure](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure) GitLab for the changes to take effect.

NOTE:
GitLab users are created with read-only Viewer privilege by default. The admin account must be used to grant additional access.

### Resetting the admin password

After the first startup, the admin password is stored in the Grafana datastore
and you cannot change it via `gitlab.rb`.

To update it, you can use the following command:

```shell
gitlab-ctl set-grafana-password
```

See the [Grafana CLI documentation](https://grafana.com/docs/grafana/next/cli/#reset-admin-password)
for more information.

## Dashboards

Starting with [GitLab 11.10](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4180), dashboards for monitoring Omnibus GitLab will be pre-loaded and available on initial login.

For earlier versions of GitLab, you can manually import the
[pre-built dashboards](https://gitlab.com/gitlab-org/grafana-dashboards/tree/master/omnibus)
that are tailored for Omnibus installations.

## Grafana metrics

Grafana can provide [metrics to be scraped by Prometheus](https://grafana.com/docs/grafana/next/setup-grafana/set-up-grafana-monitoring/).

By default, the metrics API is disabled in the bundled Grafana instance.

### Enabling Grafana's metrics API

To enable Grafana's metrics API with basic authentication:

1. Edit `/etc/gitlab/gitlab.rb` and add/edit the following lines:

   ```ruby
   grafana['metrics_enabled'] = true
   grafana['metrics_basic_auth_username'] = 'grafana_metrics'
   grafana['metrics_basic_auth_password'] = 'please_set_a_unique_password'
   ```

1. Save the file and [reconfigure](https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure) GitLab for the changes to take effect.

1. The metrics will be available at `https://gitlab.example.com/-/grafana/metrics`
   with basic authentication. The username and password for basic authentication
   will be the `metrics_basic_auth_username` and `metrics_basic_auth_password`
   that was set in `/etc/gitlab/gitlab.rb`.

## Grafana SMTP

Enable SMTP to allow Grafana to send emails:

```ruby
grafana['smtp']['enabled'] = true
```

To fully customize Grafana's SMTP configuration, use the following code snippet as a starting point:

```ruby
grafana['smtp'] = {
  'enabled' => true,
  'host' => 'localhost:25',
  'user' => nil,
  'password' => nil,
  'cert_file' => nil,
  'key_file' => nil,
  'skip_verify' => false,
  'from_address' => 'admin@grafana.localhost',
  'from_name' => 'Grafana',
  'ehlo_identity' => 'dashboard.example.com',
  'startTLS_policy' => nil
}
```

For more information on Grafana's SMTP configuration see Grafana's [documentation](https://grafana.com/docs/grafana/next/setup-grafana/configure-grafana/#smtp).

## Troubleshooting

### X.509: certificate signed by unknown authority

When using a self-signed SSL certificate for GitLab, you may get the following error in the UI:

```plaintext
login.OAuthLogin(NewTransportWithCode)

Check the Grafana server logs for the detailed error message.
```

The error reported in the Grafana logs at `/var/log/gitlab/grafana/current` can be:

```plaintext
lvl=eror msg=login.OAuthLogin(NewTransportWithCode) logger=context userId=0 orgId=0 uname= error="Post \"https://gitlab.example.com/oauth/token\": x509: certificate signed by unknown authority"
```

In this case, you must [install the self-signed GitLab certificate as trusted](ssl.md#install-custom-public-certificates).

### The redirect URI included is not valid

An incorrect callback URL commonly causes this error.
You may get this error when trying to log in to Grafana if the Callback URL is not correct.
To fix that:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Applications**.
1. Select **Edit** of the **GitLab Grafana** application.
1. Change the value of **Callback URL** to look like `https://gitlab.example.com/-/grafana/login/gitlab` where `https://gitlab.example.com` corresponds to your `external_url`.

### Client authentication failed due to unknown client, no client authentication included, or unsupported authentication method

These errors may happen if the GitLab Grafana OAuth application does not exist or
the settings in `/etc/gitlab/gitlab-secrets.json` are no longer consistent with each other.

WARNING:
The following steps may lead to data loss if the `/etc/gitlab/gitlab-secrets.json` file is corrupted.
Make sure to create a backup before applying any changes.

To fix it:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Applications**.
1. Remove the application **GitLab Grafana** if it exists by selecting **Destroy**.
1. Create a backup of `/etc/gitlab/gitlab-secrets.json` on your GitLab server.
1. Edit `/etc/gitlab/gitlab-secrets.json` and remove the section starting with `grafana`.
   You can find the relevant section with:

   ```shell
   $ grep grafana -A6 /etc/gitlab/gitlab-secrets.json

   "grafana": {
   "secret_key": "...",
   "gitlab_secret": "...",
   "gitlab_application_id": "...",
   "admin_password": "...",
   "metrics_basic_auth_password": null
   },
   ```

1. Reconfigure GitLab to re-create the **GitLab Grafana** application and regenerate the values in `/etc/gitlab/gitlab-secrets.json`:

   ```shell
   sudo gitlab-ctl reconfigure
   ```
