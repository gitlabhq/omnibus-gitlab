# Updating GitLab installed with the omnibus-gitlab package

See our page on [Upgrade Recommendations](https://docs.gitlab.com/ee/policy/maintenance.html#upgrade-recommendations) for suggestions on when to upgrade

See our page on upgrading from a non-Omnibus installation [to an Omnibus installation](convert-to-omnibus.md)

## Updating methods
### Updating using the official repositories

If you have installed Omnibus GitLab [Community Edition](https://about.gitlab.com/installation/?version=ce#)
or [Enterprise Edition](https://about.gitlab.com/installation), then the
official GitLab repository should have already been set up for you.

To update to a newer GitLab version, all you have to do is:

```
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install gitlab-ce

# Centos/RHEL
sudo yum install gitlab-ce
```

If you are an Enterprise Edition user, replace `gitlab-ce` with `gitlab-ee` in
the above commands.

### Updating manually installed package

If for some reason you don't use the official repositories, it is possible to
download the package and install it manually.

1. Visit the [Community Edition repository](https://packages.gitlab.com/gitlab/gitlab-ce)
   or the [Enterprise Edition repository](https://packages.gitlab.com/gitlab/gitlab-ee)
   depending on the edition you already have installed.
1. Find the package version you wish to install and click on it.
1. Click the 'Download' button in the upper right corner to download the package.
1. Once the GitLab package is downloaded, install it using the following
   commands, replacing `XXX` with the Omnibus GitLab version you downloaded:

    ```
    # Debian/Ubuntu
    dpkg -i gitlab-ce-XXX.deb

    # CentOS/RHEL
    rpm -Uvh gitlab-ce-XXX.rpm
    ```

    If you are an Enterprise Edition user, replace `gitlab-ce` with `gitlab-ee`
    in the above commands.

## Updating Community Edition to Enterprise Edition

To upgrade an existing GitLab Community Edition (CE) server, installed using the
Omnibus packages, to GitLab Enterprise Edition (EE), all you have to do is
install the EE package on top of CE. While upgrading from the same version of
CE to EE is not explicitly necessary, and any standard upgrade jump (i.e. 8.0
to 8.7) should work, in the following steps we assume that you are upgrading the
same versions.

The steps can be summed up to:

1. Find the currently installed GitLab version:

    **For Debian/Ubuntu**

    ```
    sudo apt-cache policy gitlab-ce | grep Installed
    ```

    The output should be similar to: `Installed: 8.6.7-ce.0`. In that case,
    the equivalent Enterprise Edition version will be: `8.6.7-ee.0`. Write this
    value down.

    ---

    **For CentOS/RHEL**

    ```
    sudo rpm -q gitlab-ce
    ```

    The output should be similar to: `gitlab-ce-8.6.7-ce.0.el7.x86_64`. In that
    case, the equivalent Enterprise Edition version will be:
    `gitlab-ee-8.6.7-ee.0.el7.x86_64`. Write this value down.

1. Add the `gitlab-ee` [Apt or Yum repository](https://packages.gitlab.com/gitlab/gitlab-ee/install):

    **For Debian/Ubuntu**

    ```
    curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
    ```

    **For CentOS/RHEL**

    ```
    curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash
    ```

    ---

    The above command will find your OS version and automatically set up the
    repository. If you are not comfortable installing the repository through a
    piped script, you can first
    [check its contents](https://packages.gitlab.com/gitlab/gitlab-ee/install).

1. Next, install the `gitlab-ee` package. Note that this will automatically
   uninstall the `gitlab-ce` package on your GitLab server. Reconfigure
   Omnibus right after the `gitlab-ee` package is installed. Make sure that you
   install the exact same GitLab version:

    **For Debian/Ubuntu**

    ```
    ## Make sure the repositories are up-to-date
    sudo apt-get update

    ## Install the package using the version you wrote down from step 1
    sudo apt-get install gitlab-ee=8.6.7-ee.0

    ## Reconfigure GitLab
    sudo gitlab-ctl reconfigure
    ```

    **For CentOS/RHEL**

    ```
    ## Install the package using the version you wrote down from step 1
    sudo yum install gitlab-ee-8.6.7-ee.0.el7.x86_64

    ## Reconfigure GitLab
    sudo gitlab-ctl reconfigure
    ```

    > **Note:**
    If you want to upgrade to EE and at the same time also update GitLab to the
    latest version, you can omit the version check in the above commands. For
    Debian/Ubuntu that would be `sudo apt-get install gitlab-ee` and for
    CentOS/RHEL `sudo yum install gitlab-ee`.

1. Now go to the GitLab admin panel of your server (`/admin/license/new`) and
   upload your license file.

1. After you confirm that GitLab is working as expected, you may remove the old
   Community Edition repository:

    **For Debian/Ubuntu**

    ```
    sudo rm /etc/apt/sources.list.d/gitlab_gitlab-ce.list
    ```

    ---

    **For CentOS/RHEL**

    ```
    sudo rm /etc/yum.repos.d/gitlab_gitlab-ce.repo
    ```

That's it! You can now use GitLab Enterprise Edition! To update to a newer
version follow the section on
[Updating using the official repositories](#updating-using-the-official-repositories).

>**Note:**
If you want to use `dpkg`/`rpm` instead of `apt-get`/`yum`, go through the first
step to find the current GitLab version and then follow the steps in
[Updating by manually downloading the official packages](#updating-by-manually-downloading-the-official-packages).

## Zero downtime updates

**Note:** This is only available in GitLab 9.1.0 or newer

It's possible to upgrade to a newer version of
GitLab without having to take your GitLab instance offline. This can only be
done if you are using PostgreSQL. If you are using MySQL you will still need downtime when upgrading.

Verify that you can upgrade with no downtime by checking the
[Upgrading without downtime section](https://docs.gitlab.com/ee/update/README.html#upgrading-without-downtime) of the update document.

If you meet all the requirements above, follow these instructions:

1. If you have multiple nodes in a highly available/scaled environment, decide
   which node is the `Deploy Node`. On this node create an empty file at
   `/etc/gitlab/skip-auto-reconfigure`. During software installation only, this
   will prevent the upgrade from running `gitlab-ctl reconfigure` and
   automatically running database migrations.
1. On every other node **except** the `Deploy Node` ensure that
   `gitlab_rails['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`.
1. On the `Deploy Node`, update the GitLab package.
1. On the `Deploy Node` run `SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure`
   to get the regular migrations in place.
1. On all other nodes, update the GitLab package and run `gitlab-ctl reconfigure`
   so these nodes get the newest code.
1. Once all nodes are updated, run `gitlab-rake db:migrate` from the `Deploy Node`
   to run post-deployment migrations.


## Version specific changes
### GitLab 10

From version 10.0 GitLab requires the version of PostgreSQL to be 9.6 or
higher.

Check out [docs on upgrading packaged PostgreSQL server](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)
for details.

* For users running versions below 8.15 and using PostgreSQL bundled with
  omnibus, this means they will have to first upgrade to 9.5.x, during which
  PostgreSQL will be automatically updated to 9.6.
* Users who are on versions above 8.15, but chose not to update PostgreSQL
  automatically during previous upgrades, can run the following command to
  update the bundled PostgreSQL to 9.6

  ```
  sudo gitlab-ctl pg-upgrade
  ```

Users can check their PostgreSQL version using the following command
```
/opt/gitlab/embedded/bin/psql --version
```

### GitLab 8

#### Updating from GitLab 8.10 and lower to 8.11 or newer

GitLab 8.11 introduces new key names for several secrets, to match the GitLab
Rails app and clarify the use of the secrets. For most installations, this
process should be transparent as the 8.11 and higher packages will try to
migrate the existing secrets to the new key names.

##### Migrating legacy secrets

These keys have been migrated from old names:

- `gitlab_rails['otp_key_base']` is used for encrypting the OTP secrets in the
  database. Changing this secret will stop two-factor auth from working for all
  users. Previously called `gitlab_rails['secret_token']`
- `gitlab_rails['db_key_base']` is used for encrypting import credentials and CI
  secret variables. Previously called `gitlab_ci['db_key_base']`; **note** that
  `gitlab_rails['db_key_base']` was not previously used for this - setting it
  would have no effect
- `gitlab_rails['secret_key_base']` is used for password reset links, and other
  'standard' auth features. Previously called `gitlab_ci['db_key_base']`;
  **note** that `gitlab_rails['secret_token']` was not previously used for this,
  despite the name

These keys were not used any more, and have simply been removed:

- `gitlab_ci['secret_token']`
- `gitlab_ci['secret_key_base']`

### GitLab 7

#### Updating from GitLab 6.6 and higher to 7.10 or newer

In the 7.10 package we have added the `gitlab-ctl upgrade` command, and we
configured the packages to run this command automatically after the new package
is installed. If you are installing GitLab 7.9 or earlier, please see the
[procedure below](#updating-from-gitlab-66-and-higher-to-the-latest-version).

If you installed using the package server all you need to do is run `sudo apt-get update && sudo apt-get install gitlab-ce` (for Debian/Ubuntu) or `sudo yum install gitlab-ce` (for CentOS/Enterprise Linux).

If you are not using the package server, consider [upgrading to the package repository](https://about.gitlab.com/upgrade-to-package-repository). Otherwise, download the latest [CE](https://packages.gitlab.com/gitlab/gitlab-ce) or
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

```
sudo touch /etc/gitlab/skip-auto-reconfigure
```

Alternatively if you just want to prevent DB migrations add `gitlab_rails['auto_migrate'] = false`
to your `gitlab.rb` file.

### GitLab 6

#### Updating from GitLab 6.6 and higher to the latest version

The procedure can also be used to upgrade from a CE omnibus package to an EE omnibus package.

First, download the latest [CE](https://packages.gitlab.com/gitlab/gitlab-ce) or
[EE (license key required)](https://about.gitlab.com/downloads-ee/)
package to your GitLab server.

##### Stop services but leave postgresql running for the database migrations and create a backup

```shell
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq
sudo gitlab-ctl stop nginx
sudo gitlab-rake gitlab:backup:create
```

##### Install the latest package

```
# Debian/Ubuntu:
sudo dpkg -i gitlab_x.x.x-omnibus.xxx.deb

# CentOS:
sudo rpm -Uvh gitlab-x.x.x_xxx.rpm
```

##### Reconfigure GitLab (includes running database migrations) and restart all services

```
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
```

Done!

### Updating from GitLab 6.6.0.pre1 to 6.6.4

First, download the latest package from https://www.gitlab.com/downloads/ to your GitLab server.


##### Stop unicorn and sidekiq so we can do database migrations

```shell
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq
```

##### One-time migration because we changed some directories since 6.6.0.pre1

```
sudo mkdir -p /var/opt/gitlab/git-data
sudo mv /var/opt/gitlab/{repositories,gitlab-satellites} /var/opt/gitlab/git-data/
sudo mv /var/opt/gitlab/uploads /var/opt/gitlab/gitlab-rails/
```

##### Install the latest package

```
# Ubuntu:
sudo dpkg -i gitlab_6.6.4-omnibus.xxx.deb

# CentOS:
sudo rpm -Uvh gitlab-6.6.4_xxx.rpm
```

##### Reconfigure GitLab (includes database migrations)

```
sudo gitlab-ctl reconfigure
```

##### Start unicorn and sidekiq

```
sudo gitlab-ctl start
```

Done!


## Downgrading

This section contains general information on how to revert to an earlier version of a package.

*NOTE* This guide assumes that you have a backup archive created under the version you are reverting to.

These steps consist of:

* Download the package of a target version.(example below uses GitLab 6.x.x)
* Stop GitLab
* Install the old package
* Reconfigure GitLab
* Restoring the backup
* Starting GitLab

See example below:

First download a GitLab 6.x.x [CE](https://www.gitlab.com/downloads/archives/) or
[EE (subscribers only)](https://gitlab.com/subscribers/gitlab-ee/blob/master/doc/install/packages.md)
package.


### Stop GitLab

```
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq
```

### Downgrade GitLab to 6.x

```
# Ubuntu
sudo dpkg -r gitlab
sudo dpkg -i gitlab-6.x.x-yyy.deb

# CentOS:
sudo rpm -e gitlab
sudo rpm -ivh gitlab-6.x.x-yyy.rpm
```

### Prepare GitLab for receiving the backup restore

Due to a backup restore bug in versions earlier than GitLab 6.8.0, it is needed to drop the database
_before_ running `gitlab-ctl reconfigure`, only if you are downgrading to 6.7.x or less.

```
sudo -u gitlab-psql /opt/gitlab/embedded/bin/dropdb gitlabhq_production
```

### Reconfigure GitLab (includes database migrations)

```
sudo gitlab-ctl reconfigure
```

### Restore your backup

```
sudo gitlab-rake gitlab:backup:restore BACKUP=12345 # where 12345 is your backup timestamp
```

### Start GitLab

```
sudo gitlab-ctl start
```

### Updating GitLab CI via omnibus-gitlab

#### Updating from GitLab CI version prior to 5.4.0 to version 7.14

>**Warning:**
Omnibus GitLab 7.14 was the last version where CI was bundled in the package.
Starting from GitLab 8.0, CI was merged into GitLab, thus it's no longer a
separate application included in the Omnibus package.

In GitLab CI 5.4.0 we changed the way GitLab CI authorizes with GitLab.

In order to use GitLab CI 5.4.x, GitLab 7.7.x is required.

Make sure that GitLab 7.7.x is installed and running and then go to Admin section of GitLab.
Under Applications create a new a application which will generate the `app_id` and `app_secret`.

In `/etc/gitlab/gitlab.rb`:

```
gitlab_ci['gitlab_server'] = { "url" => 'http://gitlab.example.com', "app_id" => '12345678', "app_secret" => 'QWERTY12345' }

```

where `url` is the url to the GitLab instance.

Make sure to run `sudo gitlab-ctl reconfigure` after saving the configuration.

## Troubleshooting

### Getting the status of a GitLab installation

```
sudo gitlab-ctl status
sudo gitlab-rake gitlab:check SANITIZE=true
```

+ Information on using `gitlab-ctl` to perform maintenance tasks - [maintenance/README.md.](../maintenance/README.md)
+ Information on using `gitlab-rake` to check the configuration - [Maintenance - Rake tasks](https://docs.gitlab.com/ee/administration/raketasks/maintenance.html#check-gitlab-configuration).

### RPM 'package is already installed' error

If you are using RPM and you are upgrading from GitLab Community Edition to GitLab Enterprise Edition you may get an error like this:

```
package gitlab-7.5.2_omnibus.5.2.1.ci-1.el7.x86_64 (which is newer than gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64) is already installed
```

You can override this version check with the `--oldpackage` option:

```
rpm -Uvh --oldpackage gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm
```


============================================================================
