---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Deprecate and remove support for a supported operating system

GitLab provides Omnibus packages for operating systems (OS) only until their end of life (EOL).
After the EOL date of the OS, GitLab stops releasing official
packages. The following content documents how to:

- Deprecate and remove support for an OS.
- Communicate this information to internal and external stakeholders.

## Check for upcoming EOL dates for supported OS

Check [supported operating systems](https://docs.gitlab.com/ee/administration/package_information/supported_os.html)
to see EOL dates for supported OS.

Slack reminders to check the EOL dates are sent to the Distribution team's Slack
channel on the first day of every quarter.

## Tell users of the deprecation and upcoming removal of support

If you find an OS has an EOL date in the upcoming quarter, open an issue to
discuss the deprecation and removal timeline. We provide a path forward for users
who are affected by this by making sure:

- We can build packages for the next version of the OS.
- Our package repository provider, [Packagecloud](https://packagecloud.io/),
  supports packages for the new version.

After we decide to deprecate support for an OS, we tell affected users
through appropriate channels, including:

- In the next and following GitLab release blog posts, until removal.
- At the end of `gitlab-ctl reconfigure` run.

To add the deprecation notice to the blog post, message the Distribution team PM
in the issue to open necessary merge requests in the website repository.

To add deprecation notice to the end of `gitlab-ctl reconfigure` output, add
the OS information to the [`OmnibusHelper#deprecated_os_list`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/e0fbef119bdcfccc488713c68c9e076c1a592412/files/gitlab-cookbooks/package/libraries/omnibus_helper.rb#L133).

## Tell other internal stakeholders about the deprecation and upcoming removal of support

You must tell customer-facing teams about the deprecation and upcoming removal
of support for the OS. Announce the deprecation in the following Slack channels:

1. `#support_self_managed` - Support team catering to our self-managed customers.
1. `#customer-success` - Customer Success team of our Sales division.

## Remove support for an OS

When the OS EOL date has passed, open an merge request to the `omnibus-gitlab` project to
remove CI/CD jobs for that OS from the CI/CD configuration. These jobs include:

- Spec jobs that run in the
[development repository](https://gitlab.com/gitlab-org/omnibus-gitlab)
- Package build and release jobs that run in the
[Release mirror](https://dev.gitlab.org/gitlab/omnibus-gitlab).

Message the PM and all other necessary Slack channels to tell every stakeholder
about the removal of support.

When the last version which supported the OS is out of the maintenance window,
open an merge request to remove the builder image from the
[Omnibus Builder](https://gitlab.com/gitlab-org/gitlab-omnibus-builder)
project.
