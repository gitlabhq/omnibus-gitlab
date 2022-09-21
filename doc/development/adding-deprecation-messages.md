---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Adding deprecation messages

We store a list of deprecations associated with it in the `list` method of
[`Gitlab::Deprecations` class](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/package/libraries/deprecations.rb)
If a configuration has to be deprecated, it has to be added to that list with
proper details.

## Example

```ruby
deprecations = [
          {
            config_keys: %w(gitlab postgresql data_dir),
            deprecation: '11.6',
            removal: '14.0',
            note: "Please see https://docs.gitlab.com/omnibus/settings/database.html#store-postgresql-data-in-a-different-directory for how to use postgresql['dir']"
          },
          {
            config_keys: %w(gitlab sidekiq cluster),
            deprecation: '13.0',
            removal: '14.0',
            note: "Running sidekiq directly is deprecated. Please see https://docs.gitlab.com/ee/administration/operations/extra_sidekiq_processes.html for how to use sidekiq-cluster."
          },
...
]
```

### `config_keys`

`config_keys` represents a list of keys, which can be used to traverse the configuration hash available from `/opt/gitlab/embedded/nodes/{fqdn}.json` to reach a specific configuration. For example `%w(mattermost log_file_directory)` means `mattermost['log_file_directory']` setting. Similarly, `%w(gitlab nginx listen_addresses)` means `gitlab['nginx']['listen_addresses']`. We internally convert it to `nginx['listen_addresses']`, which is what we use in `/etc/gitlab/gitlab.rb`.

### `deprecation`

`deprecation` is where you set the `<major>.<minor>` version that deprecated the change. Starting in that version, running `gitlab-ctl reconfigure` will warn that the setting is being removed in the `removal` version, and it will display the provided `note`.

### `removal`

`removal` is where you set the `<major>.<minor>` version that will no longer support the change at all. This should almost always be a major release. The Omnibus package runs a script at the beginning of installation that ensures you don't have any removed configuration in your settings. The install will fail early, before making any changes, if it finds configuration that is no longer supported.

### `note`

`note` is part of the deprecation message provided to users during `gitlab-ctl reconfigure`. Use this area to inform users of how to change their settings, often by linking to new documentation, or in the case of a settings rename, telling them what the new setting name should be.

Once the version where the setting is removed is out of the [maintenance window](https://docs.gitlab.com/ee/policy/maintenance.html#gitlab-release-and-maintenance-policy), the deprecation message can be removed from the codebase.
