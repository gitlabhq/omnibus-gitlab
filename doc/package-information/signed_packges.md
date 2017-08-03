# Package Signatures

As of the release of GitLab 9.5 on August 22, 2017, GitLab will provide signed Omnibus GitLab packages for RPM and DEB based distributions. This means that all packages provided on [packages.gitlab.com](https://packages.gitlab.com) will be signed, starting with `9.5.0`, and all future versions of supported branches (e.g. `9.3.x` and `9.4.x` after August 22, 2017).

Omnibus GitLab packages produced by GitLab are created via the [Omnibus](https://github.com/chef/omnibus) tool, for which GitLab has added DEB signing via `debsigs` in [our own fork](https://gitlab.com/gitlab-org/omnibus). This addition, combined with the existing functionality of RPM signing, allows GitLab to provide signed packages for all supported distributions using DEB or RPM.

These packages are produced by the GitLab CI process, as found in the  [omnibus-gitlab project](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.gitlab-ci.yml), prior to their delivery to [packages.gitlab.com][packages] to ensure provide assurance that the packages are not altered prior to delivery to our community.

## GnuPG Public Keys
All packages are signed with [GnuPG](https://www.gnupg.org/), in a method appropriate for their format. The key used to sign these packages can be found on [pgp.mit.edu](https://pgp.mit.edu) at [0x3cfcf9baf27eab47](https://pgp.mit.edu/pks/lookup?op=vindex&search=0x3CFCF9BAF27EAB47)

## Verifying Signatures

Information on how to verify GitLab package signatures can be found in [Package Signatures](../update/package_signatures.md) under [Updating GitLab via omnibus-gitlab](../update/)


[packages]: https://packages.gitlab.com
