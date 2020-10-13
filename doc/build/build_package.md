---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Building an `omnibus-gitlab` package locally

## Preparing a build environment

Docker images with necessary build tools for building `omnibus-gitlab` packages
can be found at the [`GitLab Omnibus Builder`](https://gitlab.com/gitlab-org/gitlab-omnibus-builder)
project's [Container Registry](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/container_registry).

1. [Install Docker](https://docs.Docker.com/engine/installation/).

    > Containers need access to 4GB of memory to complete builds. Consult the documentation
    > for your container runtime. Docker for Mac and Docker for Windows are known to set
    > this value to 2GB for default installations.

1. Pull the Docker image for the OS you need to build a package for. The current
   version of the image used officially by `omnibus-gitlab` is referred to the
   `BUILDER_IMAGE_REVISION` environment variable in the
   [CI configuration](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.gitlab-ci.yml)

   ```shell
   docker pull registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION}
   ```

1. Clone the Omnibus GitLab source and change to the cloned directory:

   ```shell
   git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git ~/omnibus-gitlab
   cd ~/omnibus-gitlab
   ```

1. Start the container and enter its shell, while mounting the `omnibus-gitlab`
   directory in it:

   ```shell
   docker run -v ~/omnibus-gitlab:~/omnibus-gitlab -it registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION} bash
   ```

1. By default, `omnibus-gitlab` will choose GitLab's internal repositories from
   `dev.gitlab.org` to fetch sources of various GitLab components. Since this
   repository is not publicly accessible, set the environment variable
   `ALTERNATIVE_SOURCES` to `true`.

   ```shell
   export ALTERNATIVE_SOURCES=true
   ```

   Details of sources of various components is available in the
   [`.custom_sources.yml`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.custom_sources.yml)
   file.

1. By default, `omnibus-gitlab` codebase is optimized to be used in a CI
   environment. One such optimization is reusing the pre-compiled Rails assets
   that is built by GitLab's CI pipeline. To know how to leverage this in your
   builds, check [Fetch upstream assets](#fetch-upstream-assets) section. Or,
   you can choose to compile the assets during the package build by setting the
   `COMPILE_ASSETS` environment variable.

   ```shell
   export COMPILE_ASSETS=true
   ```

1. Install the libraries and other dependencies:

   ```shell
   cd ~/omnibus-gitlab
   bundle install --path .bundle --binstubs
   ```

### Fetch upstream assets

Pipelines on GitLab and GitLab-FOSS projects will create a Docker image with
pre-compiled assets and publish it to the container registry. While building
packages, it's possible to reuse these images instead of compiling the assets
again, and thus save time:

1. Fetch the assets Docker image corresponding to the ref of GitLab or
   GitLab-FOSS you are building. For example, to pull the asset image
   corresponding to latest master ref, run the following:

   ```shell
   docker pull registry.gitlab.com/gitlab-org/gitlab/gitlab-assets-ee:master
   ```

1. Create a container using that image

   ```shell
   docker create --name gitlab_asset_cache registry.gitlab.com/gitlab-org/gitlab/gitlab-assets-ee:master
   ```

1. Copy the asset directory from the container to the host

   ```shell
   docker cp gitlab_asset_cache:/assets ~/gitlab-assets
   ```

1. While starting the build environment container, mount the asset directory in
   it:

   ```shell
   docker run -v ~/omnibus-gitlab:~/omnibus-gitlab -v ~/gitlab-assets:/gitlab-assets -it registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_10:${BUILDER_IMAGE_REVISION} bash
   ```

1. Instead of setting `COMPILE_ASSETS` to true, set the path where assets can be
   found:

   ```shell
   export ASSET_PATH=/gitlab-assets
   ```

## Building the package

Once you have prepared the build environment and have made necessary changes, if
any, you can build packages using the provided Rake tasks:

1. For builds to work, Git working directory should be clean. So, commit your
   changes to a new branch.

1. Run the Rake task to build the package:

    ```shell
    bundle exec rake build:project
    ```

The packages will be built and available in the `~/omnibus-gitlab/pkg`
directory.

### Building an EE package

By default, `omnibus-gitlab` will build a CE package. If you want to build an EE
package, set the `ee` environment variable before running the Rake task:

```shell
export ee=true
```

## Miscellaneous

### Cleaning files created during build

You can clean up all temporary files generated during the build process with
`omnibus`'s `clean` command:

```shell
bin/omnibus clean
```

Adding the `--purge` purge option removes __ALL__ files generated during the
build including the project install directory (`/opt/gitlab`) and
the package cache directory (`/var/cache/omnibus/pkg`):

```shell
bin/omnibus clean --purge
```

### Getting further help on Omnibus

Full help for the Omnibus command line interface can be accessed with the
`help` command:

```shell
bin/omnibus help
```
