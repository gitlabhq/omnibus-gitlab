---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Building `omnibus-gitlab` packages and Docker images locally
---

{{< alert type="note" >}}

If you are a GitLab team member, you have access to our CI infrastructure which
can be used to build these artifacts. Check the [documentation](team_member_docs.md)
for more details.

{{< /alert >}}

## `omnibus-gitlab` packages

<!-- vale gitlab_base.SubstitutionWarning = NO -->

`omnibus-gitlab` uses [Omnibus](https://github.com/chef/omnibus) for
building packages for the supported operating systems. Omnibus detects
the OS where it is being used and build packages for that OS. You should use a
Docker container corresponding to the OS as the environment for building packages.

<!-- vale gitlab_base.SubstitutionWarning = YES -->

How to build a custom package locally is described in the
[dedicated document](build_package.md).

## All-in-one Docker image

{{< alert type="note" >}}

If you want individual Docker images for each GitLab component instead of the
all-in-one monolithic one, check out the
[CNG](https://gitlab.com/gitlab-org/build/CNG) repository.

{{< /alert >}}

The GitLab all-in-one Docker image uses the `omnibus-gitlab` package built for
Ubuntu 24.04 under the hood. The Dockerfile is optimized to be used in a CI
environment, with the expectation of packages being available over the Internet.

We're looking at improving this situation
[in issue #5550](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5550).

How to build an all-in-one Docker image locally is described in the
[dedicated document](build_docker_image.md).
