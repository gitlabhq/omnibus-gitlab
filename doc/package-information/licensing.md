# Package Licensing

## License


While GitLab itself is MIT, the omnibus-gitlab sources are licensed under the Apache-2.0.

## License file location

Starting with version 8.11, the omnibus-gitlab package contains license
information of all software that is bundled within the package.

After installing the package, licenses for each individual bundled library
can be be found in `/opt/gitlab/LICENSES` directory.

There is also one `LICENSE` file which contains all licenses compiled together.
This compiled license can be found in `/opt/gitlab/LICENSE` file.


## Checking licenses

The omnibus-gitlab package is made up of many pieces of software, comprising code
that is covered by many different licenses. Those licenses are provided and
compiled as stated above.

Starting with version 8.13, GitLab has placed an additional step into the omnibus-gitlab.
The `license_check` step calls `support/license_check.sh`, which checks the compiled
`LICENSE` file against the current list of approved and questionable licenses as
denoted in the arrays at the top of the script. This script will output one of
`Good`, `Unknown` or `Check` for each piece of software that is a part of the
omnibus-gitlab package.

- `Good`: denotes a license that is approved for all usage types, within GitLab and
omnibus-gitlab.
- `Unknown`: denotes a license that is not recognized in the list of 'good' or 'bad',
which should be immediately reviewed for implications of use.
- `Check`: denotes a license that has the potential be incompatible with GitLab itself,
and thus should be checked for how it is used as a part of the omnibus-gitlab package
to ensure compliance.

This list is currently sourced from the [GitLab development documenation on licensing]
(https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/development/licensing.md).
However, due to the nature of the omnibus-gitlab package the licenses may not apply
in the same way. Such as with `git` and `rsync`. See the [GNU License FAQ]
(https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation)
