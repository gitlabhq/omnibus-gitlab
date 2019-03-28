# Grafana Dashboard Service

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3487) in GitLab 11.9.

[Grafana](https://grafana.com/) is a powerful dashboard building system that
you can use to visualize performance metrics from the [embedded Prometheus](prometheus.md)
monitoring system.

## Enabling Grafana

Grafana is not enabled by default. To enable it:

1. Edit `/etc/gitlab/gitlab.rb` and add/edit the following lines:

   ```ruby
   ## The URL of your GitLab instance
   external_url "https://gitlab.example.com"

   ## Set to true/false to enable/disable respectively
   grafana['enable'] = true

   ## The default admin password is 'admin', change it here
   grafana['admin_password'] = 'admin'
   ```

1. Save the file and [reconfigure] GitLab for the changes to take effect.
1. Once enabled, Grafana will be available on `https://gitlab.example.com/-/grafana`
   where you can log in with the username `admin` and the password you set.

NOTE: **Note:**
The admin password must be changed before the first startup of Grafana. After this the configuration setting does not have any effect. See below for admin password reset information.

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

To use GitLab as an OAuth provider so that users of your GitLab instance
have access to Grafana:

1. First, [create an application ID and secret](https://docs.gitlab.com/ce/integration/oauth_provider.html).
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

### Reset admin password

After the first startup, the admin password is stored in the Grafana datastore. To update it you must follow a reset procedure.

   ```console
   $ gitlab-ctl stop grafana
   $ /opt/gitlab/embedded/bin/grafana-cli admin reset-admin-password \
       --homepath /var/opt/gitlab/grafana NewPassword
   $ gitlab-ctl start grafana
   ```

See the [Grafana CLI documentation][reset-admin-password] for more information.

## Dashboards

Once Grafana is up, you can start importing the
[pre-built dashboards](https://gitlab.com/gitlab-org/grafana-dashboards/tree/master/omnibus)
that are tailored for Omnibus installations.

NOTE: **Note:**
The pre-built dashboards will be automatically loaded in a future release.
Follow [issue 4180](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/4180)
for more information.

[reconfigure]: https://docs.gitlab.com/ee/administration/restart_gitlab.html#omnibus-gitlab-reconfigure
[reset-admin-password]: http://docs.grafana.org/administration/cli/#reset-admin-password
