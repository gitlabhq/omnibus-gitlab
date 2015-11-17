# GitLab Mattermost

You can run a [GitLab Mattermost](http://www.mattermost.org/)
service on your GitLab server.

## Documentation version

Make sure you view this guide from the tag (version) of GitLab you would like to install. In most cases this should be the highest numbered production tag (without rc in it). You can select the tag in the version dropdown in the top left corner of GitLab (below the menu bar).

If the highest number stable branch is unclear please check the [GitLab Blog](https://about.gitlab.com/blog/) for installation guide links by version.

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

mattermost['oauth'] = {'gitlab' => {'Allow' => true, 'Secret' => "123", 'Id' => "123", "AuthEndpoint" => "http://gitlab.example.com/oauth/authorize", "TokenEndpoint" => "http://gitlab.example.com/oauth/token", "UserApiEndpoint" => "http://gitlab.example.com/api/v3/user" }}

# Shut down GitLab services on the Mattermost server
gitlab_rails['enable'] = false
```

where `Secret` and `Id` are `application secret` and `application id` received when creating new `Application` authorization in GitLab admin section.

Optionally, you can set `mattermost['email_enable_sign_up_with_email'] = false` to force all users to sign-up with GitLab only. See Mattermost [documentation on GitLab SSO](https://github.com/mattermost/platform/blob/master/doc/integrations/Single-Sign-On/Gitlab.md).

## Manually (re)authorising GitLab Mattermost with GitLab

### Authorise GitLab Mattermost

To do this, using browser navigate to the `admin area` of GitLab, `Application` section. Create a new application and for the callback URL use: `http://mattermost.example.com/signup/gitlab/complete` and `http://mattermost.example.com/login/gitlab/complete` (replace http with https if you use https).

Once the application is created you will receive an `Application ID` and `Secret`. One other information needed is the URL of GitLab instance.

Now, go to the GitLab server and edit the `/etc/gitlab/gitlab.rb` configuration file.

In `gitlab.rb` use the values you've received above:

```
mattermost['oauth'] = {'gitlab' => {'Allow' => true, 'Secret' => "123", 'Id' => "123", "AuthEndpoint" => "http://gitlab.example.com/oauth/authorize", "TokenEndpoint" => "http://gitlab.example.com/oauth/token", "UserApiEndpoint" => "http://gitlab.example.com/api/v3/user" }}
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

SMTP configuration depends on SMTP provider used. If you are using SMTP without TLS minimal configuration in `/etc/gitlab/gitlab.rb` contains:

```ruby
mattermost['email_enable_sign_up_with_email'] = true
mattermost['email_smtp_username'] = "username"
mattermost['email_smtp_password'] = "password"
mattermost['email_smtp_server'] = "smtp.example.com:465"
mattermost['email_connection_security'] = nil
mattermost['email_feedback_name'] = "GitLab Mattermost"
mattermost['email_feedback_email'] = "email@example.com"
```

If you are using TLS, configuration can look something like this:

```ruby
mattermost['email_enable_sign_up_with_email'] = true
mattermost['email_smtp_username'] = "username"
mattermost['email_smtp_password'] = "password"
mattermost['email_smtp_server'] = "smtp.example.com:587"
mattermost['email_connection_security'] = 'TLS' # Or 'STARTTLS'
mattermost['email_feedback_name'] = "GitLab Mattermost"
mattermost['email_feedback_email'] = "email@example.com"
```

`email_connection_security` depends on your SMTP provider so you need to verify which of `TLS` or `STARTTLS` is valid for your provider.

Once the configuration is set, run `sudo gitlab-ctl reconfigure` for the changes to take effect.

## GitLab Mattermost configuration

For a complete list of available options, visit the [gitlab.rb.template](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).

Also see:

### GitLab Mattermost Administrator's Guide

The [GitLab Mattermost Administrator's Guide](https://github.com/mattermost/platform/blob/master/doc/install/Administration.md#gitlab-mattermost-administration) is maintained by the Mattermost community for GitLab users.

#### GitLab Mattermost Trouble Shooting

The [GitLab Mattermost Trouble Shooting](https://github.com/mattermost/platform/blob/master/doc/install/Administration.md#troubleshooting-gitlab-mattermost) section includes common error messages that may be encountered under different configurations as well as common solutions.

#### Configuring Mattermost Incoming Webhooks

See [the section on configuring incoming webhooks in Mattermost](https://github.com/mattermost/platform/blob/master/doc/install/Administration.md#connecting-mattermost-to-integrations-with-incoming-webhooks) to support Slack-equivalent notifications from GitLab, as well as for fully customizable alerting through the **GitLab Integration Service for Mattermost**.

#### Configuring Mattermost Outgoing Webhooks

See [the section on configuring outoing webhooks in Mattermost](https://github.com/mattermost/platform/blob/master/doc/install/Administration.md#connecting-mattermost-to-integrations-with-outgoing-webhooks) for connecting to Mattermost applications created by the Mattermost community for interactivity with systems like **Hubot** and **IRC**.


We welcome contributions to improve the configuration settings explanations both in the gitlab.rb.template and in the documentation.
