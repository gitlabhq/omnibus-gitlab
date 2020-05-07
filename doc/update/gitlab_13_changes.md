# GitLab 13 specific changes

NOTE: **Note**
When upgrading to a new major version, remember to first [check for background migrations](https://docs.gitlab.com/ee/update/README.html#checking-for-background-migrations-before-upgrading).

## Puma becoming default web server instead of Unicorn

Starting with GitLab 13.0, Puma will be the default web server used in
`omnibus-gitlab` based installations. This will be the case for both fresh
installations as well as upgrades, unless [users have explicitly disabled Puma
and enabled Unicorn](../settings/unicorn.md#enabling-unicorn). Users who have
Unicorn configuration are recommended to refer to [the docs on how to convert them to Puma ones](../settings/puma.md#converting-unicorn-settings-to-puma).
