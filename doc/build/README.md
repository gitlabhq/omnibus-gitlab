# Preparing a build environment

See [Preparing a Build Environment page](doc/build/prepare-build-environment.md)
for instructions on how to prepare build environment using Docker.

## Usage

### Build

You create a platform-specific package using the `build` command:

```shell
$ bin/omnibus build gitlab
```

The platform/architecture type of the package created will match the platform
where the `build project` command is invoked. So running this command on say a
MacBook Pro will generate a Mac OS X specific package. After the build
completes packages will be available in `pkg/`.

### Clean

You can clean up all temporary files generated during the build process with
the `clean` command:

```shell
$ bin/omnibus clean
```

Adding the `--purge` purge option removes __ALL__ files generated during the
build including the project install directory (`/opt/gitlab`) and
the package cache directory (`/var/cache/omnibus/pkg`):

```shell
$ bin/omnibus clean --purge
```

### Help

Full help for the Omnibus command line interface can be accessed with the
`help` command:

```shell
$ bin/omnibus help
```

## Build Docker image

```shell
# Build with stable packagecloud packages
# This will build gitlab-ee (8.0.2-ee.1) using STABLE repo and tag it as gitlab-ee:latest
make docker_build RELEASE_VERSION=8.0.2-ee.1 PACKAGECLOUD_REPO=gitlab-ee RELEASE_PACKAGE=gitlab-ee

# Build with unstable packagecloud packages
# This will build gitlab-ce (8.0.2-ce.1) using UNSTABLE repo and tag it as gitlab-ce:latest
make docker_build RELEASE_VERSION=8.0.2-ce.1 PACKAGECLOUD_REPO=unstable RELEASE_PACKAGE=gitlab-ce
```

### Publish Docker image

```shell
# This will push gitlab-ee:latest as gitlab/gitlab-ee:8.0.2-ee.1
make docker_push RELEASE_PACKAGE=gitlab-ee RELEASE_VERSION=8.0.2-ee.1

# This will push gitlab-ce:latest as gitlab/gitlab-ce:8.0.2-ce.1
make docker_push RELEASE_PACKAGE=gitlab-ce RELEASE_VERSION=8.0.2-ce.1

# This will push gitlab-ce:latest as gitlab/gitlab-ce:latest
make docker_push_latest RELEASE_PACKAGE=gitlab-ce
```

## Building a package from a custom branch

>**Note** For a description on how the official omnibus-gitlab package is built,
see the [release process](doc/release/README.md) document.

If you are working on implementing a feature in one of the GitLab components,
you might need to build a package from your custom branch in order to test the
feature using the omnibus-gitlab package.

For example, you've implemented something inside of GitLab Rails application and
the code is located in the branch named `my-feature`.

To use the custom branch for building an omnibus-gitlab package, you will need
to prepend the branch name with `buildfrombranch:` and place it in the
related `VERSION` file.

For our previous example, to build a package that will use `my-feature` branch
for GitLab Rails project, the `VERSION` file inside of the omnibus-gitlab
repository should contain `buildfrombranch:my-feature`.

Similarly, you can do the same for `GITLAB_WORKHORSE_VERSION` and so on.

### Note for GitLab Inc. developers

If you are a member of the GitLab Inc. team, you will have access to the build
infrastructure (or to the colleagues that have access to the infrastructure).

You can easily build custom packages leveraging the build infrastructure to test
your code.

Before you start,
**you need push access to the omnibus-gitlab repository.**

If you have (someone with) access, you need to:

1. Make sure that your custom branch is synced to `dev.gitlab.org` project
mirror. For example, if you are working on `gitlab-shell`, make sure that your
custom branch is pushed to the `gitlab-shell` repository on `dev.gitlab.org`
1. Create a branch in the omnibus-gitlab repository
1. In this branch, open the related version file of the component and specify
the name of your branch prepended with the `buildfrombranch:` keyword.
For example, if you are working on `gitlab-shell` open `GITLAB_SHELL_VERSION`
and write `buildfrombranch:my-feature`
1. Commit and push the omnibus-gitlab branch to `dev.gitlab.org`

This will trigger a build of the custom package, and if the build is
successful, you will see a link at the bottom of the build trace with which you
will be able to download the custom package.
