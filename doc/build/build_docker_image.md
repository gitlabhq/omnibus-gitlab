---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Building an all-in-one GitLab Docker image locally

GitLab's all-in-one Docker image uses Ubuntu 16.04 package created by
`omnibus-gitlab` under the hood. The files required for building Docker image
can be found inside the `Docker` directory of `omnibus-gitlab` repository,
except `RELEASE` file which needs to be compiled manually, as described below.

## RELEASE file

The details of the version of the package being used is stored in a file named
`RELEASE`. To build your own Docker image, you should create this file with
contents similar to the following

```plaintext
RELEASE_PACKAGE=gitlab-ee
RELEASE_VERSION=13.2.0-ee
DOWNLOAD_URL=https://example.com/gitlab-ee_13.2.00-ee.0_amd64.deb
```

Here, `RELEASE_PACKAGE` specifies whether the package is a CE one or EE one.
`RELEASE_VERSION` specifies the version of the package (`13.2.0-ee`,
`12.9.2+rfbranch.150270.c43b3273-0`, etc.). `DOWNLOAD_URL` specifies the URL
where that package can be downloaded from.

NOTE **Note:**
We're looking at improving this situation, and using locally available packages
[in issue #5550](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5550).

## Building the Docker image

To build the Docker image after populating the `RELEASE` file:

```shell
cd docker
docker build -t omnibus-gitlab-image:custom .
```

The image will be built and tagged as `omnibus-gitlab-image:custom`.
