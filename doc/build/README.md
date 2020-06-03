---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

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

#### Platform-specific build via pipelines

We use Dockerfiles in the [Omnibus GitLab Builder](https://gitlab.com/gitlab-org/gitlab-omnibus-builder) project to provide the build environment for platform-specific packaging. If you are modifying one of these build environments and want to test your changes to ensure that the packaging still works, you can follow these steps:

  1. Commit your change to the [Omnibus GitLab Builder](https://gitlab.com/gitlab-org/gitlab-omnibus-builder) project, and confirm that the pipeline completes successfully. [Here is an example pipeline](https://dev.gitlab.org/cookbooks/gitlab-omnibus-builder/pipelines/155519).
     - Note: As you can tell from this link, a commit to `gitlab.com/gitlab-org/gitlab-omnibus-builder` will trigger a pipeline in `dev.gitlab.org/cookbooks/gitlab-omnibus-builder`, because the latter is a mirror. We rely on the `dev.gitlab.com` pipeline for generating the build environment images for some platforms. Others are also available on the `gitlab.org` pipelines.
  1. In the pipeline mentioned above, note the image name and tag pushed from the relevant job in the `test` stage (for this example, the job name is `debian_10 test`).
  1. Create a branch off of `master` from [Omnibus GitLab in dev](https://dev.gitlab.org/gitlab/omnibus-gitlab) and confirm that it creates a new pipeline.
    - Note: You can immediately cancel the running pipeline as we will need to trigger it with specific variables.
  1. [Trigger a new pipeline](https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines/new) for your branch (created in the step above) with the following variables:
     - `BUILDER_IMAGE_REGISTRY=${IMAGE_NAME}` (for example: `dev.gitlab.org:5005/cookbooks/gitlab-omnibus-builder/staging`)
     - `BUILDER_IMAGE_REVISION=${IMAGE_TAG}` (for example: `debian-change-branch`)
     - `ee=true` (only if you need to build GitLab EE; for example, you would not set this for a Raspberry Pi build)
  1. Ensure that the OS-specific package is uploaded in the relevant job for the `package-and-image` stage.
     - For example, the `Debian-10-branch` [job](https://dev.gitlab.org/gitlab/omnibus-gitlab/-/jobs/7955045) shows the .deb in the logs: `https://omnibus-builds.s3.amazonaws.com/debian-buster/gitlab-ce_13.0.3%2Brfbranch.156562.e150c78b-0_amd64.deb`

The package will be available to download from GitLab for 1 day. We will use `curl` in the next section to download this artifact into our target system.

#### Testing platform-specific packages

Once you have a platform-specific package built, you can follow the steps below to test that it works on the target platform.

  1. Launch an instance of the target platform (preferably in a virtual machine or on bare-metal).
  1. Prepare your system with the relevant dependencies using the [platform-specific installation instructions](https://about.gitlab.com/install/).
  1. Download the platform-specific package from the job mentioned [above](#platform-specific-build-via-pipelines) using `curl`:

     ```shell
     curl --header 'Private-Token: ${PERSONAL_ACCESS_TOKEN}' \
       -o ${PACKAGE_NAME_AND_EXTENSION} \
       -L "https://dev.gitlab.org/api/v4/projects/${PROJECT_ID}/jobs/${JOB_ID}/artifacts/${PACKAGE_PATH}"
     ```

  1. Follow the installation instructions for [manually downloading and installing a GitLab package](../manual_install.md#installing-the-gitlab-package).

You should now have a running instance of GitLab using the package you downloaded. If you want to perform further testing, you can run [GitLab QA](https://gitlab.com/gitlab-org/gitlab-qa) against the instance.

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
