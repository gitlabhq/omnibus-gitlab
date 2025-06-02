---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Build a GitLab Docker image locally
---

The GitLab Docker image uses the Ubuntu 24.04 package created by
`omnibus-gitlab`. Most of the files needed for building a Docker image
are in the `Docker` directory of the `omnibus-gitlab` repository.
The `RELEASE` file is not in this directory, and you must create this file.

## Create the `RELEASE` file

The version details of the package being used are stored in the `RELEASE` file.
To build your own Docker image, create this file in the `docker/` folder with
contents similar to the following.

```plaintext
RELEASE_PACKAGE=gitlab-ee
RELEASE_VERSION=13.2.0-ee
DOWNLOAD_URL_amd64=https://example.com/gitlab-ee_13.2.00-ee.0_amd64.deb
```

- `RELEASE_PACKAGE` specifies whether the package is a CE one or EE one.
- `RELEASE_VERSION` specifies the version of the package, for example `13.2.0-ee`.
- `DOWNLOAD_URL_amd64` specifies the URL for amd64 where that package can be downloaded from.
- `DOWNLOAD_URL_arm64` specifies the URL for arm64 where that package can be downloaded from.

{{< alert type="note" >}}

We're looking at improving this situation, and using locally available packages
[in issue #5550](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5550).

{{< /alert >}}

## Build the Docker image

To build the Docker image after populating the `RELEASE` file:

```shell
cd docker
docker build -t omnibus-gitlab-image:custom .
```

The image is built and tagged as `omnibus-gitlab-image:custom`.
