---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Add support for a new operating system
---

Adding support for a new operating system (OS) version in `omnibus-gitlab` requires
changes across three separate repositories. Complete the steps in order, because
each step depends on the previous one.

For related context, see the [Distribution team Tips and Tricks issue 451](https://gitlab.com/gitlab-org/distribution/team-tasks/-/work_items/451).

To remove support for an OS, see
[Deprecate and remove support for a supported operating system](deprecating-and-removing-support-for-an-os.md).

## Overview

The three repositories involved are:

1. [`gl-infra/pulp-resources-automation`](https://gitlab.com/gitlab-com/gl-infra/pulp-resources-automation) —
   configures the Pulp package repository infrastructure.
1. [`gitlab-org/gitlab-omnibus-builder`](https://gitlab.com/gitlab-org/gitlab-omnibus-builder) —
   contains the Docker builder images used to compile packages.
1. [`gitlab-org/omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab) —
   contains the CI jobs that build and release packages.

## Step 1: Add OS repos to Pulp

Open a merge request in [`gl-infra/pulp-resources-automation`](https://gitlab.com/gitlab-com/gl-infra/pulp-resources-automation)
to register the new OS package repositories in the Pulp configuration.

For an example, see [merge request 49](https://gitlab.com/gitlab-com/gl-infra/pulp-resources-automation/-/merge_requests/49),
which added Ubuntu 26.04 (Resolute) repos.

### What to change

Add the new OS to the YAML configuration files that define which upstream
package repositories Pulp mirrors. Each entry typically requires:

- Name.
- Path.
- Architectures.

### Who reviews

The Pulp merge request is reviewed by the GitLab Build team. Coordinate
with them early, because this step can take time to merge and propagate.

> [!note]
> You can open this merge request in parallel with Step 2. Both steps are
> independent of each other, but both must be complete before Step 3.

## Step 2: Create builder images

Open a merge request in [`gitlab-org/gitlab-omnibus-builder`](https://gitlab.com/gitlab-org/gitlab-omnibus-builder)
to add a new Docker builder image for the OS.

For an example, see [merge request 483](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/merge_requests/483),
which added the Ubuntu 26 builder image and CI jobs.

### Dockerfile location and naming

Builder images follow a consistent naming convention. For a new OS named
`<os>` at version `<version>`:

- AMD64 Dockerfile: `docker/Dockerfile_<os>_<version>.erb`
- ARM64 Dockerfile: `docker/Dockerfile_<os>_<version>_arm64.erb`

For example, for Ubuntu 26.04:

- `docker/Dockerfile_ubuntu_26.04.erb`
- `docker/Dockerfile_ubuntu_26.04_arm64.erb`

Base the new Dockerfile on the closest existing version for the same OS family.
Update the `FROM` base image, package repository URLs, and any version-specific
package names.

### CI job naming

CI jobs in `gitlab-omnibus-builder` build and publish the images. Follow the
existing naming pattern:

- `ubuntu_26.04 test` — AMD64 build job (branch pipelines).
- `ubuntu_26.04_arm64 test` — ARM64 build job (branch pipelines).
- `ubuntu_26.04` — AMD64 build job (tag/release pipelines).
- `ubuntu_26.04_arm64` — ARM64 build job (tag/release pipelines).

The image tags pushed to the registry use the format:
`<registry>/<os>_<version>:<revision>` and
`<registry>/<os>_<version>_arm64:<revision>`.

### AMD64 and ARM64 matrix

Add CI jobs for both architectures when the OS supports them. Some OS versions
may not have ARM64 support initially. In that case, add only the AMD64 job and
note the limitation in the merge request.

### Who reviews

The `gitlab-omnibus-builder` merge request is reviewed by the GitLab Build
team. The builder image must be merged and the new image revision published
before the `omnibus-gitlab` CI jobs can successfully build packages.

## Step 3: Add CI jobs to `omnibus-gitlab`

Open a merge request in [`gitlab-org/omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab)
to wire up build, check, and release CI jobs for the new OS.

For an example, see [merge request 9405](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9405),
which added Ubuntu 26.04 (Resolute) support.

### Add the codename mapping

For Debian-based systems, add the version-to-codename mapping in
[`lib/gitlab/ohai_helper.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/lib/gitlab/ohai_helper.rb). Find the appropriate `get_<os>_version` method
and add a new `when` clause:

```ruby
def get_ubuntu_version
  case ohai['platform_version']
  # ... existing entries ...
  when /^26\.04/
    'resolute'
  end
end
```

This mapping is used to construct package repository paths and artifact
directory names.

### Add branch pipeline jobs

In `gitlab-ci-config/dev-gitlab-org.yml`, add branch build jobs in the
**Branch pipeline** section. Follow the naming pattern `<OS>-<Version>-branch`
and `<OS>-<Version>-arm64-branch`:

```yaml
Ubuntu-26.04-branch:
  image: "${BUILDER_IMAGE_REGISTRY}/ubuntu_26.04:${BUILDER_IMAGE_REVISION}"
  extends: .branch_template
  rules:
    - !reference [.default_rules, rules]
    - if: '$PIPELINE_TYPE =~ /(NIGHTLY|BRANCH|INTERNAL_RELEASE)_BUILD_PIPELINE$/'
    - if: '$PIPELINE_TYPE =~ /TRIGGERED_(CE|EE)_PIPELINE/'
    - if: '$PIPELINE_TYPE == "TRIGGER_CACHE_UPDATE_PIPELINE"'

Ubuntu-26.04-arm64-branch:
  image: "${BUILDER_IMAGE_REGISTRY}/ubuntu_26.04_arm64:${BUILDER_IMAGE_REVISION}"
  extends: .arm64_branch_template
  rules:
    - !reference [.default_rules, rules]
    - if: '$PIPELINE_TYPE =~ /_(NIGHTLY|BRANCH)_BUILD_PIPELINE$/'
    - if: '$PIPELINE_TYPE =~ /TRIGGERED_(CE|EE)_PIPELINE/'
    - if: '$PIPELINE_TYPE == "TRIGGER_CACHE_UPDATE_PIPELINE"'
```

### Add tag (release) pipeline jobs

In the **Release pipeline** section of `gitlab-ci-config/dev-gitlab-org.yml`,
add tag build jobs and staging upload jobs:

```yaml
Ubuntu-26.04:
  image: "${BUILDER_IMAGE_REGISTRY}/ubuntu_26.04:${BUILDER_IMAGE_REVISION}"
  stage: package
  extends: .tag_template

Ubuntu-26.04-arm64:
  image: "${BUILDER_IMAGE_REGISTRY}/ubuntu_26.04_arm64:${BUILDER_IMAGE_REVISION}"
  stage: package
  extends: .arm64_tag_template

Ubuntu-26.04-staging:
  extends: .staging_upload_template
  needs:
    - job: Ubuntu-26.04
      optional: true
    - job: Ubuntu-26.04-branch
      optional: true
  rules:
    - !reference [.default_rules, rules]
    - if: '$PIPELINE_TYPE =~ /(_RC|_TAG|NIGHTLY|INTERNAL_RELEASE)_BUILD_PIPELINE$/'

Ubuntu-26.04-arm64-staging:
  extends: .staging_upload_template
  needs:
    - job: Ubuntu-26.04-arm64
      optional: true
    - job: Ubuntu-26.04-arm64-branch
      optional: true
  rules:
    - !reference [.default_rules, rules]
    - if: '$PIPELINE_TYPE =~ /(_RC|_TAG|NIGHTLY)_BUILD_PIPELINE$/'

Ubuntu-26.04-release:
  extends: .production_release_template
  needs:
    - job: Ubuntu-26.04-staging

Ubuntu-26.04-arm64-release:
  extends: .production_release_template
  needs:
    - job: Ubuntu-26.04-arm64-staging
```

### Add package check jobs

In `gitlab-ci-config/check-packages.yml`, add install-check jobs that verify
the built package installs correctly. For Debian-based systems, extend
`.apt-install` and `.apt-arm-install`:

```yaml
Ubuntu-26.04-check:
  image: "${BUILDER_IMAGE_REGISTRY}/ubuntu_26.04:${BUILDER_IMAGE_REVISION}"
  extends: .apt-install

Ubuntu-26.04-arm64-check:
  image: "${BUILDER_IMAGE_REGISTRY}/ubuntu_26.04_arm64:${BUILDER_IMAGE_REVISION}"
  extends: .apt-arm-install
```

For RPM-based systems, extend `.yum-install` or `.zypper-install` as appropriate.

### Validate the pipeline

Before the builder image merge request is merged, you can test the `omnibus-gitlab`
CI jobs by overriding the builder image CI variables in your branch pipeline:

- `BUILDER_IMAGE_REGISTRY` - append `/staging` to the existing value in the
  [`gitlab-ci-config/variables.yml`](../../gitlab-ci-config/variables.yml) file. Do
  the same for `DEV_BUILDER_IMAGE_REGISTRY` and `PUBLIC_BUILDER_IMAGE_REGISTRY`
  variables as well.
- `BUILDER_IMAGE_REVISION` — set to the slug of the branch in `gitlab-omnibus-builder`.

After the builder image is merged and published with a new revision, update
`BUILDER_IMAGE_REVISION` in the `omnibus-gitlab` project CI variables or confirm
the pipeline picks up the new image automatically.

Push the `omnibus-gitlab` branch to [`dev.gitlab.org`](https://dev.gitlab.org/gitlab/omnibus-gitlab)
to confirm that branch builds work end-to-end before merging.
