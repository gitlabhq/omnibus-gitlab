# GitLab Mattermost

You can run a [GitLab Mattermost](http://www.mattermost.org/)
service on your GitLab server.

## Documentation version

Make sure you view this guide from the tag (version) of GitLab you would like to install. In most cases this should be the highest numbered production tag (without rc in it). You can select the tag in the version dropdown in the top left corner of GitLab (below the menu bar).

If the highest number stable branch is unclear please check the [GitLab Blog](https://about.gitlab.com/blog/) for installation guide links by version.

## Pre-requisite 

GitLab Mattermost is compiled and manually tested each release on an AMD 64 chipset for Linux. ARM chipsets and operating systems, like Raspberry PI, are not supported. 

## Getting started

GitLab Mattermost expects to run on its own virtual host. In your DNS you would then
have two entries pointing to the same machine, e.g. `gitlab.example.com` and
`mattermost.example.com`.

GitLab Mattermost is disabled by default, to enable it just tell omnibus-gitlab what
the external URL for Mattermost server is:

```ruby
# in /etc/gitlab/gitlab.rb
mattermost_external_url 'http://mattermost.example.com'
```

After you run `sudo gitlab-ctl reconfigure`, your GitLab Mattermost should
now be reachable at `http://mattermost.example.com` and authorized to connect to GitLab. Authorising Mattermost with GitLab will allow users to use GitLab as SSO provider.

Omnibus-gitlab package will attempt to automatically authorise GitLab Mattermost with GitLab if applications are running on the same server.
This is because automatic authorisation requires access to GitLab database.
If GitLab database is not available you will need to manually authorise GitLab Mattermost for access to GitLab.

## Running GitLab Mattermost on its own server

If you want to run GitLab and GitLab Mattermost on two separate servers you
can use the following settings on the GitLab Mattermost server to effectively disable
the GitLab service bundled into the Omnibus package. The GitLab services will
still be set up on your GitLab Mattermost server, but they will not accept user requests or
consume system resources.

```ruby
mattermost_external_url 'http://mattermost.example.com'

# Tell GitLab Mattermost to integrate with gitlab.example.com

mattermost['gitlab_enable'] = true
mattermost['gitlab_id'] = "12345656"
mattermost['gitlab_secret'] = "123456789"
mattermost['gitlab_scope'] = ""
mattermost['gitlab_auth_endpoint'] = "http://gitlab.example.com/oauth/authorize"
mattermost['gitlab_token_endpoint'] = "http://gitlab.example.com/oauth/token"
mattermost['gitlab_user_api_endpoint'] = "http://gitlab.example.com/api/v3/user"

# Shut down GitLab services on the Mattermost server
gitlab_rails['enable'] = false
```

where `Secret` and `Id` are `application secret` and `application id` received when creating new `Application` authorization in GitLab admin section.

Optionally, you can set `mattermost['email_enable_sign_up_with_email'] = false` to force all users to sign-up with GitLab only. See Mattermost [documentation on GitLab SSO](https://docs.mattermost.com/deployment/sso-gitlab.html).

## Manually (re)authorising GitLab Mattermost with GitLab

### Authorise GitLab Mattermost

To do this, using browser navigate to the `admin area` of GitLab, `Application` section. Create a new application and for the callback URL use: `http://mattermost.example.com/signup/gitlab/complete` and `http://mattermost.example.com/login/gitlab/complete` (replace http with https if you use https).

Once the application is created you will receive an `Application ID` and `Secret`. One other information needed is the URL of GitLab instance.

Now, go to the GitLab server and edit the `/etc/gitlab/gitlab.rb` configuration file.

In `gitlab.rb` use the values you've received above:

```
mattermost['gitlab_enable'] = true
mattermost['gitlab_id'] = "12345656"
mattermost['gitlab_secret'] = "123456789"
mattermost['gitlab_scope'] = ""
mattermost['gitlab_auth_endpoint'] = "http://gitlab.example.com/oauth/authorize"
mattermost['gitlab_token_endpoint'] = "http://gitlab.example.com/oauth/token"
mattermost['gitlab_user_api_endpoint'] = "http://gitlab.example.com/api/v3/user"
```

Save the changes and then run `sudo gitlab-ctl reconfigure`.

If there are no errors your GitLab and GitLab Mattermost should be configured correctly.

### Reauthorise GitLab Mattermost

To reauthorise GitLab Mattermost you will first need to revoke access of the existing authorisation. This can be done in the Admin area of GitLab under `Applications`. Once that is done follow the steps in the `Authorise GitLab Mattermost` section.

## Running GitLab Mattermost with HTTPS

Place the ssl certificate and ssl certificate key inside of `/etc/gitlab/ssl` directory. If directory doesn't exist, create one.

In `/etc/gitlab/gitlab.rb` specify the following configuration:

```ruby
mattermost_external_url 'https://mattermost.gitlab.example'

mattermost_nginx['redirect_http_to_https'] = true
mattermost_nginx['ssl_certificate'] = "/etc/gitlab/ssl/mattermost-nginx.crt"
mattermost_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/mattermost-nginx.key"
mattermost['service_use_ssl'] = true
```

where `mattermost-nginx.crt` and `mattermost-nginx.key` are ssl cert and key, respectively.
Once the configuration is set, run `sudo gitlab-ctl reconfigure` for the changes to take effect.

## Setting up SMTP for GitLab Mattermost

By default, `mattermost['email_enable_sign_up_with_email'] = true` which allows team creation and account signup using email and password. This should be `false` if you're using only an external authentication source such as GitLab.

SMTP configuration depends on SMTP provider used.  Note that the configuration keys used are not the same as the ones that the main GitLab application uses, for example the SMTP user in Mattermost is `email_smtp_username` and not `smtp_user_name`.

If you are using SMTP without TLS minimal configuration in `/etc/gitlab/gitlab.rb` contains:

```ruby
mattermost['email_enable_sign_in_with_email'] = false
mattermost['email_enable_sign_up_with_email'] = false
mattermost['email_send_email_notifications'] = true
mattermost['email_smtp_username'] = "username"
mattermost['email_smtp_password'] = "password"
mattermost['email_smtp_server'] = "smtp.example.com"
mattermost['email_smtp_port'] = "465"
mattermost['email_connection_security'] = nil
mattermost['email_feedback_name'] = "GitLab Mattermost"
mattermost['email_feedback_email'] = "email@example.com"
```

If you are using TLS, configuration can look something like this:

```ruby
mattermost['email_enable_sign_up_with_email'] = true
mattermost['email_smtp_username'] = "username"
mattermost['email_smtp_password'] = "password"
mattermost['email_smtp_server'] = "smtp.example.com"
mattermost['email_smtp_port'] = "587"
mattermost['email_connection_security'] = 'TLS' # Or 'STARTTLS'
mattermost['email_feedback_name'] = "GitLab Mattermost"
mattermost['email_feedback_email'] = "email@example.com"
```

`email_connection_security` depends on your SMTP provider so you need to verify which of `TLS` or `STARTTLS` is valid for your provider.

Once the configuration is set, run `sudo gitlab-ctl reconfigure` for the changes to take effect.

## Community Support Resources

For help and support around your GitLab Mattermost deployment please see:

- [Troubleshooting Forum](https://forum.mattermost.org/t/about-the-trouble-shooting-category/150/1) for configuration questions and issues
- [Troubleshooting FAQ](http://docs.mattermost.com/install/troubleshooting.html)
- [GitLab Mattermost issue tracker](https://gitlab.com/gitlab-org/gitlab-mattermost/issues) for verified bugs with repro steps

## Upgrading GitLab Mattermost

Note: These upgrade instructions are for GitLab Version 8.9 (Mattermost v3.1.0) and above. For upgrading versions prior to GitLab 8.9, [additional steps are required](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc//gitlab-mattermost/README.md#upgrading-gitlab-mattermost-from-versions-prior-to-89).  
  
| GitLab Version | Mattermost Version |
|----------------|--------------------|
| 8.9            | v3.1.0             |
| 8.10           | v3.2.0             |
| 8.11           | v3.3.0             |
| 8.12           | v3.4.0             |  
  
It is possible to skip upgrade versions starting from Mattermost v3.1. For example, Mattermost v3.1.0 in GitLab 8.9 can upgrade directly to Mattermost v3.4.0 in GitLab 8.12. 

GitLab Mattermost can be upgraded through the regular GitLab omnibus update process provided Mattermost configuration settings have not been changed outside of GitLab. This means no changes to Mattermost's `config.json` file have been made, either directly or via the Mattermost **System Console** which saves back changes to `config.json`.

If this is the case, upgrading GitLab using omnibus and running `gitlab-ctl reconfigure` should upgrade GitLab Mattermost to the next version.

If this is not the case, there are two options:

1. Update [`gitlab.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template#L706) with the changes done to `config.json`
   This might require adding some parameters as not all settings in `config.json` are available in `gitlab.rb`. Once complete, GitLab omnibus should be able to upgrade GitLab Mattermost from one version to the next.
2. Migrate Mattermost outside of the directory controlled by GitLab omnibus so it can be administered and upgraded independently (see below).

**Special Considerations**

Consider these notes when upgrading GitLab Mattermost:

1. If public links are enabled, upgrading to Mattermost v3.4 will invalidate existing public links due to a security upgrade allowing admins to invalidate links by resetting a public link salt from the System Console.
2. Upgrading from v3.2 to v3.4 will be incomplete due to a migration code not being run properly. You can either:
    - Upgrade from v3.2 to v3.3 and then from v3.3 to v3.4, or
    - Upgrade from v3.2 to v3.4, then run the following SQL query to make Mattermost rerun upgrade steps that were not properly completed: `UPDATE Systems SET Value = '3.1.0' WHERE Name = 'Version';`


## Upgrading GitLab Mattermost from versions prior to 8.9

After upgrading to GitLab 8.9 additional steps are require before restarting the Mattermost server to enable multi-account support in Mattermost 3.1.

1. Confirm you are starting with version GitLab 8.8.
1. Backup your Mattermost database.
     - This is especially important in the 8.9 upgrade since the database upgrade cannot be reversed and is incompatible with previous versions.
     - If you use a default omnibus install you can use this command: `sudo -u gitlab-psql -- /opt/gitlab/embedded/bin/pg_dump -h /var/opt/gitlab/postgresql mattermost_production | gzip > mattermost_dbdump_$(date --rfc-3339=date).sql.gz`
1. Configure two settings.
     - In ` /etc/gitlab/gitlab.rb` set `mattermost['db2_backup_created'] = true` to verify your database backup is complete.
     - In ` /etc/gitlab/gitlab.rb` set `mattermost['db2_team_name'] = "TEAMNAME"` where TEAMNAME is the name of your primary team in Mattermost.
          - If you use only one team in Mattermost, this should be the name of the team.
          - If you use multiple teams, this should be the name of the team most commonly used.
               - When Mattermost 3.1 upgrades the database with multi-team account support user accounts on the primary team are preserved, and accounts with duplciate emails or usernames in other teams are renamed.
               - Users with renamed accounts receive instructions by email on how to switch from using multiple accounts into one multi-team account.
               - For more information, please review the [Mattermost 3.0 upgrade documentation.](http://www.mattermost.org/upgrade-to-3-0/)
1. Run your GitLab 8.9 upgrade as normal.
    - This installs the Mattermost 3.1 binary and will attempt to auto-upgrade the database.
    - Your Mattermost database will be upgraded to version 3.1 and the server should start.
    - You'll see an "Automatic database upgrade failed" error on the command line and Mattermost will not start if something goes wrong.

If you experience issues you can run an interactive upgrade using:

```
sudo -u mattermost -i bash
cd /opt/gitlab/embedded/service/mattermost
/opt/gitlab/embedded/bin/mattermost -config='/var/opt/gitlab/mattermost/config.json' -upgrade_db_30
```

Log in as root or user with super user access and re-run `sudo gitlab-ctl reconfigure`.

For any questions, please [visit the GitLab Mattermost troubleshooting forum](https://forum.mattermost.org/t/upgrading-to-gitlab-mattermost-in-gitlab-8-9/1735) and share any relevant portions of `mattermost.log` along with the step at which you encountered issues.

### Migrating Mattermost outside of GitLab

Follow the [Mattermost Migration Guide](http://docs.mattermost.com/administration/migrating.html) to move your Mattermost configuration settings and data to another directory or server independent from GitLab omnibus.

### Upgrading GitLab Mattermost outside of GitLab

If you choose to upgrade Mattermost outside of GitLab's omnibus automation, please [follow this guide](http://docs.mattermost.com/administration/upgrade-guide.html).

## Administering GitLab Mattermost

### GitLab notifications in Mattermost

There are multiple ways to send notifications depending on how much control you'd like over the messages.

If you are using the Omnibus edition, enable incoming webhooks from the gitlab.rb file not the System Console or your settings will be lost the next time you upgrade GitLab Omnibus.

```ruby
mattermost['service_enable_incoming_webhooks'] = true
```

#### Setting up Mattermost as a Slack project service integration:

Mattermost is "Slack-compatible, not Slack-limited" so if you like Slack's default formatting you can use their project service option to set up Mattermost integration:

1. In Mattermost, go to **System Console** → **Service Settings** and turn on **Enable Incoming Webhooks**
1. Go to **Account Settings** → **Integrations** → **Incoming Webhooks**
2. Select a channel and click **Add* and copy the `Webhook URL`
3. In GitLab, paste the `Webhook URL` into **Webhook** under your project’s **Settings** → **Services** → **Slack**
4. Enter **Username** for how you would like to name the account that posts the notifications
4. Select **Triggers** for GitLab events on which you'd like to receive notifications
6. Click **Save changes** then **Test settings** to make sure everything is working

Any issues, please see the [Mattermost Troubleshooting Forum](https://forum.mattermost.org/t/how-to-use-the-troubleshooting-forum/150).

#### Setting up GitLab integration service for Mattermost

You can also set up the [open source integration service](https://github.com/NotSqrt/mattermost-integration-gitlab) to let you configure notifications on GitLab issues, pushes, build events, merge requests and comments to be delivered to selected Mattermost channels.

This integration lets you completely control how notifications are formatted and, unlike Slack, offers full markdown support.

The source code can be modified to support not only GitLab, but any in-house applications you may have that support webhooks. Also see:
- [Mattermost incoming webhook documentation](http://docs.mattermost.com/developer/webhooks-incoming.html)
- [GitLab webhook documentation](http://doc.gitlab.com/ce/web_hooks/web_hooks.html)

![webhooks](https://gitlab.com/gitlab-org/omnibus-gitlab/uploads/677b0aa055693c4dcabad0ee580c61b8/730_gitlab_feature_request.png)

### Specify numeric user and group identifiers

omnibus-gitlab creates a user and group mattermost. You can specify the
numeric identifiers for these users in `/etc/gitlab/gitlab.rb` as follows.

```ruby
mattermost['uid'] = 1234
mattermost['gid'] = 1234
```

Run `sudo gitlab-ctl reconfigure` for the changes to take effect.

### OAuth2 Sequence Diagram

The following image is a sequence diagram for how GitLab works as an OAuth2
provider for Mattermost. It may be useful to use this to troubleshoot errors
in getting the integration to work:

![sequence diagram](img/gitlab-mattermost.png)
