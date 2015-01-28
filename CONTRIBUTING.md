These are the contributing guidelines for omnibus-gitlab issues and merge
requests.

## General guidelines

If you are experiencing problems during GitLab package installation or have issues with package configuration please create an issue that includes the following:

- Include the omnibus-gitlab version when discussing behavior: `dpkg-query -W
  gitlab` or `rpm -q gitlab`.
- Be careful when pasting log output of `gitlab-ctl reconfigure`; Chef happily
  writes secrets to the log.

#### For problems not related to package installation and configuration check ways to get help [at GitLab website.](https://about.gitlab.com/getting-help/)

## Merge request guidelines

- Please add a CHANGELOG entry for your contribution
- Have a look at the [development tips and tricks](doc/development.md)
