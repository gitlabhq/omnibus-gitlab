---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Upgrading software components

The Linux package is created from a series of software components, some of which
are developed by GitLab and others which are sourced from free and open source
projects. Software components can be updated individually as new features, bug
fixes, and security vulnerabilities become available.

Software component upgrades can be risky, especially when non-backwards
compatible changes are made. Considering [Semantic versioning](https://semver.org/)], examining changelogs, and examining release
notes can give a sense of the amount of risk involved in an upgrade. In all
cases, upgrades should be thoroughly tested before merging.

The [CNG](https://gitlab.com/gitlab-org/build/CNG) project uses some of these
same software components. Components common to both projects should be updated
in both.

## Types of software components

There are two types of software components used in the Linux package:

- External software components
- Internal software components

### External software components

External software components source is downloaded directly from an external site
or copied from the
[`omnibus-mirror`](https://gitlab.com/gitlab-org/build/omnibus-mirror) repository.
A component can be provided using a `git clone`, extracting from a source
tarball, performing a `gem install` (for Ruby modules), or performing a `pip
install` (for Python modules).

### Internal software components

Internal software component are developed by GitLab and external contributors.
Source for internal software components is downloaded from a project's GitLab
repository. Versions used in a build are set by the Git reference contained in
the project's corresponding `*VERSION` files. These versions can be overridden
by environment variables. For more information, see
[Use specific branches or versions of a GitLab component](../build/team_member_docs.md#use-specific-branches-or-versions-of-a-gitlab-component).

Updates to internal software components are done by merge requests in the
corresponding repository.

## Internal software component update workflow

A typical workflow for updating an internal software component.

### Create a fork/branch

External contributors should create a fork of the
[`gitlab-org/omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab) repository.

Create a new branch from the target branch (usually `master` of the
[`gitlab-org/omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab) repository.

### Modify `config/software/<component.rb>`

1. Find the corresponding configure file for the component that you want to
 update in the `config/software` directory. For example
 `config/software/prometheus.rb` is used for the Prometheus component.

1. Change the version to the version you want to update to. If applicable, also
change the corresponding `sha256` to the value of the corresponding version
source tarball.

### Add or modify any required patches

The new component version may require:

- Adding new patches.
- Removing existing patches.
- Changing existing patches.

All patch files go in `config/patches/<component name>`. They are then
referenced in the corresponding `config/software/<component name>.rb` file.
Examples can be found at:

- [unzip component](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/config/software/unzip.rb)
- [unzip patches](https://gitlab.com/gitlab-org/omnibus-gitlab/-/tree/master/config/patches/unzip).

### Push branch

Push the branch to the to the upstream repository.

### Create merge request (MR)

Create a merge request using your development branch and the target branch.

### Build

Build the Linux package either:

- Using the CI/CD system.
- Building locally using [Build local Linux package](../build/build_package.md).

You must build on all architectures using the CI/CD system before a merge
request for an updated software component can be accepted.

### Test

Install the resulting Linux package and test the component changes.

## Testing software component updates

### Minimum test requirements

At a minimum, the following tests should be performed when updating a software
component.

- Perform a successful GitLab Enterprise Edition (EE) build on all supported platforms.
- Run `qa-test` CI/CD test job for both GitLab Enterprise Edition and GitLab Community Edition.
- Install and verify that component version has been upgraded.
- Verify basic functionality of the software component.

Additional testing is almost always required and varies depending on the
software component.

### Test plans

Here are test plans for individual components. They are meant to be copied into
the merge request where their execution can be recorded.

Not every component is listed here. Please consider creating a merge request to
add one for a component upgrade that you are working on. Use
`test-plans/upgrade-component-testplan-template.md` as a starting point.

These test plans are not exhaustive. The might need to be supplemented depending
on the degree of change made to the component. Record these additions in the
merge request and consider adding them here. Use the following filename pattern
when creating the test plan file:

```plaintext
upgrade-<component-name>-testplan.md
```

And add a link in `test-plans/index.md`.
