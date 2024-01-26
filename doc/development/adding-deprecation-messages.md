---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Omnibus GitLab deprecation process

Besides following the [GitLab deprecation guidelines](https://handbook.gitlab.com/handbook/product/gitlab-the-product/#deprecations-removals-and-breaking-changes), we should also add deprecation messages
to the Omnibus GitLab package.

Notifying GitLab administrators of the deprecation and removal of features through deprecation messages consists of:

1. [Addding deprecation messages](#adding-deprecation-messages).
1. [Tracking the removal of deprecation messages](#tracking-the-removal-of-deprecation-messages).
1. [Tracking the removal of the feature](#track-the-removal-of-the-feature).
1. [Removing deprecation messages](#removing-deprecation-messages).

## You must know

Before you add a deprecation message, make sure to read:

- [When can a feature be deprecated](https://docs.gitlab.com/ee/development/deprecation_guidelines/#when-can-a-feature-be-deprecated).
- [Omnibus GitLab deprecation policy](https://docs.gitlab.com/ee/administration/package_information/deprecation_policy.html).

## Adding deprecation messages

We store a list of deprecations associated with it in the `list` method of
[`Gitlab::Deprecations` class](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/package/libraries/deprecations.rb)
If a configuration has to be deprecated, it has to be added to that list with
proper details. For example:

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

`config_keys` represents a list of keys, which can be used to traverse the configuration hash available
from `/opt/gitlab/embedded/nodes/{fqdn}.json` to reach a specific configuration.
For example `%w(mattermost log_file_directory)` means `mattermost['log_file_directory']` setting.
Similarly, `%w(gitlab nginx listen_addresses)` means `gitlab['nginx']['listen_addresses']`.
We internally convert it to `nginx['listen_addresses']`, which is what we use in `/etc/gitlab/gitlab.rb`.

### `deprecation`

`deprecation` is where you set the `<major>.<minor>` version that deprecated the change.
Starting in that version, running `gitlab-ctl reconfigure` will warn that the setting is being removed in the `removal`
version, and it will display the provided `note`.

### `removal`

`removal` is where you set the `<major>.<minor>` version that will no longer support the change at all.
This should almost always be a major release. The Omnibus package runs a script at the beginning of installation that ensures you don't have any removed configuration in your settings. The install will fail early, before making any changes, if it finds configuration that is no longer supported. Similarly, running `gitlab-ctl reconfigure` will also check the `gitlab.rb` file for removed configs. This is to tackle situations where users simply copy `gitlab.rb` from an older instance to a newer one.

### `note`

`note` is part of the deprecation message provided to users during `gitlab-ctl reconfigure`.
Use this area to inform users of how to change their settings, often by linking to new documentation,
or in the case of a settings rename, telling them what the new setting name should be.

## Tracking the removal of deprecation messages

Deprecation messages **should not** be cleaned up together with removals, because even after the removal they protect upgrades
where an administrator tries to upgrade to the version where the key got removed, but they have not yet migrated all
the old configuration.

Upgrades do this by running the `Gitlab::Deprecations.check_config` method, which compares existing
configuration against their scheduled removal date, before allowing the GitLab package to be updated.

Additionaly, we have users who might skip multiple GitLab versions when upgrading. For that reason, we recommend deprecation
messages to only be removed in the next planned required stop following the removal milestone, as per our
[upgrade paths](https://docs.gitlab.com/ee/update/index.html#upgrade-paths). For example:

- A deprecation message was added in 15.8.
- The old configuration was removed from the codebase in 16.0.
- The deprecation messages should be removed in 16.3, as this is the next planned required stop.

To track the removal of deprecation messages:

1. Create a follow-up issue using the `Remove Deprecation Message` issue template.
1. Add a comment next to your deprecation message with a link to the follow-up issue to remove the message. For example:

   ```ruby
   {
     config_keys: ...
     deprecation: '15.8', # Remove message Issue: https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/XYZ
     removal: '16.0', 
     note: "..."
   },
   ```

## Track the removal of the feature

Define the correct milestone to remove the feature you want to deprecate, based on the [you must know](#you-must-know)
section above. Then create a follow-up issue to track the removal of the feature, and add a comment
beside the `removal` key informing which issue is tracking its removal. For example:

```ruby
{
  config_keys: ...
  deprecation: '15.8', # Remove message Issue: https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/1
  removal: '16.0', # Removal issue: https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2
  note: "..."
},
```

The follow-up issue should be set to the milestone in which the feature is expected to be removed.

## Removing deprecation messages

When the messages are ready to be removed you should:

1. Make sure the deprecated configuration was indeed removed in a previous milestone.
1. Make sure the message removal is being released in a required stop milestone later than the one that removed the configuration.
1. Open an MR to remove the deprecation messages and to close the follow-up issue.
