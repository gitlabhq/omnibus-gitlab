---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Building `omnibus-gitlab` packages and Docker images locally

NOTE: **Note:**
If you are a GitLab team member, you have access to our CI infrastructure which
can be used to build these artifacts. Check the [documentation](team_member_docs.md)
for more details.

## `omnibus-gitlab` packages

`omnibus-gitlab` uses the [omnibus](https://github.com/chef/omnibus) tool for
building packages for the supported operating systems. The omnibus tool will detect
the OS where it is being used and build packages for that OS. It is recommended
to use a Docker container corresponding to the OS as the environment for building
packages.

How to build a custom package locally is described in the
[dedicated document](build_package.md).

## All-in-one Docker image

NOTE: **Note:**
If you want individual Docker images for each GitLab component instead of the
all-in-one monolithic one, check out the
[CNG](https://gitlab.com/gitlab-org/build/CNG) repository.

GitLab's all-in-one Docker image uses the `omnibus-gitlab` package built for
Ubuntu 16.04 under the hood. The Dockerfile is optimized to be used in a CI
environment, with the expectation of packages being available over the Internet.

We're looking at improving this situation
[in issue #5550](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5550).

How to build an all-in-one Docker image locally is described in the
[dedicated document](build_docker_image.md).
