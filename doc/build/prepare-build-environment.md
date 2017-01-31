# Setting up a build environment

Omnibus GitLab provides docker images for all the OS versions that it
supports and these are available in the
[Container Registry](https://gitlab.com/gitlab-org/omnibus-gitlab/container_registry).
Users can use these images to setup the build environment. The steps are as
follows

1. Install docker. Visit [official docs](https://docs.docker.com/engine/installation)
   for more details.
2. Login to GitLab's registry

    You need a GitLab.com account to use the GitLab.com's container registry.
    Login to the registry using the command given below. Provide your username
    and password (you will have to create a
    [personal access token](https://docs.gitlab.com/ce/api/README.html#personal-access-tokens_)
    and use it instead of password, if you have enabled 2FA), when prompted.

    **Note:** Please keep in mind that your password/personal access token will
    be stored in the file `~/.docker/config.json`.

    ```
    docker login registry.gitlab.com
    ```
3. Pull the docker image for the OS you need to build package for

    Omnibus GitLab registry contains images for all the supported OSs and
    versions. You can use one of them to build a package for it. For example,
    to prepare a build environment for Debian Jessie, you have to pull its
    image.

    ```
    docker pull registry.gitlab.com/gitlab-org/omnibus-gitlab:jessie
    ```
4. Start the container and enter its shell

    ```
    docker run -it registry.gitlab.com/gitlab-org/omnibus-gitlab:jessie bash
    ```

5. Clone the Omnibus GitLab source and change to the cloned directory


    ```
    git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git ~/omnibus-gitlab
    cd ~/omnibus-gitlab
    ```

6. Omnibus GitLab is optimized to use the internal repositories from
   dev.gitlab.org. This is specified in the `.custom_sources.yml` file in the
   root of the source tree and these repositories are not publicly usable. So,
   for personal builds, you have to use public alternatives of these repos.
   An example `.custom_sources.yml` file would be as follows. Edit the file
   and make necessary changes.

    ```
    gitlab-rails:
      remote: "https://gitlab.com/gitlab-org/gitlab-ce.git"
    gitlab-rails-ee:
      remote: "https://gitlab.com/gitlab-org/gitlab-ee.git"
    gitlab-shell:
      remote: "https://gitlab.com/gitlab-org/gitlab-shell.git"
    gitlab-workhorse:
      remote: "https://gitlab.com/gitlab-org/gitlab-workhorse.git"
    gitlab-pages:
      remote: "https://gitlab.com/gitlab-org/gitlab-pages"
    config_guess:
      remote: "git://git.savannah.gnu.org/config.git"
    omnibus:
      remote: "https://gitlab.com/gitlab-org/omnibus.git"
    registry:
      remote: "https://github.com/docker/distribution.git"
    rb-readline:
      remote: "https://github.com/ConnorAtherton/rb-readline.git"
    ```
7. Install the dependencies and generate binaries


    ```
    bundle install --path .bundle --binstubs
    ```

8. Run the build command to initiate a build process

    ```
    bin/omnibus build gitlab
    ```
    You can see the results of the build in the `pkg` folder at the root of the
    source tree.
