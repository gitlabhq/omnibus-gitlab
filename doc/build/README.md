# Preparing a build environment

See
https://gitlab.com/gitlab-org/gitlab-omnibus-builder/blob/master/README.md#recipe-default
for instructions on how to prepare a build box using Chef. After running the
cookbook you can perform builds as the `gitlab_ci_multi_runner` user.

```shell
# Ubuntu/Debian only: ensure you have proper locale available
sudo locale-gen en_US.UTF-8

# Login as build user
sudo su - gitlab_ci_multi_runner

# Set git author
git config --global user.email "email@example.com"
git config --global user.name "Example name"

# Ensure you have proper locale in the environment
export LC_ALL=en_US.UTF-8

# Clone the omnibus repo
git clone https://gitlab.com/gitlab-org/omnibus-gitlab.git

# Install gem dependencies for omnibus-ruby
cd omnibus-gitlab
bundle install --path .bundle --binstubs

# Do a build
bin/omnibus build gitlab
```

## Usage

*Important note* omnibus-gitlab project is used to build official GitLab
packages. These packages are also used to deploy GitLab.com.

The build tools are optimised for internal GitLab Inc infrastructure.
For example, omnibus-gitlab project will pull GitLab and dependent projects
code from internal dev.gitlab.org server. The internal server hosts the same
copy of the source code available elsewhere. Alternative source location is
necessary in case of an unforeseen circumstances.

All repositories used for building the packages that are not publicly reachable,
have their remotes listed in  `.custom_sources.yml` file in the root of this
project.

If you are using these tools to build your own packages, you will have to
adjust them to your needs.

At the time of writing, an example of a fully public config for `.custom_sources.yml`
would look like this:

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
```

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
