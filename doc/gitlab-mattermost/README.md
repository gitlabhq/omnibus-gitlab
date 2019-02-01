# GitLab Mattermost

You can run a [GitLab Mattermost](http://www.mattermost.org/)
service on your GitLab server.

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
can use the following settings and configuration details on the GitLab Mattermost server to effectively disable
the GitLab service bundled into the Omnibus package. The GitLab services will
still be set up on your GitLab Mattermost server, but they will not accept user requests or
consume system resources.

```ruby
mattermost_external_url 'http://mattermost.example.com'

# Shut down GitLab services on the Mattermost server
gitlab_rails['enable'] = false
redis['enable'] = false
```

Then following the details in [Authorise GitLab Mattermost section](#authorise-gitlab-mattermost).

To enable integrations with GitLab, add the following on the GitLab Server:
```ruby
gitlab_rails['mattermost_host'] = "https://mattermost.example.com"
```

By default GitLab Mattermost will force all users to sign-up with GitLab and disable sign-up by email option. See Mattermost [documentation on GitLab SSO](https://docs.mattermost.com/deployment/sso-gitlab.html).

## Manually (re)authorising GitLab Mattermost with GitLab

### Authorise GitLab Mattermost

To do this, using browser navigate to the Admin area of GitLab, `Application` section. Create a new application and for the `Redirect URI` use:

```
http://mattermost.example.com/signup/gitlab/complete
http://mattermost.example.com/login/gitlab/complete
```
(replace `http` with `https` if you use https).

Once the application is created you will receive an `Application ID` and `Secret`. One other piece of information needed is the URL of GitLab instance.

Now, go to the server running GitLab Mattermost and edit the `/etc/gitlab/gitlab.rb`
configuration file as follows using the values you've received above:

```
mattermost['gitlab_enable'] = true
mattermost['gitlab_id'] = "12345656"
mattermost['gitlab_secret'] = "123456789"
mattermost['gitlab_scope'] = ""
mattermost['gitlab_auth_endpoint'] = "http://gitlab.example.com/oauth/authorize"
mattermost['gitlab_token_endpoint'] = "http://gitlab.example.com/oauth/token"
mattermost['gitlab_user_api_endpoint'] = "http://gitlab.example.com/api/v4/user"
```

Save the changes and then run `sudo gitlab-ctl reconfigure`.

If there are no errors your GitLab and GitLab Mattermost should be configured correctly.

### Reauthorise GitLab Mattermost

To reauthorise GitLab Mattermost you will first need to revoke access of the existing
authorisation. This can be done in the Admin area of GitLab under `Applications`.
Once that is done follow the steps in the [Authorise GitLab Mattermost section](#authorise-gitlab-mattermost).

## Configuring Mattermost

### With GitLab 11.0

Starting in GitLab 11.0, Mattermost can be configured using the Mattermost System Console. An extensive list of
Mattermost settings and where they can be set is available [in the Mattermost documentation](https://docs.mattermost.com/administration/config-settings.html).

While using the System Console is recommended, you can also configure Mattermost using one of the following:
1. You can edit the Mattermost configuration directly through `/var/opt/gitlab/mattermost/config.json`.
1. You can specify environment variables used to run Mattermost by changing the `mattermost['env']` setting in
`gitlab.rb`. Any settings configured in this way will be disabled from the System Console and cannot be changed
without restarting Mattermost.

### Prior to GitLab 11.0

Before GitLab 11.0, Mattermost should be configured through `gitlab.rb`. Changes could also be made through the
System Console, but any changes made outside of `gitlab.rb` would be overwritten. See [the upgrade section](#upgrading-gitlab-mattermost)
for more details.

## Running GitLab Mattermost with HTTPS

Place the ssl certificate and ssl certificate key inside of `/etc/gitlab/ssl` directory. If directory doesn't exist, create one.

```bash
sudo mkdir -p /etc/gitlab/ssl
sudo chmod 700 /etc/gitlab/ssl
sudo cp mattermost.gitlab.example.key mattermost.gitlab.example.crt /etc/gitlab/ssl/
```

In `/etc/gitlab/gitlab.rb` specify the following configuration:

```ruby
mattermost_external_url 'https://mattermost.gitlab.example'

mattermost_nginx['redirect_http_to_https'] = true
```

If you haven't named your certificate and key like `mattermost.gitlab.example.crt`
and `mattermost.gitlab.example.key` then you'll need to also add the full paths
like shown below.

```
mattermost_nginx['ssl_certificate'] = "/etc/gitlab/ssl/mattermost-nginx.crt"
mattermost_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/mattermost-nginx.key"
```

where `mattermost-nginx.crt` and `mattermost-nginx.key` are ssl cert and key, respectively.

Once the configuration is set, run `sudo gitlab-ctl reconfigure` for the changes to take effect.

## Email Notifications

### Setting up SMTP for GitLab Mattermost

#### With GitLab 11.0

As of GitLab 11.0, these settings are configured through the Mattermost **System Console** by a user logged
into Mattermost as a System Administrator. On  the **Notifications** > **Email** tab of the **System Console**,
you can enter the SMTP credentials given by your SMTP provider or `127.0.0.1` and port `25` to use `sendmail`.
More information on the specific settings
that are needed is available in the [Mattermost documentation](https://docs.mattermost.com/install/smtp-email-setup.html).

These settings can also be configured in `/var/opt/gitlab/mattermost/config.json`.

#### Prior to GitLab 11.0

SMTP configuration depends on SMTP provider used.  Note that the configuration keys used are not the same as the ones that the main GitLab application uses, for example the SMTP user in Mattermost is `email_smtp_username` and not `smtp_user_name`.

If you are using SMTP without TLS minimal configuration in `/etc/gitlab/gitlab.rb` contains:

```ruby
mattermost['email_enable_sign_in_with_email'] = false
mattermost['email_enable_sign_up_with_email'] = false
mattermost['email_send_email_notifications'] = true
mattermost['email_smtp_auth'] = true
mattermost['email_smtp_username'] = "username"
mattermost['email_smtp_password'] = "password"
mattermost['email_smtp_server'] = "smtp.example.com"
mattermost['email_smtp_port'] = "465"
mattermost['email_connection_security'] = nil
mattermost['email_feedback_name'] = "GitLab Mattermost"
mattermost['email_feedback_email'] = "email@example.com"
mattermost['email_skip_server_certificate_verification'] = false
```

If you are using TLS, configuration can look something like this:

```ruby
mattermost['email_enable_sign_in_with_email'] = true
mattermost['email_enable_sign_up_with_email'] = false
mattermost['email_send_email_notifications'] = true
mattermost['email_smtp_auth'] = true
mattermost['email_smtp_username'] = "username"
mattermost['email_smtp_password'] = "password"
mattermost['email_smtp_server'] = "smtp.example.com"
mattermost['email_smtp_port'] = "587"
mattermost['email_connection_security'] = 'TLS' # Or 'STARTTLS'
mattermost['email_feedback_name'] = "GitLab Mattermost"
mattermost['email_feedback_email'] = "email@example.com"
mattermost['email_skip_server_certificate_verification'] = false
```

`email_connection_security` depends on your SMTP provider so you need to verify which of `TLS` or `STARTTLS` is valid for your provider.

### Email Batching

#### With GitLab 11.0

Enabling this feature allows users to control how often they receive email notifications. Configuring the site URL,
including protocol and port, is required if different from `mattermost_external_url`:

```ruby
mattermost['service_site_url'] = 'https://mattermost.example.com'
```

Then, run `sudo gitlab-ctl reconfigure` for the changes to take effect.

With the site URL configured, email batching can be enabled in the Mattermost **System Console** by going to the **Notifications** > **Email**
tab, and setting the `Enable Email Batching` setting to true

This setting can also be configured in `/var/opt/gitlab/mattermost/config.json`.

#### Prior to GitLab 11.0

Enabling this feature allows users to control how often they receive email notifications. Configuring the site URL, including protocol and port, is required if different from `mattermost_external_url`:

```ruby
mattermost['service_site_url'] = 'https://mattermost.example.com'
mattermost['email_enable_batching'] = true
```

Once the configuration is set, run `sudo gitlab-ctl reconfigure` for the changes to take effect.

For additional configuration settings, see the [Mattermost documentation](https://docs.mattermost.com/administration/config-settings.html).

## Community Support Resources

For help and support around your GitLab Mattermost deployment please see:

- [Troubleshooting Forum](https://forum.mattermost.org/t/about-the-trouble-shooting-category/150/1) for configuration questions and issues
- [Troubleshooting FAQ](http://docs.mattermost.com/install/troubleshooting.html)
- [Mattermost GitLab Issues Support Handbook](https://docs.mattermost.com/process/support.html?highlight=omnibus#gitlab-issues)
- [GitLab Mattermost issue tracker](https://gitlab.com/gitlab-org/gitlab-mattermost/issues) for verified bugs with repro steps

## Upgrading GitLab Mattermost

> Note: These upgrade instructions are for GitLab Version 8.9 (Mattermost v3.1.0) and above. For upgrading versions prior to GitLab 8.9, [additional steps are required](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc//gitlab-mattermost/README.md#upgrading-gitlab-mattermost-from-versions-prior-to-89).

Below is a list of Mattermost versions for GitLab 9.0 and later:

| GitLab Version  | Mattermost Version |
| :------------ |:----------------|
| 9.0, 9.1 | 3.7 |
| 9.2 | 3.9 |
| 9.3 | 3.10 |
| 9.4 | 4.0 |
| 9.5 | 4.1 |
| 10.0, 10.1 | 4.2 |
| 10.2 | 4.3 |
| 10.3 | 4.4 |
| 10.4 | 4.5 |
| 10.5 | 4.6 |
| 10.6 | 4.7 |
| 10.7 | 4.8 |
| 10.8 | 4.9 |
| 11.0 | 4.10 |
| 11.1 | 5.0 |
| 11.2 | 5.1 |
| 11.3 | 5.2 |
| 11.4 | 5.3 |
| 11.5 | 5.4 |
| 11.6 | 5.5 |
| 11.7 | 5.6 |
| 11.8 | 5.7 |

It is possible to skip upgrade versions starting from Mattermost v3.1. For example, Mattermost v3.1.0 in GitLab 8.9 can upgrade directly to Mattermost v3.4.0 in GitLab 8.12.

Starting with GitLab 11.0, GitLab Mattermost can be upgraded through the regular GitLab omnibus update process. When upgrading GitLab prior to that, that process can only be used if Mattermost configuration settings have not been changed outside of GitLab. This means no changes to Mattermost's `config.json` file have been made, either directly or via the Mattermost **System Console** which saves back changes to `config.json`.

If you are upgrading to at least GitLab 11.0 or have only configured Mattermost using `gitlab.rb`, you can upgrade GitLab using omnibus and then run `gitlab-ctl reconfigure` to upgrade GitLab Mattermost to the latest version.

If this is not the case, there are two options:

1. Update [`gitlab.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template#L706) with the changes done to `config.json`
   This might require adding some parameters as not all settings in `config.json` are available in `gitlab.rb`. Once complete, GitLab omnibus should be able to upgrade GitLab Mattermost from one version to the next.
2. Migrate Mattermost outside of the directory controlled by GitLab omnibus so it can be administered and upgraded independently (see below).

**Special Considerations**

Consider these notes when upgrading GitLab Mattermost:

1. Starting in Mattermost v4.2, user-supplied URLs such as those used for Open Graph metadata, webhooks, or slash commands will no longer be allowed to connect to reserved IP addresses including loopback or link-local addresses used for internal networks by default. This change may cause private integrations to break in testing environments, which may point to a URL such as http://127.0.0.1:1021/my-command.
    - If you point private integrations to such URLs, you may whitelist such domains, IP addresses, or CIDR notations via the [AllowedUntrustedInternalConnections config setting](https://github.com/mattermost/docs/blob/05cd1685deff85b2a2c5130d889f935b808ae159/source/administration/config-settings.rst#allow-untrusted-internal-connections-to) in your local environment. Although not recommended, you may also whitelist the addresses in your production environments.
    - Push notification, OAuth 2.0 and WebRTC server URLs are trusted and not affected by this setting.
1. Starting in Mattermost v4.2, Mattermost now handles multiple content-types for integrations. Make sure your integrations have been set to use the appropriate content-type.

For a complete list of upgrade notices from older versions, see the [Mattermost documentation](https://docs.mattermost.com/administration/important-upgrade-notes.html).

## Upgrading GitLab Mattermost from versions prior to 11.0

With version 11.0, GitLab will introduce breaking changes regarding Mattermost configuration.
In versions prior to GitLab 11.0 all
Mattermost related settings were configurable from the `gitlab.rb` file, which
generated the Mattermost `config.json` file. However, Mattermost also
permitted configuration via its System Console. This configuration ended up in
the same `config.json` file, which resulted in changes made via the System Console being
overwritten when users ran `gitlab-ctl reconfigure`.

To resolve this problem, `gitlab.rb` will include only the
configuration necessary for GitLab<=>Mattermost integration in 11.0. GitLab will no longer
generate the `config.json` file, instead passing limited configuration settings via environment variables.

The settings that continue to be supported in `gitlab.rb` can be found in
[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).

With GitLab 11.0, other Mattermost settings can be configured through Mattermost's System Console,
by editing `/var/opt/gitlab/mattermost/config.json`, or by using `mattermost['env']` in `gitlab.rb`.

If you would like to keep configuring Mattermost using `gitlab.rb`, you can take the following actions
in preparation for GitLab 11.0:

1. Upgrade to version 10.x which supports the new `mattermost['env']` setting.
1. Configure any settings not listed above through the `mattermost['env']` setting. Mattermost requires
environment variables to be provided in `MM_<CATEGORY>SETTINGS_<ATTRIBUTE>` format. Below is an example
of how to convert the old settings syntax to the new one.

The following settings in `gitlab.rb`:

```ruby
mattermost['service_maximum_login_attempts'] = 10
mattermost['team_teammate_name_display'] = "full_name"
mattermost['sql_max_idle_conns'] = 10
mattermost['log_file_level'] = 'INFO'
mattermost['email_batching_interval'] = 30
mattermost['file_enable_file_attachments'] = true
mattermost['ratelimit_memory_store_size'] = 10000
mattermost['support_terms_of_service_link'] = "/static/help/terms.html"
mattermost['privacy_show_email_address'] = true
mattermost['localization_available_locales'] = "en,es,fr,ja,pt-BR"
mattermost['webrtc_enable'] = false
```

Would translate to:

```ruby
mattermost['env'] = {
                    'MM_SERVICESETTINGS_MAXIMUMLOGINATTEMPTS' => '10',
                    'MM_TEAMSETTINGS_TEAMMATENAMEDISPLAY' => 'full_name',
                    'MM_SQLSETTINGS_MAXIDLECONNS' => '10',
                    'MM_LOGSETTINGS_FILELEVEL' => 'INFO',
                    'MM_EMAILSETTINGS_BATCHINGINTERVAL' => '30',
                    'MM_FILESETTINGS_ENABLEFILEATTACHMENTS' => 'true',
                    'MM_RATELIMITSETTINGS_MEMORYSTORESIZE' => '10000',
                    'MM_SUPPORTSETTINGS_TERMSOFSERVICELINK' => '/static/help/terms.html',
                    'MM_PRIVACYSETTINGS_SHOWEMAILADDRESS' => 'true',
                    'MM_LOCALIZATIONSETTINGS_AVAILABLELOCALES' => 'en,es,fr,ja,pt-BR',
                    'MM_WEBRTCSETTINGS_ENABLE' => 'false'
                    }
```

Refer to [Mattermost
Documentation](https://docs.mattermost.com/administration/config-settings.html)
for details about categories, configuration values, etc.

There are a few exceptions to this rule:

 1. `ServiceSettings.ListenAddress` configuration of Mattermost is configured
    by `mattermost['service_address']` and `mattermost['service_port']` settings.
 2. Configuration settings named in an inconsistent way are given in the
    following table. Use these mappings while converting them to environment
    variables.

|`gitlab.rb` configuration|Environment variable|
|---|---|
|`mattermost['service_lets_encrypt_cert_cache_file']`|`MM_SERVICESETTINGS_LETSENCRYPTCERTIFICATECACHEFILE`|
|`mattermost['service_user_access_tokens']`|`MM_SERVICESETTINGS_ENABLEUSERACCESSTOKENS`|
|`mattermost['log_console_enable']`|`MM_LOGSETTINGS_ENABLECONSOLE`|
|`mattermost['email_enable_batching']`|`MM_EMAILSETTINGS_ENABLEEMAILBATCHING`|
|`mattermost['email_batching_buffer_size']`|`MM_EMAILSETTINGS_EMAILBATCHINGBUFFERSIZE`|
|`mattermost['email_batching_interval']`|`MM_EMAILSETTINGS_EMAILBATCHINGINTERVAL`|
|`mattermost['email_smtp_auth']`|`MM_EMAILSETTINGS_ENABLESMTPAUTH`|
|`mattermost['email_notification_content_type']`|`MM_EMAILSETTINGS_NOTIFICATIONCONTENTTYPE`|
|`mattermost['ratelimit_enable_ratelimiter']`|`MM_RATELIMITSETTINGS_ENABLE`|
|`mattermost['support_email']`|`MM_SUPPORTSETTINGS_SUPPORTEMAIL`|
|`mattermost['localization_server_locale']`|`MM_LOCALIZATIONSETTINGS_DEFAULTSERVERLOCALE`|
|`mattermost['localization_client_locale']`|`MM_LOCALIZATIONSETTINGS_DEFAULTCLIENTLOCALE`|
|`mattermost['webrtc_gateway_stun_uri']`|`MM_WEBRTCSETTINGS_STUN_URI`|
|`mattermost['webrtc_gateway_turn_uri']`|`MM_WEBRTCSETTINGS_TURN_URI`|
|`mattermost['webrtc_gateway_turn_username']`|`MM_WEBRTCSETTINGS_TURN_USERNAME`|
|`mattermost['webrtc_gateway_turn_sharedkey']`|`MM_WEBRTCSETTINGS_TURN_SHAREDKEY`|


> Please note:
GitLab 11.0 will no longer generate `config.json` file from the configuration specified
in `gitlab.rb`. Users are responsible for managing this file which can be done via
Mattermost System System Console or manually.
If a configuration setting is specified via both `gitlab.rb` (as env variable)
and via `config.json` file, environment variable gets precedence.


## Upgrading GitLab Mattermost from versions prior to 8.9

After upgrading to GitLab 8.9 additional steps are require before restarting the Mattermost server to enable multi-account support in Mattermost 3.1.

1. Confirm you are starting with version GitLab 8.8.
1. Backup your Mattermost database.
     - This is especially important in the 8.9 upgrade since the database upgrade cannot be reversed and is incompatible with previous versions.
     - If you use a default omnibus install you can use [this command](#backup-the-bundled-postgresql-database)
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

If you are using GitLab 11.0 or newer, you can enable incoming webhooks from the **Integrations > Custom Integrations** section of
the Mattermost **System Console**.

If you are using an older version of GitLab Omnibus, enable incoming webhooks from the `gitlab.rb` file.

```ruby
mattermost['service_enable_incoming_webhooks'] = true
```

#### Setting up Mattermost as a service integration:

You can use the Mattermost notifications project integration option to set up Mattermost integration:

1. In Mattermost, go to **System Console** > **Integration Settings** > **Custom Integrations** and turn on **Enable Incoming Webhooks**
1. Exit the system console, and then go to **Integrations** > **Incoming Webhooks** from the main menu
2. Select a channel and click **Add** and copy the `Webhook URL`
3. In GitLab, paste the `Webhook URL` into **Webhook** under your project’s **Settings** > **Integrations** > **Mattermost notifications**
4. Enter **Username** for how you would like to name the account that posts the notifications
4. Select **Triggers** for GitLab events on which you'd like to receive notifications
6. Click **Test settings and save changes** to make sure everything is working

Any issues, please see the [Mattermost Troubleshooting Forum](https://forum.mattermost.org/t/how-to-use-the-troubleshooting-forum/150).

#### Setting up GitLab integration service for Mattermost

You can also set up the [open source integration service](https://github.com/NotSqrt/mattermost-integration-gitlab) to let you configure notifications on GitLab issues, pushes, build events, merge requests and comments to be delivered to selected Mattermost channels.

This integration lets you completely control how notifications are formatted and, unlike Slack, offers full markdown support.

The source code can be modified to support not only GitLab, but any in-house applications you may have that support webhooks. Also see:
- [Mattermost incoming webhook documentation](http://docs.mattermost.com/developer/webhooks-incoming.html)
- [GitLab webhook documentation](https://docs.gitlab.com/ce/web_hooks/web_hooks.html)

![webhooks](https://gitlab.com/gitlab-org/omnibus-gitlab/uploads/677b0aa055693c4dcabad0ee580c61b8/730_gitlab_feature_request.png)

### Specify numeric user and group identifiers

omnibus-gitlab creates a user and group mattermost. You can specify the
numeric identifiers for these users in `/etc/gitlab/gitlab.rb` as follows.

```ruby
mattermost['uid'] = 1234
mattermost['gid'] = 1234
```

Run `sudo gitlab-ctl reconfigure` for the changes to take effect.

### Setting custom environment variables

If necessary you can set custom environment variables to be used by Mattermost
via `/etc/gitlab/gitlab.rb`.  This can be useful if the Mattermost server
is operated behind a corporate internet proxy.  In `/etc/gitlab/gitlab.rb`
supply a `mattermost['env']` with a hash value. For example:

```ruby
mattermost['env'] = {"http_proxy" => "my_proxy", "https_proxy" => "my_proxy", "no_proxy" => "my_no_proxy"}
```

Run `sudo gitlab-ctl reconfigure` for the changes to take effect.

### Connecting to the bundled PostgreSQL database

If you need to connect to the bundled PostgreSQL database and are using the default Omnibus GitLab database configuration, you can connect as the Postgres superuser:

```
sudo gitlab-psql -d mattermost_production
```

### Backup the bundled PostgreSQL database

If you need to backup the bundled PostgreSQL database and are using the default Omnibus GitLab database configuration, you can backup using this command:

```
sudo -i -u gitlab-psql -- /opt/gitlab/embedded/bin/pg_dump -h /var/opt/gitlab/postgresql mattermost_production | gzip > mattermost_dbdump_$(date --rfc-3339=date).sql.gz
```

### Mattermost Command Line Tools (CLI)

Should you need to use the [Mattermost Command Line Tools (CLI)](https://docs.mattermost.com/administration/command-line-tools.html),
you must be in the following directory when you run CLI commands: `/opt/gitlab/embedded/service/mattermost`.
Also, you must run the commands as the user `mattermost` and specify the location of the configuration file. The executable is `/opt/gitlab/embedded/bin/mattermost`.

```
cd /opt/gitlab/embedded/service/mattermost
sudo -u mattermost /opt/gitlab/embedded/bin/mattermost --config=/var/opt/gitlab/mattermost/config.json version
```

For more details see [Mattermost Command Line Tools (CLI)](https://docs.mattermost.com/administration/command-line-tools.html).


### OAuth2 Sequence Diagram

The following image is a sequence diagram for how GitLab works as an OAuth2
provider for Mattermost. It may be useful to use this to troubleshoot errors
in getting the integration to work:

![sequence diagram](img/gitlab-mattermost.png)
