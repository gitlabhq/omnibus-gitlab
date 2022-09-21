---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Deprecating and removing support for a supported operating system

GitLab provides Omnibus packages for operating systems only until their EOL
(End-Of-Life). After the EOL date of the OS, GitLab stops releasing official
packages. This documentation acts as a guideline for the process involved in
deprecating and removing support for an operating system, and how to communicate
it to relevant stakeholders, both internal and external to the company.

## Checking for upcoming EOL dates for supported operating systems

Slack reminders are configured to remind Distribution team's Slack channel on
the first day of every quarter to check EOL dates of various supported
operating systems. Known EOL dates and links to find out the unknown ones are
linked from [the deprecated OSs page](https://docs.gitlab.com/ee/administration/package_information/supported_os.html).

## Informing users of the deprecation and upcoming removal of support

Once an OS is found to reach EOL in the upcoming quarter, open an issue to
discuss the deprecation/removal timeline for it. Validation should be done to
ensure we can provide a path forward for users who might be affected by this -
this generally involves ensuring we can build packages for the next version of
the OS and that our package repository provider, Packagecloud, supports packages
for the new version.

Once the decision has been made to deprecate support for an OS, it should be
communicated to users via multiple avenues, including but not limited to:

1. In the next and following GitLab release blog posts, until removal.
1. At the end of `gitlab-ctl reconfigure` run.

For adding the deprecation notice to the blog post, ping the Distribution team PM in
the issue to open up necessary MRs in the website repo.

For adding a deprecation notice to the end of `gitlab-ctl reconfigure` output, add
the OS information to [`OmnibusHelper#deprecated_os_list`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/e0fbef119bdcfccc488713c68c9e076c1a592412/files/gitlab-cookbooks/package/libraries/omnibus_helper.rb#L133)
method.

## Informing other internal stakeholders about the deprecation and upcoming removal of support

It is also important other teams, who work closely with customers, are also
aware of the deprecation and upcoming removal of support. For this, announce the
deprecation in the following Slack channels:

1. `#support_self_managed` - Support team catering to our self-managed customers
1. `#customer-success` - Customer Success team of our Sales division

## Removing support for an operating system

Once the EOL date of the operating system have passed, open an MR to the
`omnibus-gitlab` project removing CI jobs corresponding to the operating system
from the CI configuration - this involves both spec jobs that are run in the
[development repository](https://gitlab.com/gitlab-org/omnibus-gitlab) as well
as package build and release jobs that are run in the
[Release mirror](https://dev.gitlab.org/gitlab/omnibus-gitlab).

Similar to deprecation, ensure to ping the PM and other necessary Slack channels
to inform every stakeholder is aware of the removal.

After the last version which supported the OS is out of the maintenance window,
open an MR to remove the builder image from the
[Omnibus Builder](https://gitlab.com/gitlab-org/gitlab-omnibus-builder)
project.
