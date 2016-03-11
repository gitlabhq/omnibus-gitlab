These are the contributing guidelines for omnibus-gitlab issues and merge
requests.

## General guidelines

If you are experiencing problems during GitLab package installation or have issues with package configuration please create an issue that includes the following:

- Include the omnibus-gitlab version when discussing behavior: `dpkg-query -W
  gitlab` or `rpm -q gitlab`.
- Include the omnibus-gitlab configuration: `sudo gitlab-ctl show-config`
- Copy few lines before, full error output and few lines after from the `gitlab-ctl reconfigure` run log and paste it inside a [GitLab snippet](https://gitlab.com/snippets) or inside the issue description under triple backticks "```".

*Warning* Be careful when pasting log outputs of `gitlab-ctl reconfigure` or `gitlab-ctl show-config`; They will contain secrets like passwords and keys so *make sure to edit out all secrets before pasting the log output*.

#### For problems not related to package installation and configuration check ways to get help [at GitLab website.](https://about.gitlab.com/getting-help/)

This can be the case when installation and `gitlab-ctl reconfigure` run went without issues but your GitLab instance is still giving 500 error page with an error in the log.

## Merge request guidelines

- Please add a CHANGELOG entry for your contribution
- Have a look at the [development tips and tricks](doc/development/README.md)


## Maintainer documentation

### Issue description templates

Issue description template will show this message to
all users that create issues in this repository:

```
When submitting an issue that is not a feature request, please submit the following:

1. Make sure that the issue is with the package itself. If your GitLab is running but you are seeing error page 500, first check https://about.gitlab.com/getting-help/ on where to ask your question
1. Include the omnibus-gitlab package version with: dpkg-query -W
gitlab or rpm -q gitlab
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
