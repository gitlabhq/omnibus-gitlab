# Omnibus-gitlab release process

Our main goal is to make it clear which version of GitLab is in an omnibus package.

## On your development machine

1. Pick a tag of GitLab to package (e.g. `v6.6.0`).
1. Create a release branch in omnibus-gitlab (e.g. `6-6-stable`).
1. If the release branch already exists, for instance because you are doing a
  patch release, make sure to pull the latest changes to your local machine:

    ```
    git pull https://gitlab.com/gitlab-org/omnibus-gitlab.git 6-6-stable # existing release branch
    ```

1. Use `support/set-revisions` to set the revisions of files in
  `config/software/`. It will take tag names and look up the Git SHA1's, and set
  the download sources to dev.gitlab.org. Use `set-revisions --ee` for an EE
  release:

    ```
    # usage: set-revisions [--ee] GITLAB_RAILS_REF GITLAB_SHELL_REF

    # For 6.6.0 CE:
    support/set-revisions v6.6.0 v1.2.3

    # For 7.14 EE:
    support/set-revisions --ee v7.14.0-ee v2.6.4
    ```

1. Commit the new version to the release branch:

    ```shell
    git commit -v config/software
    ```

1. Create an annotated tag on omnibus-gitlab corresponding to the GitLab tag.
  The omnibus tag looks like: `MAJOR.MINOR.PATCH+OTHER.OMNIBUS_RELEASE`, where
  `MAJOR.MINOR.PATCH` is the GitLab version, `OTHER` can be something like `ce`,
  `ee` or `rc1` (or `rc1.ee`), and `OMNIBUS_RELEASE` is a number (starting at 0):

    ```shell
    git tag -a 6.6.0+ce.0 -m 'Pin GitLab to v6.6.0'
    ```

    **WARNING:** Do NOT use a hyphen `-` anywhere in the omnibus-gitlab tag.

    Examples of converting an upstream tag to an omnibus tag sequence:

    | upstream tag     | omnibus tag sequence                        |
    | ------------     | --------------------                        |
    | `v7.10.4`        | `7.10.4+ce.0`, `7.10.4+ce.1`, `...`         |
    | `v7.10.4-ee`     | `7.10.4+ee.0`, `7.10.4+ee.1`, `...`         |
    | `v7.11.0.rc1-ee` | `7.11.0+rc1.ee.0`, `7.11.0+rc1.ee.1`, `...` |

1. Push the branch and the tag to both gitlab.com and dev.gitlab.org:

    ```shell
    git push git@gitlab.com:gitlab-org/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
    git push git@dev.gitlab.org:gitlab/omnibus-gitlab.git 6-6-stable 6.6.0+ce.0
    ```

    Pushing an annotated tag to dev.gitlab.org triggers a package release.

## Publishing the packages

You can track the progress of package building on [ci.gitlab.org](https://ci.gitlab.org/projects/55).
They are pushed to [packagecloud](https://packages.gitlab.com/gitlab/)
automatically after successful builds.
