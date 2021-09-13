---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Update GitLab installed with the Omnibus GitLab package **(FREE SELF)**

Before following these instructions, note the following:

- [Supported upgrade paths](https://docs.gitlab.com/ee/update/index.html#upgrade-paths)
  has suggestions on when to upgrade.
- If you are upgrading from a non-Omnibus installation to an Omnibus installation, see
  [Upgrading from a non-Omnibus installation to an Omnibus installation](convert_to_omnibus.md).

WARNING:
If you aren't [using the current major version](#mandatory-upgrade-paths-for-version-upgrades),
you **must** follow the
[supported upgrade paths](https://docs.gitlab.com/ee/update/index.html#upgrade-paths)
when updating to the current version.

## Background migrations

WARNING:
It's important to ensure that any background migrations have been fully completed
before upgrading to a new major version. Upgrading before background migrations have
finished may lead to data corruption.

To see the current size of the `background_migration` queue,
[check for background migrations before upgrading](https://docs.gitlab.com/ee/update/index.html#checking-for-background-migrations-before-upgrading).

## Version-specific changes

We recommend performing upgrades between major and minor releases no more than once per
week, to allow time for background migrations to finish. Decrease the time required to
complete these migrations by increasing the number of
[Sidekiq workers](https://docs.gitlab.com/ee/administration/operations/extra_sidekiq_processes.html)
that can process jobs in the `background_migration` queue.

Updating to major versions might need some manual intervention. For more information,
check the version your are updating to:

- [GitLab 14](gitlab_14_changes.md)
- [GitLab 13](gitlab_13_changes.md)
- [GitLab 12](gitlab_12_changes.md)
- [GitLab 11](gitlab_11_changes.md)

## Mandatory upgrade paths for version upgrades

From GitLab 10.8, upgrade paths are enforced for version upgrades by
default. This restricts performing direct upgrades that skip major versions (for
example 10.3 to 12.7 in one jump) that **can break GitLab
installations** due to multiple reasons like deprecated or removed configuration
settings, upgrade of internal tools and libraries, and so on. Users must follow
the [official upgrade paths](https://docs.gitlab.com/ee/update/index.html#upgrade-paths)
while upgrading their GitLab instances.

## Updating methods

There are two ways to update Omnibus GitLab:

- [Using the official repositories](#update-using-the-official-repositories).
- [Using a manually-downloaded package](#update-using-a-manually-downloaded-package).

Both will automatically back up the GitLab database before installing a newer
GitLab version. You may skip this automatic backup by creating an empty file
at `/etc/gitlab/skip-auto-backup`:

```shell
sudo touch /etc/gitlab/skip-auto-backup
```

For safety reasons, you should maintain an up-to-date backup on your own if you plan to use this flag.

When upgrading to a new major version, remember to first [check for background migrations](https://docs.gitlab.com/ee/update/index.html#checking-for-background-migrations-before-upgrading).

Unless you are following the steps in [Zero downtime upgrades](https://docs.gitlab.com/ee/update/zero_downtime.html), your GitLab application will not be available to users while an update is in progress. They will either see a "Deploy in progress" message or a "502" error in their web browser.

### Update using the official repositories

If you have installed Omnibus GitLab [Community Edition](https://about.gitlab.com/install/?version=ce)
or [Enterprise Edition](https://about.gitlab.com/install/), then the
official GitLab repository should have already been set up for you.

To update to the newest GitLab version, run:

- For GitLab [Enterprise Edition](https://about.gitlab.com/pricing/):

  ```shell
  # Debian/Ubuntu
  sudo apt-get update
  sudo apt-get install gitlab-ee

  # Centos/RHEL
  sudo yum install gitlab-ee
  ```

- For GitLab Community Edition:

  ```shell
  # Debian/Ubuntu
  sudo apt-get update
  sudo apt-get install gitlab-ce

  # Centos/RHEL
  sudo yum install gitlab-ce
  ```

#### Multi-step upgrade using the official repositories

Linux package managers default to installing the latest available version of a
package for installation and upgrades. Upgrading directly to the latest major
version can be problematic for older GitLab versions that require a multi-stage
upgrade path.

When following an [upgrade path](https://docs.gitlab.com/ee/update/index.html#upgrade-paths)
spanning multiple versions, for each upgrade, specify the intended GitLab version
number in your package manager's install or upgrade command:

1. First, identify the GitLab version number in your package manager:

   ```shell
   # Ubuntu/Debian
   sudo apt-cache madison gitlab-ee
   # RHEL/CentOS 6 and 7
   yum --showduplicates list gitlab-ee
   # RHEL/CentOS 8
   dnf search gitlab-ee*
   ```

1. Then install the specific GitLab package:

   ```shell
   # Ubuntu/Debian
   sudo apt install gitlab-ee=12.0.12-ee.0
   # RHEL/CentOS 6 and 7
   yum install gitlab-ee-12.0.12-ee.0.el7
   # RHEL/CentOS 8
   dnf install gitlab-ee-12.0.12-ee.0.el8
   # SUSE
   zypper install gitlab-ee=12.0.12-ee.0
   ```

### Update using a manually-downloaded package

If for some reason you don't use the official repositories, you can
[download the package and install it manually](../manual_install.md).

## Update Community Edition to Enterprise Edition

To upgrade an existing GitLab Community Edition (CE) server installed using the Omnibus GitLab
packages to GitLab [Enterprise Edition](https://about.gitlab.com/pricing/) (EE), you install the EE
package on top of CE.

Upgrading from the same version of CE to EE is not explicitly necessary, and any standard upgrade
(for example, CE 12.0 to EE 12.1) should work. However, in the following steps we assume that
you are upgrading the same version (for example, CE 12.1 to EE 12.1), which is **recommended**.

WARNING:
When updating to EE from CE, avoid reverting back to CE if you plan on going to EE again in the
future. Reverting back to CE can cause
[database issues](#500-error-when-accessing-project--settings--repository-on-omnibus-installs)
that may require Support intervention.

The steps can be summed up to:

1. Find the currently installed GitLab version:

   **For Debian/Ubuntu**

   ```shell
   sudo apt-cache policy gitlab-ce | grep Installed
   ```

   The output should be similar to: `Installed: 13.0.4-ce.0`. In that case,
   the equivalent Enterprise Edition version will be: `13.0.4-ee.0`. Write this
   value down.

   **For CentOS/RHEL**

   ```shell
   sudo rpm -q gitlab-ce
   ```

   The output should be similar to: `gitlab-ce-13.0.4-ce.0.el8.x86_64`. In that
   case, the equivalent Enterprise Edition version will be:
   `gitlab-ee-13.0.4-ee.0.el8.x86_64`. Write this value down.

1. Add the `gitlab-ee` [Apt or Yum repository](https://packages.gitlab.com/gitlab/gitlab-ee/install):

   **For Debian/Ubuntu**

   ```shell
   curl -s "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh" | sudo bash
   ```

   **For CentOS/RHEL**

   ```shell
   curl -s "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
   ```

   The above command will find your OS version and automatically set up the
   repository. If you are not comfortable installing the repository through a
   piped script, you can first
   [check its contents](https://packages.gitlab.com/gitlab/gitlab-ee/install).

1. Next, install the `gitlab-ee` package. Note that this will automatically
   uninstall the `gitlab-ce` package on your GitLab server. `reconfigure`
   Omnibus right after the `gitlab-ee` package is installed. **Make sure that you
   install the exact same GitLab version**:

   **For Debian/Ubuntu**

   ```shell
   ## Make sure the repositories are up-to-date
   sudo apt-get update

   ## Install the package using the version you wrote down from step 1
   sudo apt-get install gitlab-ee=13.0.4-ee.0

   ## Reconfigure GitLab
   sudo gitlab-ctl reconfigure
   ```

   **For CentOS/RHEL**

   ```shell
   ## Install the package using the version you wrote down from step 1
   sudo yum install gitlab-ee-13.0.4-ee.0.el8.x86_64

   ## Reconfigure GitLab
   sudo gitlab-ctl reconfigure
   ```

1. Now go to the GitLab admin panel of your server (`/admin/license/new`) and
   upload your license file.

1. After you confirm that GitLab is working as expected, you may remove the old
   Community Edition repository:

   **For Debian/Ubuntu**

   ```shell
   sudo rm /etc/apt/sources.list.d/gitlab_gitlab-ce.list
   ```

   **For CentOS/RHEL**

   ```shell
   sudo rm /etc/yum.repos.d/gitlab_gitlab-ce.repo
   ```

That's it! You can now use GitLab Enterprise Edition! To update to a newer
version, follow [Update using the official repositories](#update-using-the-official-repositories).

NOTE:
If you want to use `dpkg`/`rpm` instead of `apt-get`/`yum`, go through the first
step to find the current GitLab version and then follow
[Update using a manually-downloaded package](#update-using-a-manually-downloaded-package).

## Zero downtime updates

Read how to perform [zero downtime upgrades](https://docs.gitlab.com/ee/update/zero_downtime.html).

## Upgrade Gitaly servers

Gitaly servers must be upgraded to the newer version prior to upgrading the application server.
This prevents the gRPC client on the application server from sending RPCs that the old Gitaly version
does not support.

## Downgrade

This section contains general information on how to revert to an earlier version
of a package.

WARNING:
You must at least have a database backup created under the version you are
downgrading to. Ideally, you should have a
[full backup archive](https://docs.gitlab.com/ee/raketasks/backup_restore.html#back-up-gitlab)
on hand.

The example below demonstrates the downgrade procedure when downgrading between minor
and patch versions (for example, from 13.0.6 to 13.0.5).

When downgrading between major versions, take into account the
[specific version changes](#version-specific-changes) that occurred when you upgraded
to the major version you are downgrading from.

These steps consist of:

- Stopping GitLab
- Removing the current package
- Installing the old package
- Reconfiguring GitLab
- Restoring the backup
- Starting GitLab

Steps:

1. Stop GitLab and remove the current package:

   ```shell
   # If running Puma
   sudo gitlab-ctl stop puma

   # Stop sidekiq
   sudo gitlab-ctl stop sidekiq

   # If on Ubuntu: remove the current package
   sudo dpkg -r gitlab-ee

   # If on Centos: remove the current package
   sudo yum remove gitlab-ee
   ```

1. Identify the GitLab version you want to downgrade to:

   ```shell
   # (Replace with gitlab-ce if you have GitLab FOSS installed)

   # Ubuntu
   sudo apt-cache madison gitlab-ee

   # CentOS:
   sudo yum --showduplicates list gitlab-ee
   ```

1. Downgrade GitLab to the desired version (for example, to GitLab 13.0.5):

   ```shell
   # (Replace with gitlab-ce if you have GitLab FOSS installed)

   # Ubuntu
   sudo apt install gitlab-ee=13.0.5-ee.0

   # CentOS:
   sudo yum install gitlab-ee-13.0.5-ee.0.el8
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Follow the instructions in the [Restore for Omnibus GitLab installations](https://docs.gitlab.com/ee/raketasks/backup_restore.html#restore-for-omnibus-gitlab-installations)
page to complete the downgrade.

## Troubleshooting

### GitLab 13.7 and later unavailable on Amazon Linux 2

Amazon Linux 2 is not an [officially supported operating system](../package-information/deprecated_os.md#supported-operating-systems).
However, in past the [official package installation script](https://packages.gitlab.com/gitlab/gitlab-ee/install)
installed the `el/6` package repository if run on Amazon Linux. From GitLab 13.7, we no longer
provide `el/6` packages so administrators must run the [installation script](https://packages.gitlab.com/gitlab/gitlab-ee/install)
again to update the repository to `el/7`:

```shell
curl -s "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
```

See the [epic on support for GitLab on Amazon Linux 2](https://gitlab.com/groups/gitlab-org/-/epics/2195) for the latest details on official Amazon Linux 2 support.

### Get the status of a GitLab installation

```shell
sudo gitlab-ctl status
sudo gitlab-rake gitlab:check SANITIZE=true
```

- Information on using `gitlab-ctl` to perform [maintenance tasks](../maintenance/index.md).
- Information on using `gitlab-rake` to [check the configuration](https://docs.gitlab.com/ee/administration/raketasks/maintenance.html#check-gitlab-configuration).

### RPM 'package is already installed' error

If you are using RPM and you are upgrading from GitLab Community Edition to GitLab Enterprise Edition you may get an error like this:

```shell
package gitlab-7.5.2_omnibus.5.2.1.ci-1.el7.x86_64 (which is newer than gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64) is already installed
```

You can override this version check with the `--oldpackage` option:

```shell
sudo rpm -Uvh --oldpackage gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm
```

### Package obsoleted by installed package

CE and EE packages are marked as obsoleting and replacing each other so that both aren't installed and running at the same time.

If you are using local RPM files to switch from CE to EE or vice versa, use `rpm` for installing the package rather than `yum`. If you try to use yum, then you may get an error like this:

```plaintext
Cannot install package gitlab-ee-11.8.3-ee.0.el6.x86_64. It is obsoleted by installed package gitlab-ce-11.8.3-ce.0.el6.x86_64
```

To avoid this issue, either:

- Use the same instructions provided in the
  [Update using a manually-downloaded package](#update-using-a-manually-downloaded-package) section.
- Temporarily disable obsoletion checking in yum by adding `--setopt=obsoletes=0` to the options given to the command.

### 500 error when accessing Project > Settings > Repository on Omnibus installs

In situations where a GitLab instance has been migrated from CE > EE > CE and then back to EE, some Omnibus installations get the below error when viewing a projects repository settings.

```shell
Processing by Projects::Settings::RepositoryController#show as HTML
  Parameters: {"namespace_id"=>"<namespace_id>", "project_id"=>"<project_id>"}
Completed 500 Internal Server Error in 62ms (ActiveRecord: 4.7ms | Elasticsearch: 0.0ms | Allocations: 14583)

NoMethodError (undefined method `commit_message_negative_regex' for #<PushRule:0x00007fbddf4229b8>
Did you mean?  commit_message_regex_change):
```

This error is caused by an EE feature being added to a CE instance on the initial move to EE.
Once the instance is moved back to CE then is upgraded to EE again, the `push_rules` table already exists in the database and a migration is unable to add the `commit_message_regex_change` column.

This results in the [backport migration of EE tables](https://gitlab.com/gitlab-org/gitlab/-/blob/cf00e431024018ddd82158f8a9210f113d0f4dbc/db/migrate/20190402150158_backport_enterprise_schema.rb#L1619) not working correctly.
The backport migration assumes that certain tables in the database do not exist when running CE.

To fix this issue, manually add the missing `commit_message_negative_regex` column and restart GitLab:

```shell
# Access psql
sudo gitlab-rails dbconsole

# Add the missing column
ALTER TABLE push_rules ADD COLUMN commit_message_negative_regex VARCHAR;

# Exit psql
\q

# Restart GitLab
sudo gitlab-ctl restart
```

### Error `Failed to connect to the internal GitLab API` on a separate GitLab Pages server

Please see [GitLab Pages troubleshooting](https://docs.gitlab.com/ee/administration/pages/index.html#failed-to-connect-to-the-internal-gitlab-api).
