---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Team member's guide to using official build infrastructure

If you are a GitLab team member, you have access to the build
infrastructure or to the colleagues who have access to the infrastructure. You
can use that access to build packages.

## Test a `gitlab-org/gitlab` project merge request

If you have a merge request (MR) in the `gitlab-org/gitlab` project, you can
test that MR using a package or a Docker image.

In the CI pipeline corresponding to your MR, run the `package-and-qa` job in
the `qa` stage to trigger:

- A downstream pipeline in the `omnibus-gitlab`
[QA mirror](https://gitlab.com/gitlab-org/build/omnibus-gitlab-mirror), which
gives you an Ubuntu 20.04 package and an all-in-one Docker image for testing.
- A `gitlab-qa` run using these artifacts as well.

## Test an `omnibus-gitlab` project MR

If you have an MR in the `omnibus-gitlab` project, you can
test that MR using a package or a Docker image.

Similar to the `GitLab` project, pipelines running for MRs in `omnibus-gitlab` also
have manual jobs to get a package or Docker image. The `Trigger:ce-package` and
`Trigger:ee-package` jobs build CE and EE packages and Docker images and perform a QA run.

## Use specific branches or versions of a GitLab component

Versions of the primary GitLab components like GitLab Rails or Gitaly are controlled by:

- `*_VERSION` files in the `omnibus-gitlab` repository.
- `*_VERSION` environment variables present during the build.

Check the following table for more information:

| Filename                            | Environment variable                 | Description |
| ------------------------------------ | ------------------------------------ | ----------- |
| VERSION                              | GITLAB_VERSION                       | Controls the Git reference of the GitLab Rails application. By default, points to the `master` branch of the GitLab-FOSS repository. If you want to use the GitLab repository, set the environment variable `ee` to true. |
| GITALY_SERVER_VERSION                | GITALY_SERVER_VERSION                | Git reference of the [Gitaly](https://gitlab.com/gitlab-org/gitaly) repository. |
| GITLAB_PAGES_VERSION                 | GITLAB_PAGES_VERSION                 | Git reference of the [GitLab Pages](https://gitlab.com/gitlab-org/gitlab-pages) repository.|
| GITLAB_SHELL_VERSION                 | GITLAB_SHELL_VERSION                 | Git reference of the [GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell) repository.|
| GITLAB_ELASTICSEARCH_INDEXER_VERSION | GITLAB_ELASTICSEARCH_INDEXER_VERSION | Git reference of the [GitLab Elasticsearch Indexer](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer) repository. Used only in EE builds.|
| GITLAB_KAS_VERSION                   | GITLAB_KAS_VERSION                   | Git reference of the [GitLab Kubernetes Agent Server](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent) repository.|

If you are running the `package-and-qa` job from a GitLab MR, the `GITLAB_VERSION`
environment variable is set to the commit SHA corresponding to the pipeline.
Other environment variables, if not specified, are populated from
their corresponding files and passed on to the triggered pipeline.

NOTE:
Environment variables take precedence over `*_VERSION` files.

### Temporarily specify a component version

Temporarily specify a component version using any of the following methods:

- Edit the `*_VERSION` file, commit and push to start a pipeline, but revert
  this change before the MR is marked ready for merge. We recommend you
  open an unresolved discussion on this diff in the MR so you remember to
  revert it.

- Set the environment variable in the `.gitlab-ci.yml` file, commit and push to
  start a pipeline, but revert this change before the MR is marked ready for
  merge. We recommend you open an unresolved discussion on this diff in the
  MR so you remember to revert it.

- Pass the environment variable as a [Git push option](https://docs.gitlab.com/ee/user/project/push_options.html#push-options-for-gitlab-cicd).

  ```shell
  git push <REMOTE> -o ci.variable="<ENV_VAR>=<VALUE>"

  # Passing multiple variables
  git push <REMOTE> -o ci.variable="<ENV_VAR_1>=<VALUE_1>" -o ci.variable="<ENV_VAR_2>=<VALUE_2>"
  ```

  **`Note`**: This works only if you have some changes to push. If remote is
  already updated with your local branch, no new pipeline is created.

- Manually run the pipeline from UI while specifying the environment variables.

Environment variables are passed to the triggered downstream pipeline in the
[QA mirror](https://gitlab.com/gitlab-org/build/omnibus-gitlab-mirror) so that
they are used during builds.

You should use environment variables instead of changing the `*_VERSION`
files to avoid the extra step of reverting changes. The `*_VERSION` files are
most efficient when you need repeated package builds of `omnibus-gitlab`,
but the only changes happening are in GitLab components. In this case, when a
pipeline is run after changing the `*_VERSION` files, it can be retried to build
new packages pulling in changes from the upstream component feature branch instead
of manually running new pipelines.

## Use a specific mirror or fork of a GitLab component

The repository sources for most software that Omnibus builds are in
the `.custom_sources.yml` file in the `omnibus-gitlab` repository. You can override
the main GitLab components using environment variables. Check the table
below for details:

| Environment variable                          | Description |
| --------------------------------------------- | ----------- |
| ALTERNATIVE_PRIVATE_TOKEN                     | An access token used if needing to pull from private repositories. |
| GITLAB_ALTERNATIVE_REPO                       | Git repository location for the GitLab Rails application. |
| GITLAB_SHELL_ALTERNATIVE_REPO                 | Git repository location for [GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell). |
| GITLAB_PAGES_ALTERNATIVE_REPO                 | Git repository location for [GitLab Pages](https://gitlab.com/gitlab-org/gitlab-pages). |
| GITALY_SERVER_ALTERNATIVE_REPO                | Git repository location for [Gitaly](https://gitlab.com/gitlab-org/gitaly). |
| GITLAB_ELASTICSEARCH_INDEXER_ALTERNATIVE_REPO | Git repository location for [GitLab Elasticsearch Indexer](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer). |
| GITLAB_KAS_ALTERNATIVE_REPO                   | Git repository location for [GitLab Kubernetes Agent Server](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent). |

## Build packages for other operating systems

Prerequisite:

- You must have permission to push branches to the `omnibus-gitlab` [release mirror](https://dev.gitlab.org/gitlab/omnibus-gitlab).

Use the release mirror to:

- Build a package for an operating system other than Ubuntu 20.04.
- Ensure packages with your changes can be built on all operating systems.

To build packages for other operating systems:

1. Modify `*_VERSION` files or environment variables as specified in the
   previous section if needed. You might want to set the `ee` environment variable in
   the [CI configuration](https://gitlab.com/gitlab-org/omnibus-gitlab/.gitlab-ci.yml)
   to `true` to use a commit from the GitLab repository instead of GitLab-FOSS.

1. Push your branch to the release mirror and check the
   [pipelines](https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines).

1. The pipeline builds packages for all supported operating systems and a Docker image.
