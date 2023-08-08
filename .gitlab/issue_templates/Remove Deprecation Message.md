<!--
Read me first!

Before you create a new issue, please make sure to search in https://gitlab.com/gitlab-org/omnibus-gitlab/issues,
to verify that the issue you are about to submit isn't a duplicate.
-->

## Remove deprecation messages

<!--
List here the deprecation messages you want to remove.
-->

### Preparation when creating the Issue

- [ ] List all the [Remove deprecation messages](#remove-deprecation-messages) section all the deprecations you want to remove.
- [ ] Set the milestone of this issue to [next planned required stop](https://docs.gitlab.com/ee/update/index.html#upgrade-paths), which should be after
  the milestone when the configuration will be removed.

### Preparation when executing the Issue

- [ ] Verify that the related configuration got indeed removed in a previous milestone.
- [ ] Make sure the MR removing the deprecation message is released on a [required stop](https://docs.gitlab.com/ee/update/index.html#upgrade-paths)
  which is later than the removal of the configuration.
