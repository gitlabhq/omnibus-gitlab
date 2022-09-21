---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Version format for the packages and Docker images

## Packages

Packages built by the `omnibus-gitlab` continuous integration pipelines have
a version string in the format `<build_version>-<build_iteration>`. The
pipelines generally produce three types of packages:

- feature branch builds
- nightly builds
- tagged release builds

NOTE:
The `build_iteration` portion of versions strings conveys a specific meaning
and contributes to how `build_version` is computed. The next sections are
written with that in mind as `build_iteration` must be understood first even
though it comes last in the version string.

### Build Iteration

Version strings use `build_iteration` when packaging related logic changes
that do not contain changes to bundled components.

|Release Type|Example Pipelines|`build_iteration` String|
|-|-|-|
|non-tagged|feature branches, nightly builds|`0`|
|tagged|releases|`(ce|ee).<OMNIBUS_RELEASE>`|

The edition component, **ce** or **ee**, instructs package managers such as
`apt` or `yum` to treat Enteprise Edition packages as an upgrade from
Community Edition when the package version is the same because **ee** is
sorted lexographically after **ce**.

The `OMNIBUS_RELEASE` component is deprecated and always set to `0`.
Historically, `OMNIBUS_RELEASE` indicated quick bug fixes targeting
`omnibus-gitlab` with no changes in GitLab Rails or other bundled
components. The updates frequently required Semantic Version updates because
of user impact. For this reason, `OMNIBUS_RELEASE` was not useful in
practice and is no longer relevant.

### Build version

The build version component of the version string changes based on whether
the package is a [a feature branch](#regular-feature-branch-builds),
[a nightly build](#nightly-builds), or a [tagged release](#tagged-release-builds).

#### Regular feature branch builds

For regular feature branch builds, the version format is
`<latest stable git tag>+rfbranch.<pipeline id>.<omnibus-gitlab SHA>-<build iteration>`.

As noted above, `build iteration` for regular feature branch builds is set to
`0`. An example version string of this type is
`13.1.1+rfbranch.159743.eb538eaf-0`.

The `+rfbranch` string denotes the package as built from a regular feature
branch build. It also lexographically places it after a stable branch
causing package managers such as `apt` or `yum` to view it as an upgrade
from a stable release package.

#### Nightly builds

For nightly packages , the version format is
`<latest stable git tag>+rnightly.<pipeline id>.<omnibus-gitlab SHA>-<build iteration>`.

As noted above, `build iteration` for nightly builds is set to `0`. An example
version string of this type is `13.1.1+rnightly.159756.b2b5f05e-0`.

The `+rnightly` denotes the package as the output from a nightly build. When
compared alphabetically by package managers, `+rnightly` is considered
greater than both the latest stable and the `+rfbranch` packages. Package
managers will always treat a nightly package as a package upgrade.

#### Tagged release builds

For tagged release builds, while the Git tags are of the format
`<SemVer version>+<build iteration>`, the version strings follow the format of
`<SemVer version>-<build iteration>`.

For example, if the tags are `13.1.0+rc42.ce.0`, `13.1.0+ce.0`, and
`13.1.0+ee.0`, the version strings will be `13.1.0-rc42.ee.0`, `13.1.0-ce.0`,
and `13.1.0-ee.0` respectively.

As noted above, unlike feature branch and nightly builds, the `build iteration`
component of these releases are of the format `(ce|ee).0`

## Docker images

Docker images created by `omnibus-gitlab` CI pipelines are based on the Ubuntu
package built in the previous stage. Hence, the Docker image tag also reflects
the same information given by the package version string. Because `+` symbol
used in package versions is not a supported character for image tags, it is
replaced with a `-` to get a slug.

As a general rule, Docker images will use a slug of the package version as tags.
Also, all Docker images will be pushed to Docker container registries
corresponding to the host where they are being built.

The entire image reference will be of the form

```plaintext
dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-(ce|ee):<slug of package version>
```

For example,
`dev.gitlab.org:5005/gitlab/omnibus-gitlab/gitlab-ce:13.2.1-rfbranch.163015.32ed1c58-0`
will be the image tag for a Docker built from a GitLab CE package with version
`13.2.1+rfbranch.163015.32ed1c58-0`

The special cases that deviate from this general rule is listed below.

### Triggered builds in [QA mirror](https://gitlab.com/gitlab-org/build/omnibus-gitlab-mirror)

Docker images created as part of triggered pipeline (for Package and QA run) has
their tag decided depending on where the trigger originated. If the trigger
originated from an `omnibus-gitlab` pipeline, the image tag is the slug of the
package version. But, if the trigger originated from a GitLab or GitLab-FOSS
pipeline, the image tag will be set to the SHA of the commit corresponding to
that pipeline.

These jobs are not published to Dockerhub repository.

### Nightly builds

In addition to the general naming scheme, Docker images built by scheduled
nightly pipelines gets tagged with the `nightly` tag and both tags are pushed to
the Dockerhub repository also.

`gitlab/gitlab-ee:nightly` and `gitlab/gitlab-ce:nightly` denote image
references for the two editions available.

## Tagged release builds

In addition to the general naming scheme, Docker images built by tagged release
pipelines also gets tagged as `latest` and both tags are pushed to the Dockerhub
repository also.
