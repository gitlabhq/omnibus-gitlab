---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Changing `gitlab.yml` and application.yml settings **(FREE SELF)**

Some GitLab features can be customized through
[`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/config/gitlab.yml.example). If you want to change a `gitlab.yml` setting
with Omnibus GitLab, you need to do so via `/etc/gitlab/gitlab.rb`. The
translation works as follows. For a complete list of available options, visit the
[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).
New installations starting from GitLab 7.6, will have
all the options of the template listed in `/etc/gitlab/gitlab.rb` by default.

In `gitlab.yml`, you will find structure like this:

```yaml
production: &base
  gitlab:
    default_theme: 2
```

In `gitlab.rb`, this translates to:

```ruby
gitlab_rails['gitlab_default_theme'] = 2
```

What happens here is that we forget about `production: &base`, and join
`gitlab:` with `default_theme:` into `gitlab_default_theme`.
Note that not all `gitlab.yml` settings can be changed via `gitlab.rb` yet; see
the [`gitlab.yml.erb` template](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/templates/default/gitlab.yml.erb).
If you think an attribute is missing please create a merge request on the Omnibus GitLab repository.

Run `sudo gitlab-ctl reconfigure` for changes in `gitlab.rb` to take effect.

Do not edit the generated file in `/var/opt/gitlab/gitlab-rails/etc/gitlab.yml`
since it will be overwritten on the next `gitlab-ctl reconfigure` run.

## Adding a new setting to `gitlab.yml`

Don't forget to update the following 5 files when adding a new setting:

- the [`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)
  file to expose the setting to the end user via `/etc/gitlab/gitlab.rb`.
- the [`default.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/attributes/default.rb)
  file to provide a sane default for the new setting.
- the [`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/blob/master/config/gitlab.yml.example)
  file to actually use the setting's value from `gitlab.rb`.
- the [`gitlab.yml.erb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/templates/default/gitlab.yml.erb)
  file
- the [`gitlab-rails_spec.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/spec/chef/recipes/gitlab-rails_spec.rb)
  file
