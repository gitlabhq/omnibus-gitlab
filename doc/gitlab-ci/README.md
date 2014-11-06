# GitLab CI

You can run a [GitLab CI](https://about.gitlab.com/gitlab-ci/) Coordinator
service on your GitLab server.

## Getting started

GitLab CI expects to run on its own virtual host. In your DNS you would then
have two entries pointing to the same machine, e.g. `gitlab.example.com` and
`ci.example.com`.

To enable GitLab CI, just tell omnibus-gitlab what the external URL for the CI
server is:

```
# in /etc/gitlab/gitlab.rb
ci_external_url 'http://ci.example.com'
```

After you run `sudo gitlab-ctl reconfigure`, your GitLab CI Coordinator should
now be reachable at `http://ci.example.com`.

## Running GitLab CI on its own server

If you want to run GitLab and GitLab CI Coordinator on two separate servers you
can use the following settings on the GitLab CI server to effectively disable
the GitLab service bundled into the Omnibus package.

```
ci_external_url 'http://ci.example.com'

# Tell GitLab CI to integrate with gitlab.example.com
gitlab_ci['gitlab_server_urls'] = ['http://gitlab.example.com']

# Shut down GitLab services on the CI server
unicorn['enable'] = false
sidekiq['enable'] = false
```
