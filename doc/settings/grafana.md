# Grafana Dashboard Service

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3487) in GitLab 11.9.

[Grafana](https://grafana.com/) is a powerful dashboard building system that
you can use to visualize performance metrics from the [embedded Prometheus](prometheus.md)
monitoring system.

Starting with GitLab 12.0, Grafana is enabled by default and SSO with GitLab is
automatically configured. Grafana will be available on `https://gitlab.example.com/-/grafana`.

## Specifying an admin password

Default admin credentials for Grafana is `root` as both username and password.
It is recommended that you change this admin password. After logging in
initially using these credentials, Grafana will present you with a screen to
change the password.

You can also set the admin password in `/etc/gitlab/gitlab.rb` file, to do this
without using the UI.

NOTE: **Note:**
The admin password must be specified before the first reconfigure after
installation. After this, the `admin_password` setting doesn't have any effect,
and you'll have to [reset the password manually](#resetting-the-admin-password).

To specify an admin password, add the following line to `/etc/gitlab/gitlab.rb`
file and [reconfigure]:

```
grafana['admin_password'] = 'foobar'
```

## Disabling Grafana

1. Edit `/etc/gitlab/gitlab.rb` and add/edit the following lines:

   ```ruby
   ## Set to true/false to enable/disable respectively
   grafana['enable'] = false
   ```

1. Save the file and [reconfigure] GitLab for the changes to take effect.

## Authentication

If you want to give a user access to Grafana, you have two options.

### Using Grafana's authentication system

To allow users to create their own accounts in Grafana:

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines:

   ```ruby
   grafana['allow_user_sign_up'] = true
   ```

1. Save the file and [reconfigure] GitLab for the changes to take effect.

### Using GitLab as an OAuth provider

NOTE: **Note:**
If you're using GitLab 12.0 or later, this is automatically configured. You
can skip this section.

To use GitLab as an OAuth provider so that users of your GitLab instance
have access to Grafana:

1. First, [create an application ID and secret](https://docs.gitlab.com/ce/integration/oauth_provider.html).

1. Set the callback URL based on your `external_url`. For example `https://gitlab.example.com/-/grafana/login/gitlab`.

1. Then, edit `/etc/gitlab/gitlab.rb` and add the following lines:

   ```ruby
   grafana['gitlab_application_id'] = 'GITLAB_APPLICATION_ID'
   grafana['gitlab_secret'] = 'GITLAB_SECRET'
   ```

   Where `GITLAB_APPLICATION_ID` and `GITLAB_SECRET` the application ID and its
   secret that you created in the previous step.

1. Optionally, you can select a list of GitLab groups allowed to login:

   ```ruby
   grafana['allowed_groups'] = [my_group, group_one/group_two]
   ```

1. Save the file and [reconfigure] GitLab for the changes to take effect.

NOTE: **Note:**
GitLab users are created with read-only Viewer privilege by default. The admin account must be used to grant additional access.

### Resetting the admin password

After the first startup, the admin password is stored in the Grafana datastore
and you cannot change it via `gitlab.rb`.

To update it, you must follow a reset procedure:

```sh
gitlab-ctl stop grafana

/opt/gitlab/embedded/bin/grafana-cli admin reset-admin-password \
  --homepath /var/opt/gitlab/grafana <NewPassword>

gitlab-ctl start grafana
```

See the [Grafana CLI documentation](http://docs.grafana.org/administration/cli/#reset-admin-password)
for more information.

## Dashboards

Starting with [GitLab 11.10](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/4180), dashboards for monitoring Omnibus GitLab will be pre-loaded and available on initial login.

For earlier versions of GitLab, you can manually import the
[pre-built dashboards](https://gitlab.com/gitlab-org/grafana-dashboards/tree/master/omnibus)
that are tailored for Omnibus installations.

[reconfigure]: https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure
