# GitLab 7 specific changes

## Updating from GitLab `6.6` and higher to `7.10` or newer

In the 7.10 package we have added the `gitlab-ctl upgrade` command, and we
configured the packages to run this command automatically after the new package
is installed. If you are installing GitLab 7.9 or earlier, please check the
[different procedure](gitlab_6_changes.md#updating-from-gitlab-66-and-higher-to-the-latest-version).

If you installed using the package server all you need to do is run `sudo apt-get update && sudo apt-get install gitlab-ce` (for Debian/Ubuntu) or `sudo yum install gitlab-ce` (for CentOS/Enterprise Linux).

If you are not using the package server, consider [upgrading to the package repository](https://about.gitlab.com/upgrade-to-package-repository/). Otherwise, download the latest [CE](https://packages.gitlab.com/gitlab/gitlab-ce) or
[EE (subscribers only)](https://packages.gitlab.com/gitlab/gitlab-ee)
package to your GitLab server then all you have to do is `dpkg -i gitlab-ce-XXX.deb` (for Debian/Ubuntu) or `rpm
-Uvh gitlab-ce-XXX.rpm` (for CentOS/Enterprise Linux). After the package has
been unpacked, GitLab will automatically:

- Stop all GitLab services;
- Create a backup using your current, old GitLab version. This is a 'light'
  backup that **only backs up the SQL database**;
- Run `gitlab-ctl reconfigure`, which will perform any necessary database
  migrations (using the new GitLab version);
- Restart the services that were running when the upgrade script was invoked.

If you do not want the DB-only backup, automatic start/stop and DB migrations
to be performed automatically please run the following command before upgrading
your GitLab instance:

```sh
sudo touch /etc/gitlab/skip-auto-reconfigure
```

Alternatively if you just want to prevent DB migrations add `gitlab_rails['auto_migrate'] = false`
to your `gitlab.rb` file.
