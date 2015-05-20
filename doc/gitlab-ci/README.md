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

```
# in /etc/gitlab/gitlab.rb
ci_external_url 'http://ci.example.com'
```

After you run `sudo gitlab-ctl reconfigure`, your GitLab CI Coordinator should
now be reachable at `http://ci.example.com`.

Follow the on screen instructions on how to generate the app id and secret.
Once generated, edit `/etc/gitlab/gitlab.rb` to set the URL for your GitLab server, your generated app id and generated secret:

```
gitlab_ci['gitlab_server'] = { 'url' => 'http://gitlab.example.com', 'app_id' => "1234", 'app_secret' => 'qwertyuio'}
```

then run `sudo gitlab-ctl reconfigure` again.

## Running GitLab CI on its own server

If you want to run GitLab and GitLab CI Coordinator on two separate servers you
can use the following settings on the GitLab CI server to effectively disable
the GitLab service bundled into the Omnibus package. The GitLab services will
still be set up on your CI server, but they will not accept user requests or
consume system resources.

```
ci_external_url 'http://ci.example.com'

# Tell GitLab CI to integrate with gitlab.example.com
gitlab_ci['gitlab_server'] = { 'url' => 'http://gitlab.example.com', 'app_id' => "1234", 'app_secret' => 'qwertyuio'}

# Shut down GitLab services on the CI server
gitlab_rails['enable'] = false
unicorn['enable'] = false
sidekiq['enable'] = false
```
