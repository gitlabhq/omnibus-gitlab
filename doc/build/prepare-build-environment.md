---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Setting up a build environment

Omnibus GitLab provides Docker images for all the OS versions that it
supports and these are available in the
[Container Registry](https://gitlab.com/gitlab-org/omnibus-gitlab/container_registry).
Users can use these images to setup the build environment. The steps are as
follows

1. Install Docker. Visit [official docs](https://docs.docker.com/engine/installation/)
   for more details.

> Containers need access to 4GB of memory to complete builds. Consult the documentation
> for your container runtime. Docker for Mac and Docker for Windows are known to set
> this value to 2GB for default installations.

1. Pull the Docker image for the OS you need to build a package for.
   [`gitlab-omnibus-builder` registry](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/container_registry)
   contains images for all the supported OSs and versions. You can use one of
   them to build a package for it. For example, to prepare a build environment
   for Debian Stretch, you have to pull its image. The revision of the image to
   be used is specified in `BUILDER_IMAGE_REVISION` variable in
   [`.gitlab-ci.yml`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.gitlab-ci.yml)
   file. Make sure you substitute that value to `${BUILDER_IMAGE_REVISION}`
   in the following commands.

   ```shell
   docker pull registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_9:${BUILDER_IMAGE_REVISION}
   ```

1. Start the container and enter its shell:

   ```shell
   docker run -it registry.gitlab.com/gitlab-org/gitlab-omnibus-builder/debian_9:${BUILDER_IMAGE_REVISION} bash
   ```

1. Clone the Omnibus GitLab source and change to the cloned directory:

   ```shell
   git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git ~/omnibus-gitlab
   cd ~/omnibus-gitlab
   ```

1. Omnibus GitLab is optimized to use the internal repositories from
   <https://dev.gitlab.org>. These repositories are specified in the `.custom_sources.yml`
   file (specified by `remote` key) in the root of the source tree and will be
   used by default. Since these repositories are not publicly usable, for
   personal builds you have to use public alternatives of these repositories. The
   alternatives are also provided in the same file, specified by `alternative`
   key. The selection between these two is controlled by `ALTERNATIVE_SOURCES`
   environment variable, which can be set either `true` or `false`. If that
   variable is set `true`, the repositories marked by `alternative` key will be
   used.
   Similarly, if you want to use your custom forks as sources, modify the
   `.custom_sources.yml` file and specify them as `alternate` and set the
   `ALTERNATIVE_SOURCES` variable to `true`.

1. By default, Omnibus GitLab uses a Docker image containing pre-compiled assets for the `config/software/gitlab-rails.rb`
   1. If you are building from a mirror of the GitLab application on the same instance, you should not need to do anything.
   1. To use the upstream assets, set the `ASSET_REGISTRY` environment variable to `registry.gitlab.com`
   1. To compile your own, set the `COMPILE_ASSETS` environment variable to `true`
1. Install the dependencies and generate binaries:

   ```shell
   bundle install --path .bundle --binstubs
   ```

1. Run the build command to initiate a build process:

   ```shell
   bin/omnibus build gitlab
   ```

   You can see the results of the build in the `pkg` folder at the root of the
   source tree.
