---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab 14 specific changes

NOTE:
When upgrading to a new major version, remember to first [check for background migrations](https://docs.gitlab.com/ee/update/index.html#checking-for-background-migrations-before-upgrading).

## 14.0

### Removing support for running Sidekiq directly instead of `sidekiq-cluster`

In GitLab 13.0, `sidekiq-cluster` was enabled by default and the `sidekiq`
service ran `sidekiq-cluster` under the hood. However, users could control this
behavior using `sidekiq['cluster']` setting to run Sidekiq directly instead.
Users could also run `sidekiq-cluster` separately using the various
`sidekiq_cluster[*]` settings available in `gitlab.rb`. However these features
were deprecated and are now being removed.

Starting with GitLab 14.0, `sidekiq-cluster` becomes the only way to run Sidekiq
in `omnibus-gitlab` installations. As part of this process, support for the
following settings in `gitlab.rb` is being removed:

1. `sidekiq['cluster']` setting. Sidekiq can only be run using `sidekiq-cluster`
   now.

1. `sidekiq_cluster[*]` settings. They should be set via respective `sidekiq[*]`
   counterparts.

1. `sidekiq['concurrency']` setting. The limits should be controlled using the
   two settings `sidekiq['min_concurrency']` and `sidekiq['max_concurrency']`.
