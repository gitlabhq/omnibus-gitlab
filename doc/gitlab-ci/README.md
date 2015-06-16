# GitLab CI

You can run a [GitLab CI](https://about.gitlab.com/gitlab-ci/) Coordinator
service on your GitLab server.

## Documentation version

Please make sure you are viewing the documentation for the version of
omnibus-gitlab you are using. In most cases this should be the highest numbered
stable branch (example shown below).

![documentation version](doc/images/omnibus-documentation-version.png)

## Getting started

GitLab CI expects to run on its own virtual host. In your DNS you would then
have two entries pointing to the same machine, e.g. `gitlab.example.com` and
`ci.example.com`.

GitLab CI is disabled by default, to enable it just tell omnibus-gitlab what
the external URL for the CI server is:

```ruby
# in /etc/gitlab/gitlab.rb
ci_external_url 'http://ci.example.com'
```

After you run `sudo gitlab-ctl reconfigure`, your GitLab CI Coordinator should
now be reachable at `http://ci.example.com` and authorized to connect to GitLab.

Omnibus-gitlab package will attempt to automatically authorise GitLab CI with GitLab if applications are running on the same server. This is because automatic authorisation requires access to GitLab database. If GitLab database is not available you will need to manually authorise GitLab CI for access to GitLab.

## Running GitLab CI on its own server

If you want to run GitLab and GitLab CI Coordinator on two separate servers you
can use the following settings on the GitLab CI server to effectively disable
the GitLab service bundled into the Omnibus package. The GitLab services will
still be set up on your CI server, but they will not accept user requests or
consume system resources.

```ruby
ci_external_url 'http://ci.example.com'

# Tell GitLab CI to integrate with gitlab.example.com

gitlab_ci['gitlab_server'] = { 'url' => 'http://gitlab.example.com', 'app_id' => "1234", 'app_secret' => 'qwertyuio'}

# Shut down GitLab services on the CI server
gitlab_rails['enable'] = false
unicorn['enable'] = false
sidekiq['enable'] = false
```

## Manually (re)authorising GitLab CI with GitLab

### Authorise GitLab CI

To do this, using browser navigate to the `admin area` of GitLab, `Application` section. Create a new application and for the callback URL use: `http://ci.example.com/user_sessions/callback` (replace http with https if you use https).

Once the application is created you will receive an `Application ID` and `Secret`. One other information needed is the URL of GitLab instance.

Now, go to the GitLab server and edit the `/etc/gitlab/gitlab.rb` configuration file.

In `gitlab.rb` use the values you've received above:

```
gitlab_ci['gitlab_server'] = { "url" => 'http://gitlab.example.com', "app_id" => '12345678', "app_secret" => 'QWERTY12345' }
```
Save the changes and then run `sudo gitlab-ctl reconfigure`.

If there are no errors your GitLab and GitLab CI should be configured correctly.

### Reauthorise GitLab CI

To reauthorise GitLab CI you will first need to revoke access of the existing authorisation. This can be done in the Admin area of GitLab under `Applications`. Once that is done follow the steps in the `Authorise GitLab CI` section.
