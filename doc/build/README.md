# Preparing a build environment

See [Preparing a Build Environment page](prepare-build-environment.md)
for instructions on how to prepare build environment using Docker.

## Usage

### Build

You create a platform-specific package using the `build` command:

```shell
bin/omnibus build gitlab
```

NOTE: **Note**: By default, the build process attempts to download sources from `dev.gitlab.org`, which is only available to GitLab employees. If you would like to pull from publically available sources, set the environment variable `ALTERNATIVE_SOURCES=true`

The platform/architecture type of the package created will match the platform
where the `build project` command is invoked. So running this command on say a
MacBook Pro will generate a Mac OS X specific package. After the build
completes packages will be available in `pkg/`.

### Clean

You can clean up all temporary files generated during the build process with
the `clean` command:

```shell
bin/omnibus clean
```

Adding the `--purge` purge option removes __ALL__ files generated during the
build including the project install directory (`/opt/gitlab`) and
the package cache directory (`/var/cache/omnibus/pkg`):

```shell
bin/omnibus clean --purge
```

### Help

Full help for the Omnibus command line interface can be accessed with the
`help` command:

```shell
bin/omnibus help
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

>**Note** For a description on how the official Omnibus GitLab package is built,
see the [release process](../release/README.md) document.

If you are working on implementing a feature in one of the GitLab components,
you might need to build a package from your custom branch in order to test the
feature using the Omnibus GitLab package.

For example, you've implemented something inside of GitLab Rails application and
the code is located in the branch named `my-feature`.

To use the custom branch for building an Omnibus GitLab package, you will need
to put the branch name in `VERSION` file inside of Omnibus GitLab repository.

The same works for specifying commits also. If you want to build a package that
will use a specific commit, you have to place the SHA of that commit in the
VERSION file.

For example, if you want to build a package that will use a branch named
`my-feature-branch`, `VERSION` file in omnibus-repo should contain the text
`my-feature-branch`. Similarly, if you want to build a package that will use
a specific commit, say [this one](https://dev.gitlab.org/gitlab/gitlabhq/commit/46973f3d4602c7ea6366d6401116b89d72b83b9e),
`VERSION` file should contain the text `46973f3d4602c7ea6366d6401116b89d72b83b9e`,
which is the SHA of that commit.

Similarly, you can do the same for `GITLAB_WORKHORSE_VERSION` and so on.

**Note:** Name of this custom branch should not match the format of a SemVer
version, that is `xx.yy.zz`. This is because Omnibus GitLab will append a `v`
before the branch name, mistaking it for a version tag. Example, branch name
can not be `0.5.0` as Omnibus GitLab will automatically make it `v0.5.0`.

## Building an EE package

To build a GitLab EE package, set the environment variable `ee` to true (run
the command `$ export ee=true`) before starting the build. It will make
Omnibus GitLab pull the EE repo instead of CE one and build an EE package.

### Note for GitLab Inc. developers

If you are a member of the GitLab Inc. team, you will have access to the build
infrastructure (or to the colleagues that have access to the infrastructure).

You can easily build custom packages leveraging the build infrastructure to test
your code.

Before you start,
**you need push access to the Omnibus GitLab repository.**

If you have (someone with) access, you need to:

1. Make sure that your custom branch is synced to `dev.gitlab.org` project
   mirror. For example, if you are working on `gitlab-shell`, make sure that your
   custom branch is pushed to the `gitlab-shell` repository on `dev.gitlab.org`
1. Create a branch in the Omnibus GitLab repository
1. In this branch, open the related version file of the component and specify
   the name of your branch. For example, if you are working on `gitlab-shell` open
   `GITLAB_SHELL_VERSION` and write `my-feature`
1. Commit and push the Omnibus GitLab branch to `dev.gitlab.org`

This will trigger a build of the custom package, and if the build is
successful, you will see a link at the bottom of the build trace with which you
will be able to download the custom package.

You can also change the verbosity of the build output using the CI build infrastructure.
In CI/CD variables on the Omnibus GitLab project settings (on <https://dev.gitlab.org>), add
`BUILD_LOG_LEVEL` variable with `debug` and run the pipeline.
