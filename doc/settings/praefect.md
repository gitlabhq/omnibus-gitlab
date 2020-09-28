---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Praefect

Praefect is a manager aiming to maintain replicas for each repository. Praefect
is in active development. The goal is to achieve a highly available storage cluster,
but this is not the case yet, so it is recommended to run Praefect on a different node
than the Gitaly nodes.

```ruby
praefect['enable'] = true
```

## Praefect settings

Praefect must be [enabled in GitLab](https://docs.gitlab.com/ee/administration/gitaly/praefect.html#enable-the-daemon)
before it can be used.

### Praefect storage nodes

Praefect needs one or more Gitaly servers to store the Git data on. These
Gitaly servers are considered Praefect `storage_nodes`
(`praefect['storage_nodes']`). These storage nodes should be private to
Praefect, meaning they should not be listed in `git_data_dirs` in your
`gitlab.rb`.
