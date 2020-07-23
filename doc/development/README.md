---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Omnibus GitLab developer documentation

- [Development Setup](setup.md)
- [Omnibus GitLab Architecture](../architecture/README.md)
- [Adding a new Service to Omnibus GitLab](new-services.md)
- [Creating patches](creating-patches.md)
- [Repositories, branches and CI pipelines](pipelines.md)
- [Release process](../release/README.md)
- [Building your own package](../build/README.md)
- [Building a package from a custom branch](../build/README.md#building-a-package-from-a-custom-branch)
- [Adding deprecation messages](adding-deprecation-messages.md)
- [Adding an attribute to `public_attributes.json`](public-attributes.md)
- [Adding a `gitlab-ctl` command](gitlab-ctl-commands.md)
- [Managing PostgreSQL versions](managing-postgresql-versions.md)
- [Upgrading the bundled Chef version](upgrading-chef.md)

## Setting up development environment

Check [setting up development environment docs](setup.md) for
instructions on setting up a environment for local development.

## Understanding the architecture

Check the [architecture documentation](../architecture/README.md) for an full description
of the various components of this project, and how they work together.

## Writing tests

Any change in the internal cookbook also requires specs. Apart from testing the
specific feature/bug, it would be greatly appreciated if the submitted Merge
Request includes more tests. This is to ensure that the test coverage grows with
development.

When in rush to fix something (eg. security issue, bug blocking the release),
writing specs can be skipped. However, an issue to implement the tests
**must be** created and assigned to the person who originally wrote the code.

To run tests, execute the following command (you may have to run `bundle install` before running it)

```shell
bundle exec rspec
```

## Merge Request Guidelines

If you are working on a new feature or an issue which doesn't have an entry on
Omnibus GitLab's issue tracker, it is always a better idea to create an issue
and mention that you will be working on it as this will help to prevent
duplication of work. Also, others may be able to provide input regarding the
issue, which can help you in your task.

It is preferred to make your changes in a branch named \<issue
number>-\<description> so that merging the request will automatically close the
specified issue.

A good Merge Request is expected to have the following components, based on
their applicability:

1. Full Merge Request description explaining why this change was needed
1. Code for implementing feature/bugfix
1. Tests, as explained in [Writing Tests](#writing-tests)
1. Documentation explaining the change
1. If Merge Request introduces change in user facing configuration, update to [`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)
1. [Changelog entry](https://docs.gitlab.com/ee/development/changelog.html) to inform about the change, if necessary.

**Note:** Ensure shared runners are enabled for your fork in order for our automated tests to run:

1. Go to Settings -> CI/CD
1. Expand Runners settings
1. If shared runners are not enabled, click on the button labeled "Enable shared Runners"

## Validating changes to a single software dependency

It can be useful to only build one piece of software, rather than rebuild the whole package each time. For instance,
when adding a new software definition. Using this method, you can quickly rebuild an omnibus package containing only
the software and its dependencies. Once you've confirmed the software builds on its own, you can add it to the Omnibus GitLab
build and confirm it there. To use this:

1. [Setup your development environment](setup.md)
1. Copy the [simple.rb](examples/simple.rb) file into your projects

   ```shell
   cp doc/development/examples/simple.rb config/projects/
   ```

1. Change the `dependency` in `config/projects/simple.rb` to match the software you are testing
1. Build the simple project by running

   ```shell
   bundle exec omnibus build simple
   ```

## Testing changes during install/upgrade

If you are working on changes to the install/upgrade process, and not the reconfigure process itself, you can use the [scripts/repack-deb](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/scripts/repack-deb) tool to quickly repack an existing GitLab deb with changes from your local branch. It will repack the existing deb file into a new deb containing the local content from

- `config/templates/package-scripts`
- `files/gitlab-cookbook/`
- `files/gitlab-ctl-commands`
- `files/gitlab-ctl-commands-ee`
