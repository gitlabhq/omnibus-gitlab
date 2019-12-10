## Contributing

Thank you for your interest in contributing to this GitLab project! We welcome
all contributions. By participating in this project, you agree to abide by the
[code of conduct](#code-of-conduct).

## Developer Certificate of Origin + License

By contributing to GitLab B.V., You accept and agree to the following terms and
conditions for Your present and future Contributions submitted to GitLab B.V.
Except for the license granted herein to GitLab B.V. and recipients of software
distributed by GitLab B.V., You reserve all right, title, and interest in and to
Your Contributions. All Contributions are subject to the following DCO + License
terms.

[DCO + License](https://gitlab.com/gitlab-org/dco/blob/master/README.md)

All Documentation content that resides under the [doc/ directory](/doc) of this
repository is licensed under Creative Commons:
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

_This notice should stay as the first item in the CONTRIBUTING.md file._

## Definition of done

The omnibus-gitlab project uses the [definition of done as noted in GitLab Community Edition (and Enterprise Edition)](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/doc/development/contributing/merge_request_workflow.md#definition-of-done).

As this project is a wrapper around GitLab CE/EE, some additions to the definition apply:

1. Integration tests using [GitLab QA](https://gitlab.com/gitlab-org/gitlab-qa).
1. Green pipelines in both [gitlab.com pipelines](https://gitlab.com/gitlab-org/omnibus-gitlab/pipelines) (Specs) and
[dev.gitlab.org pipelines](https://dev.gitlab.org/gitlab/omnibus-gitlab/pipelines) (Package builds). This rule is at minimum applicable to the reviewers.


## General issue guidelines

If you are experiencing problems during GitLab package installation or have issues with package configuration please create an issue that includes the following:

- Include the omnibus-gitlab version when discussing behavior: `dpkg-query -W "gitlab*"` or `rpm -q gitlab`.
- Include the omnibus-gitlab configuration: `sudo gitlab-ctl show-config`
- Copy few lines before, full error output and few lines after from the `gitlab-ctl reconfigure` run log and paste it inside a [GitLab snippet](https://gitlab.com/snippets) or inside the issue description under triple backticks "``` TEXT ```".

*Warning* Be careful when pasting log outputs of `gitlab-ctl reconfigure` or `gitlab-ctl show-config`; They will contain secrets like passwords and keys so *make sure to edit out all secrets before pasting the log output*.

#### For problems not related to package installation and configuration check ways to get help [at GitLab website.](https://about.gitlab.com/getting-help/)

This can be the case when installation and `gitlab-ctl reconfigure` run went without issues but your GitLab instance is still giving 500 error page with an error in the log.

## I want to contribute!

If you want to contribute to GitLab Omnibus, issues with both the ~Accepting merge requests and ~For Scheduling labels
are issues that have been triaged as areas where where we are looking for contributors to help us out.

See the [contributor issue issues list](https://gitlab.com/gitlab-org/omnibus-gitlab/issues?state=opened&label_name[]=Accepting%20merge%20requests&label_name[]=For%20Scheduling).

If you have any questions or need help visit [Getting Help](https://about.gitlab.com/getting-help/#discussion) to
learn how to communicate with GitLab. If you're looking for a Gitter or Slack channel
please consider we favor
[asynchronous communication](https://about.gitlab.com/handbook/communication/#internal-communication) over real time communication. Thanks for your contribution!

## Maintainer documentation

Maintainers of this project will try to address issues in a timely manner.
Maintainers, however, cannot guarantee that they would be able to address
all incoming issues as soon as they are raised nor can guarantee to provide an
answer to all raised issues.

If your issue is closed due to inactivity (from either side), please check
whether the issue persists in the latest version. If that is the case, feel free
to reopen the issue or create a new one with a link to the old issue.

### Issue description templates

Issue description template will show this message to
all users that create issues in this repository:

```
When submitting an issue that is not a feature request, please submit the following:

1. Make sure that the issue is with the package itself. If your GitLab is running but you are seeing error page 500, first check https://about.gitlab.com/getting-help/ on where to ask your question
1. Include the omnibus-gitlab package version with: `dpkg-query -W
gitlab` or `rpm -q gitlab`
1. Relevant sections of `/etc/gitlab/gitlab.rb` (make sure to omit any sections that start with # and passwords)
1. Whether the problems are caused on a fresh install or an upgrade(Describe the upgrade history)
1. Describe the OS and the system environment GitLab is installed on (Is it a clean VM, is anything else running on it, etc.)
```

### Issue response template

When the maintainer suspects the reported issue is not related to the problems with omnibus-gitlab, following template can be used to respond to the issue reporter:

```
Thanks for reporting this issue. I suspect that the issue you are experiencing is not related to the package or configuration of the package itself. Omnibus-gitlab repository is used for packaging GitLab. Since this looks like a problem not related to the packaging please check
[how to get help](https://about.gitlab.com/getting-help/) for your issue. I will close this issue but if you still think this is a problem with the package please @ mention me with the steps to reproduce the problem and I will reopen the issue.
```

### Closing issues

If an issue has a `Awaiting Feedback` label and the response from the reporter
has not been received for 14 days, we can close the issue using the following
response template:

```
We haven't received an update for more than 14 days so we will assume that the
problem is fixed or is no longer valid. If you still experience the same problem
try upgrading to the latest version. If the issue persists, reopen this issue
with the relevant information.
```

### Hand testing built packages

Once you have a have a green pipeline for the package build as discussed in the
[Definition of done](#definition-of-done), deploy the package to a VM and ensure
that everything still works.

Some of the interactions of the components are not fully covered by the
unit/acceptance tests, so testing here can reveal issues such as invalid service
configuration being generated.  Issues found should be fed back into the test
suites where possible as part of the review process.

### Reviewing Merge Requests

Before merging, a MR must be reviewed by a [GitLab Omnibus Maintainer](https://about.gitlab.com/handbook/engineering/projects/#omnibus-gitlab).
If the change is not time-sensitive, then the MR can first be reviewed by any other
[Distribution Team Member](https://about.gitlab.com/handbook/engineering/development/enablement/distribution/#team-members),
then finally reviewed by a Maintainer.

Reviews generally only need the *approval* of one Maintainer to be merged, but
additional Maintainers may be involved with reviewing parts of the change. We will
try to avoid having more than one Maintainer do a full review.

**When the change was unscheduled, and requires notifying users**

The [Distribution Engineering Manager](https://about.gitlab.com/company/team/#maxlazio)
need to provide approval if the change is for an unscheduled issue, and makes a
user-facing change that needs mentioning in the release post.

**Other changes**

As long as one of the Maintainers is confident in the change, it does not need to
be reviewed again before merge.

> **Note**: This process is intended to balance code quality with effective use of reviewers' time. Just because a change was approved and merged by one Maintainer, does not guarantee that it won't be reverted later.

## Developer Guidelines

### Developer Documentation

See the [developer documentation](doc/development/README.md) for additional information.

#### Setting up development environment

See the [developer documentation](doc/development/README.md#setting-up-development-environment)

#### Understanding the architecture

See the [developer documentation](doc/development/README.md#understanding-the-architecture)

### Writing tests

See the [developer documentation](doc/development/README.md#writing tests)

### Merge Request Guidelines

See the [developer documentation](doc/development/README.md#merge-request-guidelines)

## Unofficial packaging point of contact

The omnibus-gitlab project is a project used for building official GitLab packages.
There are multiple community driven projects for packaging, such as [GitLab CE unofficial Debian 9](https://packages.debian.org/stretch/gitlab) package.

If you are a maintainer or point of contact for a such project, and you require
assistance or just want to talk about GitLab, please raise [an issue in the omnibus-gitlab project](https://gitlab.com/gitlab-org/omnibus-gitlab/issues).

## Code of conduct

As contributors and maintainers of this project, we pledge to respect all people
who contribute through reporting issues, posting feature requests, updating
documentation, submitting pull requests or patches, and other activities.

We are committed to making participation in this project a harassment-free
experience for everyone, regardless of level of experience, gender, gender
identity and expression, sexual orientation, disability, personal appearance,
body size, race, ethnicity, age, or religion.

Examples of unacceptable behavior by participants include the use of sexual
language or imagery, derogatory comments or personal attacks, trolling, public
or private harassment, insults, or other unprofessional conduct.

Project maintainers have the right and responsibility to remove, edit, or reject
comments, commits, code, wiki edits, issues, and other contributions that are
not aligned to this Code of Conduct. Project maintainers who do not follow the
Code of Conduct may be removed from the project team.

This code of conduct applies both within project spaces and in public spaces
when an individual is representing the project or its community.

Instances of abusive, harassing, or otherwise unacceptable behavior can be
reported by emailing contact@gitlab.com.

This Code of Conduct is adapted from the [Contributor Covenant][contributor-covenant], version 1.1.0,
available at [http://contributor-covenant.org/version/1/1/0/](http://contributor-covenant.org/version/1/1/0/).

[contributor-covenant]: http://contributor-covenant.org
