---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Contribute to Omnibus GitLab

## Common enhancement tasks

- [Adding and removing configuration options](add-remove-configuration-options.md)
- [Adding a new Service to Omnibus GitLab](new-services.md)
- [Adding deprecation messages](adding-deprecation-messages.md)
- [Adding an attribute to `public_attributes.json`](public-attributes.md)
- [Adding a `gitlab-ctl` command](gitlab-ctl-commands.md)

## Common maintenance tasks

- [Patching upstream software](creating-patches.md)
- [Managing PostgreSQL versions](managing-postgresql-versions.md)
- [Upgrading the bundled Chef version](upgrading-chef.md)
- [Deprecating and removing support for an OS](deprecating-and-removing-support-for-an-os.md)
- [Adding or changing behavior during package install and upgrade](change-package-behavior.md)

## Build and test your enhancement

- [Building your own package](../build/index.md)
- [Building a package from a custom branch](../build/team_member_docs.md#test-an-omnibus-gitlab-project-mr)

## Submit your enhancement for review

### Merge request guidelines

If you are working on a new feature or an issue which doesn't have an entry on
the Omnibus GitLab issue tracker, it is always a better idea to create an issue
and mention that you will be working on it as this will help to prevent
duplication of work. Also, others may be able to provide input regarding the
issue, which can help you in your task.

It is preferred to make your changes in a branch named `\<issue number>-\<description>`
so that merging the request will automatically close the
specified issue.

A good merge request is expected to have the following components, based on
their applicability:

1. Full merge request description explaining why this change was needed
1. Code for implementing feature/bugfix
1. Tests, as explained in [Writing Tests](#write-tests)
1. Documentation explaining the change
1. If merge request introduces change in user facing configuration, update to [`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)
1. [Changelog entry](https://docs.gitlab.com/ee/development/changelog.html) to inform about the change, if necessary.

NOTE:
Ensure shared runners are enabled for your fork in order for our automated tests to run:

1. Go to **Settings -> CI/CD**.
1. Expand Runners settings.
1. If shared runners are not enabled, click on the button labeled **Enable shared Runners**.

### Write tests

Any change in the internal cookbook also requires specs. Apart from testing the
specific feature/bug, it would be greatly appreciated if the submitted Merge
Request includes more tests. This is to ensure that the test coverage grows with
development.

When in rush to fix something (such as a security issue, or a bug blocking the release),
writing specs can be skipped. However, an issue to implement the tests
**must be** created and assigned to the person who originally wrote the code.

To run tests, execute the following command. You may have to run `bundle install` before running it:

```shell
bundle exec rspec
```
