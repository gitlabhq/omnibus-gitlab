---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Team member's guide of using official build infrastructure

If you are a member of the GitLab team, you will have access to the build
infrastructure (or to the colleagues who have access to the infrastructure) and
leverage it to build packages.

## I have an MR in `gitlab-org/gitlab` project and want a package or Docker image to test it

In the CI pipeline corresponding to your MR, play the `package-and-qa` job in
the `qa` stage. This will trigger a downstream pipeline in `omnibus-gitlab`'s
[QA mirror](https://gitlab.com/gitlab-org/build/omnibus-gitlab-mirror) which
will get you an Ubuntu 20.04 package and an all-in-one Docker image for testing.
It will also run trigger a `gitlab-qa` run using these artifacts too.

## I have an MR in the `omnibus-gitlab` project and want a package or Docker image to test it

Similar to `GitLab` project, pipelines running for MRs in `omnibus-gitlab` also
have manual jobs to get a package or Docker image - `Trigger:ce-package` and
`Trigger:ee-package`, which as their names suggest builds you CE and EE packages
and Docker images, and will perform a QA run.

## I want to use specific branches or versions of various GitLab components in my build

Versions of the primary GitLab components like GitLab-Rails, Gitaly, GitLab
Pages, GitLab Shell, GitLab Elasticsearch Indexer are controlled by various
`*_VERSION` files in `omnibus-gitlab` repository and `*_VERSION` environment
variables present during the build. Check the table below for details:

| File name                            | Environment Variable                 | Description |
| ------------------------------------ | ------------------------------------ | ----------- |
| VERSION                              | GITLAB_VERSION                       | Controls Git reference of GitLab Rails application. By default, points to `master` branch of GitLab-FOSS repository. If you want to use the GitLab repository, set the environment variable `ee` to true. |
| GITALY_SERVER_VERSION                | GITALY_SERVER_VERSION                | Git reference of the [Gitaly](https://gitlab.com/gitlab-org/gitaly) repository. |
| GITLAB_PAGES_VERSION                 | GITLAB_PAGES_VERSION                 | Git reference of the [GitLab Pages](https://gitlab.com/gitlab-org/gitlab-pages) repository.|
| GITLAB_SHELL_VERSION                 | GITLAB_SHELL_VERSION                 | Git reference of the [GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell) repository.|
| GITLAB_ELASTICSEARCH_INDEXER_VERSION | GITLAB_ELASTICSEARCH_INDEXER_VERSION | Git reference of the [GitLab Elasticsearch Indexer](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer) repository. Used only in EE builds.|
| GITLAB_KAS_VERSION                   | GITLAB_KAS_VERSION                   | Git reference of the [GitLab Kubernetes Agent Server](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent) repository.|

If you are running `package-and-qa` job from a GitLab MR, `GITLAB_VERSION`
environment variable will be set to the commit SHA corresponding to the pipeline
while other environment variables, if not specified, will be populated from
their corresponding files and passed on to the triggered pipeline.

NOTE:
Environment variables take precedence over `*_VERSION` files.

### Specifying a component version temporarily

Temporarily specify a component version using any of the following methods:

1. Edit the `*_VERSION` file, commit and push to start a pipeline, but revert
   this change before the MR is marked ready for merge. It is recommended to
   open an unresolved discussion on this diff in the MR so that you remember to
   revert it.

1. Set the environment variable via `.gitlab-ci.yml` file, commit and push to
   start a pipeline, but revert this change before the MR is marked ready for
   merge. It is recommended to open an unresolved discussion on this diff in the
   MR so that you remember to revert it.

1. Pass the environment variable as a [Git push option](https://docs.gitlab.com/ee/user/project/push_options.html#push-options-for-gitlab-cicd).

    ```shell
    git push <REMOTE> -o ci.variable="<ENV_VAR>=<VALUE>"

    # Passing multiple variables
    git push <REMOTE> -o ci.variable="<ENV_VAR_1>=<VALUE_1>" -o ci.variable="<ENV_VAR_2>=<VALUE_2>"
    ```

    **`Note`**: This works only if you have some changes to push. If remote is
    already updated with your local branch, no new pipeline will be created.

1. Manually run the pipeline from UI while specifying the environment variables.

Environment variables are passed to the triggered downstream pipeline in the
[QA mirror](https://gitlab.com/gitlab-org/build/omnibus-gitlab-mirror) so that
they are used during builds.

Generally, environment variables are preferred over changing the `*_VERSION`
files to avoid the extra step of reverting changes. The `*_VERSION` files are
most efficient when repeated package builds of `omnibus-gitlab` are required,
but the only changes happening are in GitLab components. In this case, once a
pipeline is run after changing the `*_VERSION` files, it can be retried to build
new packages pulling in changes from upstream component feature branch instead
of manually running new pipelines.

## I want to use a specific mirror or fork of various GitLab components in my build

The repository sources for most software that Omnibus Builds can be found in
the `.custom_sources.yml` file in the `omnibus-gitlab` repository. The main
GitLab components can be overridden via environment variables. Check the table
below for details:

| Environment Variable                          | Description |
| --------------------------------------------- | ----------- |
| ALTERNATIVE_PRIVATE_TOKEN                     | An access token used if needing to pull from private repositories. |
| GITLAB_ALTERNATIVE_REPO                       | Git repository location for the GitLab Rails application. |
| GITLAB_SHELL_ALTERNATIVE_REPO                 | Git repository location for [GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell). |
| GITLAB_PAGES_ALTERNATIVE_REPO                 | Git repository location for [GitLab Pages](https://gitlab.com/gitlab-org/gitlab-pages). |
| GITALY_SERVER_ALTERNATIVE_REPO                | Git repository location for [Gitaly](https://gitlab.com/gitlab-org/gitaly). |
| GITLAB_ELASTICSEARCH_INDEXER_ALTERNATIVE_REPO | Git repository location for [GitLab Elasticsearch Indexer](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer). |
| GITLAB_KAS_ALTERNATIVE_REPO                   | Git repository location for [GitLab Kubernetes Agent Server](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent). |

## Building packages for other OSs

If you specifically want a package for an OS other than Ubuntu 20.04, or want to
ensure packages can be built with your change on all OSs, you will have to make
us of `omnibus-gitlab`'s [Release mirror](https://dev.gitlab.org/gitlab/omnibus-gitlab).

A prerequisite for this is access to push branches to `omnibus-gitlab`'s
[Release mirror](https://dev.gitlab.org/gitlab/omnibus-gitlab).

1. Modify various `*_VERSION` files or environment variables as specified in the
   above section if needed. You might want to set `ee` environment variable in
   the [CI config](https://gitlab.com/gitlab-org/omnibus-gitlab/.gitlab-ci.yml)
   to `true` to use a commit from GitLab repository instead of GitLab-FOSS.

1. Push your branch to the [Release mirror](https://dev.gitlab.org/gitlab/omnibus-gitlab)
   and check the [Pipelines](https://dev.gitlab.org/gitlab/omnibus-gitlab/pipeliens).

1. The pipeline will build packages for all supported OSs, and a Docker image.
