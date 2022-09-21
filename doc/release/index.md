---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Omnibus GitLab release process

Our main goal is to make it clear which version of GitLab is in an omnibus
package.

## How is the official Omnibus GitLab package built

The official package build is fully automated by GitLab Inc.

We can differentiate between two types of build:

- Packages for release to <https://packages.gitlab.com>.
- Test packages built from branches available in S3 buckets.

Both types are built on the same infrastructure.

## Infrastructure

Each package is built on the platform it is intended for (CentOS 6 packages are
built on CentOS6 servers, Debian 8 packages on Debian 8 servers and so on).
The number of build servers varies but there is always at least one build
server per platform.

The Omnibus GitLab project fully utilizes GitLab CI. This means that each push
to the Omnibus GitLab repository will trigger a build in GitLab CI which will
then create a package.

Since we deploy GitLab.com using Omnibus GitLab packages, we need a separate
remote to build the packages in case of a problem with GitLab.com or due to
a security release of a package.

This remote is located on <https://dev.gitlab.org/>. The only difference between the
Omnibus GitLab project on <https://dev.gitlab.org/> and other public remotes is that the
project has active GitLab CI and has specific runners assigned to the project
which run on the build servers. This is also the case for all GitLab components,
eg. GitLab Shell is exactly the same on <https://dev.gitlab.org/> as it is on GitLab.com.

All build servers run [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-ci-multi-runner) and all runners use a deploy key
to connect to the projects on <https://dev.gitlab.org/>. The build servers also have
access to official package repository at <https://packages.gitlab.com> and to a special
Amazon S3 bucket which stores the test packages.

## Build process

GitLab Inc is using the [release-tools project](https://gitlab.com/gitlab-org/release-tools/tree/master) to automate the release tasks
for every release. When the release manager starts the release process, a couple
of important things for Omnibus GitLab will be done:

1. All remotes of the project will be synced.
1. The versions of components will be read from GitLab CE/EE repository
  (eg. VERSION, GITLAB_SHELL_VERSION) and written to the Omnibus GitLab repository.
1. A specific Git tag will be created and synced to Omnibus GitLab repositories.

When the Omnibus GitLab repository on <https://dev.gitlab.org/> gets updated, GitLab CI
build gets triggered.

The specific steps can be seen in the `.gitlab-ci.yml` file in the Omnibus GitLab
repository. The builds are executed on all platforms at the same time.

During the build, Omnibus GitLab will pull external libraries from their source
locations and GitLab components like GitLab, GitLab Shell, GitLab Workhorse, and
so on will be pulled from <https://dev.gitlab.org/>.

Once the build completes and the .deb or .rpm packages are built, depending on
the build type package will be pushed to <https://packages.gitlab.com> or to a temporary
(files older than 30 days are purged) S3 bucket.

## Specifying component versions manually

### On your development machine

1. Pick a tag of GitLab to package (e.g. `v6.6.0`).
1. Create a release branch in your Omnibus GitLab repo (e.g. `6-6-stable`).
1. If the release branch already exists, for instance because you are doing a
   patch release, make sure to pull the latest changes to your local machine:

   ```shell
   git pull https://gitlab.com/gitlab-org/omnibus-gitlab.git 6-6-stable # existing release branch
   ```

1. Use `support/set-revisions` to set the revisions of files in
   `config/software/`. It will take tag names and look up the Git SHA1's, and set
   the download sources to <https://dev.gitlab.org/>. Use `set-revisions --ee` for an EE
   release:

   ```shell
   # usage: set-revisions [--ee] GITLAB_RAILS_REF GITLAB_SHELL_REF GITALY_REF GITLAB_ELASTICSEARCH_INDEXER_REF

   # For GitLab CE:
   support/set-revisions v1.2.3 v1.2.3 1.2.3 1.2.3 1.2.3

   # For GitLab EE:
   support/set-revisions --ee v1.2.3-ee v1.2.3 1.2.3 1.2.3 1.2.3
   ```

1. Commit the new version to the release branch:

   ```shell
   git add VERSION GITLAB_SHELL_VERSION GITALY_SERVER_VERSION
   git commit
   ```

1. Create an annotated tag in Omnibus GitLab corresponding to the GitLab tag.
   The omnibus tag looks like: `MAJOR.MINOR.PATCH+OTHER.OMNIBUS_RELEASE`, where
   `MAJOR.MINOR.PATCH` is the GitLab version, `OTHER` can be something like `ce`,
   `ee` or `rc1` (or `rc1.ee`), and `OMNIBUS_RELEASE` is a number (starting at 0):

   ```shell
   git tag -a 6.6.0+ce.0 -m 'Pin GitLab to v6.6.0'
   ```

   WARNING:
   Do NOT use a hyphen `-` anywhere in the Omnibus GitLab tag.

   Examples of converting an upstream tag to an omnibus tag sequence:

   | upstream tag     | omnibus tag sequence                        |
   | ------------     | --------------------                        |
   | `v7.10.4`        | `7.10.4+ce.0`, `7.10.4+ce.1`, `...`         |
   | `v7.10.4-ee`     | `7.10.4+ee.0`, `7.10.4+ee.1`, `...`         |
   | `v7.11.0.rc1-ee` | `7.11.0+rc1.ee.0`, `7.11.0+rc1.ee.1`, `...` |

1. Push the branch and the tag to both <https://gitlab.com> and <https://dev.gitlab.org/>:

   ```shell
   git push git@gitlab.com:gitlab-org/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   git push git@dev.gitlab.org:gitlab/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
   ```

   Pushing an annotated tag to <https://dev.gitlab.org/> triggers a package release.

### Publishing the packages

You can track the progress of package building on <https://dev.gitlab.org/gitlab/omnibus-gitlab/builds>.
They are pushed to [packagecloud repositories](https://packages.gitlab.com/gitlab/) automatically after
successful builds.

### Updating cloud images

The cloud image release process is documented here: <https://about.gitlab.com/handbook/alliances/cloud-images/>.

New image are released when:

1. There is a new monthly release of GitLab.
1. A security vulnerability has been fixed in a patch release.
1. There is a patch that fixes a critical issue impacting the image.

New images should be released within 3 business days of the package release.

Image specific release documentation:

- (**Deprecated**) [OpenShift](https://docs.gitlab.com/charts/development/release.html).
