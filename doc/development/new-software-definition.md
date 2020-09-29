---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Adding a new Software Definition to Omnibus GitLab

In order to add a new component to GitLab, you should follow these steps:

1. [Fetch and compile the software during build](#fetch-and-compile-the-software-during-build)
1. [Add a dependency for the software definition to another component](#add-a-dependency-for-the-software-definition-to-another-component)

## Fetch and compile the software during build

[Software Definitions](../architecture/README.md#software-definitions), which
can be found in `/config/software`, specify where omnibus should fetch the
software, how to compile it and install it to the required folder. This part of
the project is run when we build the Omnibus package for GitLab.

When adding a component that should be fetched from Git the clone address of the
repositories of the local mirror and upstream should be added to
`/.custom_sources.yml`.

The local mirror should be created in the [omnibus-mirror project](omnibus-mirror.md) by a member of the Distribution team.

See other Software services in the directory for examples on how to include your
software service.

## Handling Licenses

Most software repositories include a license file. Add the license using a patch
file if it is not explicitly included. Software installed using a package manager
such as `gem` or `pip` should also use this method.

[Create patches](creating-patches.md) for licenses added manually and store them
at a directory path with the naming convention
`config/patches/SOFTWARE_NAME/license/VERSION_NUMBER/add-license-file.patch`.

> Licenses can and do change over the lifetime of a project. This method
> intentionally causes builds to fail reminding contributors to verify manually
> installed licenses. If the license has not changed then `git mv` the `VERSION_NUMBER`
> directory containing the patch file to the new `VERSION_NUMBER`.

## Add a dependency for the software definition to another component

Add a `dependency` statement to the definition of the GitLab project found in
`/config/projects/gitlab.rb`, unless there is a more specific component it makes
sense to be a dependency of (eg `config/software/gitlab-rails.rb` for a
component only needed by `gitlab-rails`)
