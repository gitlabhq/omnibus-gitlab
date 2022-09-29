---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Build a GitLab Docker image locally

The GitLab Docker image uses the Ubuntu 20.04 package created by
`omnibus-gitlab`. Most of the files needed for building a Docker image
are in the `Docker` directory of the `omnibus-gitlab` repository.
The `RELEASE` file is not in this directory, and you must create this file.

## Create the `RELEASE` file

The version details of the package being used are stored in the `RELEASE` file.
To build your own Docker image, create this file with contents similar to the following.

```plaintext
RELEASE_PACKAGE=gitlab-ee
RELEASE_VERSION=13.2.0-ee
DOWNLOAD_URL=https://example.com/gitlab-ee_13.2.00-ee.0_amd64.deb
```

- `RELEASE_PACKAGE` specifies whether the package is a CE one or EE one.
- `RELEASE_VERSION` specifies the version of the package, for example `13.2.0-ee`.
- `DOWNLOAD_URL` specifies the URL where that package can be downloaded from.

NOTE **Note:**
We're looking at improving this situation, and using locally available packages
[in issue #5550](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5550).

## Build the Docker image

To build the Docker image after populating the `RELEASE` file:

```shell
cd docker
docker build -t omnibus-gitlab-image:custom .
```

The image is built and tagged as `omnibus-gitlab-image:custom`.
