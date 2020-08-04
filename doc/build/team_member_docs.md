---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab Team member's guide of using official build infrastructure

If you are a member of the GitLab team, you will have access to the build
infrastructure (or to the colleagues who have access to the infrastructure) and
leverage it to build packages.

## I have an MR in `gitlab-org/gitlab` project and want a package or Docker image to test it

In the CI pipeline corresponding to your MR, play the `package-and-qa` job in
the `qa` stage. This will trigger a downstream pipeline in `omnibus-gitlab`'s
[QA mirror](https://gitlab.com/gitlab-org/build/omnibus-gitlab-mirror) which
will get you an Ubuntu 16.04 package and an all-in-one Docker image for testing.
It will also run trigger a `gitlab-qa` run using these artifacts too.

## I have an MR in the `omnibus-gitlab` project and want a package or Docker image to test it

Similar to `GitLab` project, pipelines running for MRs in `omnibus-gitlab` also
have manual jobs to get a package or Docker image - `Trigger:ce-package` and
`Trigger:ee-package`, which as their names suggest builds you CE and EE packages
and Docker images, and will perform a QA run.

## I want to use specific branches or versions of various GitLab components in my build

Versions of the main GitLab components like GitLab-Rails, Gitaly, GitLab Pages,
GitLab Shell, GitLab Workhorse, GitLab Elasticsearch Indexer is controlled by
various `*_VERSION` files in `omnibus-gitlab` repository. You can modify these
files to point to your intended targets and the builds will use them. All of
those files accept a branch name, a tag name, or a commit SHA as their content.
They can also be provided via environment variables. Check the table below for
details:

| File name                            | Environment Variable                 | Description |
| ------------------------------------ | ------------------------------------ | ----------- |
| VERSION                              | GITLAB_VERSION                       | Controls Git reference of GitLab Rails application. By default, points to `master` branch of GitLab-FOSS repository. If you want to use the GitLab repository, set the environment variable `ee` to true. |
| GITALY_SERVER_VERSION                | GITALY_SERVER_VERSION                | Git reference of the [Gitaly](https://gitlab.com/gitlab-org/gitaly) repository. |
| GITLAB_PAGES_VERSION                 | GITLAB_PAGES_VERSION                 | Git reference of the [GitLab Pages](https://gitlab.com/gitlab-org/gitlab-pages) repository.|
| GITLAB_SHELL_VERSION                 | GITLAB_SHELL_VERSION                 | Git reference of the [GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell) repository.|
| GITLAB_WORKHORSE_VERSION             | GITLAB_WORKHORSE_VERSION             | Git reference of the [GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse) repository.|
| GITLAB_ELASTICSEARCH_INDEXER_VERSION | GITLAB_ELASTICSEARCH_INDEXER_VERSION | Git reference of the [GitLab Elasticsearch Indexer](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer) repository. Used only in EE builds.|

If you are running `package-and-qa` job from a GitLab MR, `GITLAB_VERSION`
environment variable will be set to the commit SHA corresponding to the pipeline
while other environment variables, if not specified, will be populated from
their corresponding files and passed on to the triggered pipeline.

## Building packages for other OSs

If you specifically want a package for an OS other than Ubuntu 16.04, or want to
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
