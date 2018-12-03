# Updating GitLab installed with the Omnibus GitLab package

See the [upgrade recommendations](https://docs.gitlab.com/ee/policy/maintenance.html#upgrade-recommendations)
for suggestions on when to upgrade.
If you are upgrading from a non-Omnibus installation to an Omnibus installation,
[check this guide](convert_to_omnibus.md).

## Version specific changes

Updating to major versions might need some manual intervention. For more info,
check the version your are updating to:

- [GitLab 11](gitlab_11_changes.md)
- [GitLab 10](gitlab_10_changes.md)
- [GitLab 8](gitlab_8_changes.md)
- [GitLab 7](gitlab_7_changes.md)
- [GitLab 6](gitlab_6_changes.md)

## Mandatory upgrade paths for version upgrades

From version 10.8 onwards, upgrade paths are enforced for version upgrades by
default. This restricts performing direct upgrades that skip major versions (for
example 10.3 to 12.7 in one jump) which can result in breakage of the GitLab
installations due to multiple reasons like deprecated or removed configuration
settings, upgrade of internal tools and libraries etc. Users will have to follow
the [official upgrade recommendations](https://docs.gitlab.com/ee/policy/maintenance.html#upgrade-recommendations)
while upgrading their GitLab instances.

## Updating methods

There are two ways to update Omnibus GitLab:

- Using the official repositories
- Manually download the package

### Updating using the official repositories

If you have installed Omnibus GitLab [Community Edition](https://about.gitlab.com/installation/?version=ce#)
or [Enterprise Edition](https://about.gitlab.com/installation), then the
official GitLab repository should have already been set up for you.

To update to a newer GitLab version, all you have to do is:

```sh
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install gitlab-ce

# Centos/RHEL
sudo yum install gitlab-ce
```

If you are an Enterprise Edition user, replace `gitlab-ce` with `gitlab-ee` in
the above commands.

### Updating using a manually downloaded package

If for some reason you don't use the official repositories, it is possible to
download the package and install it manually.

1. Visit the [Community Edition repository](https://packages.gitlab.com/gitlab/gitlab-ce)
   or the [Enterprise Edition repository](https://packages.gitlab.com/gitlab/gitlab-ee)
   depending on the edition you already have installed.
1. Find the package version you wish to install and click on it.
1. Click the 'Download' button in the upper right corner to download the package.
1. Once the GitLab package is downloaded, install it using the following
   commands, replacing `XXX` with the Omnibus GitLab version you downloaded:

    ```sh
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

    ```sh
    sudo apt-cache policy gitlab-ce | grep Installed
    ```

    The output should be similar to: `Installed: 8.6.7-ce.0`. In that case,
    the equivalent Enterprise Edition version will be: `8.6.7-ee.0`. Write this
    value down.

    ---

    **For CentOS/RHEL**

    ```sh
    sudo rpm -q gitlab-ce
    ```

    The output should be similar to: `gitlab-ce-8.6.7-ce.0.el7.x86_64`. In that
    case, the equivalent Enterprise Edition version will be:
    `gitlab-ee-8.6.7-ee.0.el7.x86_64`. Write this value down.

1. Add the `gitlab-ee` [Apt or Yum repository](https://packages.gitlab.com/gitlab/gitlab-ee/install):

    **For Debian/Ubuntu**

    ```sh
    curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
    ```

    **For CentOS/RHEL**

    ```sh
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

    ```sh
    ## Make sure the repositories are up-to-date
    sudo apt-get update

    ## Install the package using the version you wrote down from step 1
    sudo apt-get install gitlab-ee=8.6.7-ee.0

    ## Reconfigure GitLab
    sudo gitlab-ctl reconfigure
    ```

    **For CentOS/RHEL**

    ```sh
    ## Install the package using the version you wrote down from step 1
    sudo yum install gitlab-ee-8.6.7-ee.0.el7.x86_64

    ## Reconfigure GitLab
    sudo gitlab-ctl reconfigure
    ```

    NOTE: **Note:**
    If you want to upgrade to EE and at the same time also update GitLab to the
    latest version, you can omit the version check in the above commands. For
    Debian/Ubuntu that would be `sudo apt-get install gitlab-ee` and for
    CentOS/RHEL `sudo yum install gitlab-ee`.

1. Now go to the GitLab admin panel of your server (`/admin/license/new`) and
   upload your license file.

1. After you confirm that GitLab is working as expected, you may remove the old
   Community Edition repository:

    **For Debian/Ubuntu**

    ```sh
    sudo rm /etc/apt/sources.list.d/gitlab_gitlab-ce.list
    ```

    ---

    **For CentOS/RHEL**

    ```sh
    sudo rm /etc/yum.repos.d/gitlab_gitlab-ce.repo
    ```

That's it! You can now use GitLab Enterprise Edition! To update to a newer
version follow the section on
[Updating using the official repositories](#updating-using-the-official-repositories).

NOTE: **Note:**
If you want to use `dpkg`/`rpm` instead of `apt-get`/`yum`, go through the first
step to find the current GitLab version and then follow the steps in
[Updating by manually downloading the official packages](#updating-by-manually-downloading-the-official-packages).

## Zero downtime updates

NOTE: **Note:**
This is only available in GitLab 9.1.0 or newer. Skipping restarts during reconfigure with `/etc/gitlab/skip-auto-reconfigure` was added in [version 10.6](https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/2270). If running a version prior to 10.6, you will need to create `/etc/gitlab/skip-auto-migrations`.

It's possible to upgrade to a newer version of
GitLab without having to take your GitLab instance offline. This can only be
done if you are using PostgreSQL. If you are using MySQL you will still need downtime when upgrading.

Verify that you can upgrade with no downtime by checking the
[Upgrading without downtime section](https://docs.gitlab.com/ee/update/README.html#upgrading-without-downtime) of the update document.

If you meet all the requirements above, follow these instructions in order. There are three sets of steps, depending on your deployment type:

| Deployment type                              | Description                    |
| -------------------------------------------- | ------------------------------ |
| [Single](#single-deployment)                 | GitLab CE/EE on a single node  |
| [Multi-node / HA](#multi-node-ha-deployment) | GitLab CE/EE on multiple nodes |
| [Geo](#geo-deployment)                       | GitLab EE with Geo enabled     |


## Single deployment

1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
   installation only, this will prevent the upgrade from running
   `gitlab-ctl reconfigure` and automatically running database migrations

    ```sh
    sudo touch /etc/gitlab/skip-auto-reconfigure
    ```

1. Update the GitLab package

    ```sh
    # Debian/Ubuntu
    sudo apt-get update && sudo apt-get install gitlab-ce

    # Centos/RHEL
    sudo yum install gitlab-ce
    ```

    If you are an Enterprise Edition user, replace `gitlab-ce` with `gitlab-ee` in the above command.

1. To get the regular migrations in place, run

    ```sh
    SKIP_POST_DEPLOYMENT_MIGRATIONS=true sudo gitlab-ctl reconfigure
    ```

1. Once the node is updated and reconfigure finished successfully, complete the migrations with

    ```sh
    sudo gitlab-rake db:migrate
    ```

1. Hot reload `unicorn` and `sidekiq` services

    ```sh
    sudo gitlab-ctl hup unicorn
    sudo gitlab-ctl hup sidekiq
    ```


## Multi-node / HA deployment

Pick a node to be the `Deploy Node`.  It can be any node, but it must be the same
node throughout the process.


**Deploy node**

* Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
   installation only, this will prevent the upgrade from running
   `gitlab-ctl reconfigure` and automatically running database migrations

    ```sh
    sudo touch /etc/gitlab/skip-auto-reconfigure
    ```

**All other nodes (not the Deploy node)**

* Ensure that `gitlab_rails['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`

**Deploy node**

* Update the GitLab package

    ```sh
    # Debian/Ubuntu
    sudo apt-get update && sudo apt-get install gitlab-ce

    # Centos/RHEL
    sudo yum install gitlab-ce
    ```

    If you are an Enterprise Edition user, replace `gitlab-ce` with `gitlab-ee` in the above command.

* To get the regular database migrations in place, run

    ```sh
    SKIP_POST_DEPLOYMENT_MIGRATIONS=true sudo gitlab-ctl reconfigure
    ```

**All other nodes (not the Deploy node)**

* Update the GitLab package

    ```sh
    sudo apt-get update && sudo apt-get install gitlab-ce
    ```

    If you are an Enterprise Edition user, replace `gitlab-ce` with `gitlab-ee` in the above command.

* Ensure nodes are running the latest code

    ```sh
    sudo gitlab-ctl reconfigure
    ```

**Deploy node**

* Once all nodes are updated, run the following to run post-deployment database migrations

    ```sh
    sudo gitlab-rake db:migrate
    ```

**For nodes that run unicorn or sidekiq**

* Hot reload `unicorn` and `sidekiq` services

    ```sh
    sudo gitlab-ctl hup unicorn
    sudo gitlab-ctl hup sidekiq
    ```


## Geo deployment

**Primary node**

On the Primary node, executing the following:

1. Ensure that `gitlab_rails['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`

1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
   installation only, this will prevent the upgrade from running
   `gitlab-ctl reconfigure` and automatically running database migrations

    ```sh
    sudo touch /etc/gitlab/skip-auto-reconfigure
    ```

1. Update the GitLab package

    ```sh
    # Debian/Ubuntu
    sudo apt-get update && sudo apt-get install gitlab-ee

    # Centos/RHEL
    sudo yum install gitlab-ee
    ```

1. To get the database migrations in place, run

    ```sh
    SKIP_POST_DEPLOYMENT_MIGRATIONS=true sudo gitlab-ctl reconfigure
    ```

1. Run non post-deployment database migrations

    ```sh
    SKIP_POST_DEPLOYMENT_MIGRATIONS=true sudo gitlab-rake db:migrate
    ```

1. Run post-deployment database migrations

    ```sh
    sudo gitlab-rake db:migrate
    ```

1. Hot reload `unicorn` and `sidekiq` services

    ```sh
    sudo gitlab-ctl hup unicorn
    sudo gitlab-ctl hup sidekiq
    ```

1. Verify Geo configuration and dependencies

    ```sh
    sudo gitlab-rake gitlab:geo:check
    ```

**Secondary node(s)**


NOTE: **Note:**
Only proceed if you have successfully completed all steps on the Primary node.

On all Secondary nodes, executing the following:

1. Ensure that `geo_secondary['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`

1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
   installation only, this will prevent the upgrade from running
   `gitlab-ctl reconfigure` and automatically running database migrations

    ```sh
    sudo touch /etc/gitlab/skip-auto-reconfigure
    ```

1. Update the GitLab package

    ```sh
    # Debian/Ubuntu
    sudo apt-get update && sudo apt-get install gitlab-ee

    # Centos/RHEL
    sudo yum install gitlab-ee
    ```

1. To get the database migrations in place, run

    ```sh
    SKIP_POST_DEPLOYMENT_MIGRATIONS=true sudo gitlab-ctl reconfigure
    ```

1. Run post-deployment database migrations, specific to the Geo database

    ```sh
    sudo gitlab-rake geo:db:migrate
    ```

1. Hot reload `unicorn`, `sidekiq` and restart `geo-logcursor` services

    ```sh
    sudo gitlab-ctl hup unicorn
    sudo gitlab-ctl hup sidekiq
    sudo gitlab-ctl restart geo-logcursor
    ```

1. Verify Geo configuration and dependencies

    ```sh
    sudo gitlab-rake gitlab:geo:check
    ```

1. Verify Geo status

    ```sh
    sudo gitlab-rake geo:status
    ```

## Downgrading

This section contains general information on how to revert to an earlier version
of a package.

NOTE: **Note:**
This guide assumes that you have a backup archive created under the version you
are reverting to.

These steps consist of:

- Download the package of a target version.(example below uses GitLab 6.x.x)
- Stop GitLab
- Install the old package
- Reconfigure GitLab
- Restoring the backup
- Starting GitLab

See example below:

First download a GitLab 6.x.x [CE](https://about.gitlab.com/downloads/archives/) or
[EE (subscribers only)](https://gitlab.com/subscribers/gitlab-ee/blob/master/doc/install/packages.md)
package.

Steps:

1. Stop GitLab:

    ```sh
    sudo gitlab-ctl stop unicorn
    sudo gitlab-ctl stop sidekiq
    ```

1. Downgrade GitLab to 6.x:

    ```sh
    # Ubuntu
    sudo dpkg -r gitlab
    sudo dpkg -i gitlab-6.x.x-yyy.deb

    # CentOS:
    sudo rpm -e gitlab
    sudo rpm -ivh gitlab-6.x.x-yyy.rpm
    ```

1. Prepare GitLab for receiving the backup restore. Due to a backup restore bug
   in versions earlier than GitLab 6.8.0, it is needed to drop the database
   _before_ running `gitlab-ctl reconfigure`, only if you are downgrading to
   6.7.x or less:

    ```sh
    sudo -u gitlab-psql /opt/gitlab/embedded/bin/dropdb gitlabhq_production
    ```

1. Reconfigure GitLab (includes database migrations):

    ```sh
    sudo gitlab-ctl reconfigure
    ```

1. Restore your backup:

    ```sh
    sudo gitlab-rake gitlab:backup:restore BACKUP=12345 # where 12345 is your backup timestamp
    ```

1. Start GitLab:

    ```sh
    sudo gitlab-ctl start
    ```

## Updating GitLab CI from prior `5.4.0` to version `7.14` via Omnibus GitLab

CAUTION: **Warning:**
Omnibus GitLab 7.14 was the last version where CI was bundled in the package.
Starting from GitLab 8.0, CI was merged into GitLab, thus it's no longer a
separate application included in the Omnibus package.

In GitLab CI 5.4.0 we changed the way GitLab CI authorizes with GitLab.

In order to use GitLab CI 5.4.x, GitLab 7.7.x is required.

Make sure that GitLab 7.7.x is installed and running and then go to Admin section of GitLab.
Under Applications create a new a application which will generate the `app_id` and `app_secret`.

In `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_ci['gitlab_server'] = { "url" => 'http://gitlab.example.com', "app_id" => '12345678', "app_secret" => 'QWERTY12345' }
```

Where `url` is the url to the GitLab instance.

Make sure to run `sudo gitlab-ctl reconfigure` after saving the configuration.

## Troubleshooting

### Getting the status of a GitLab installation

```sh
sudo gitlab-ctl status
sudo gitlab-rake gitlab:check SANITIZE=true
```

- Information on using `gitlab-ctl` to perform [maintenance tasks](../maintenance/README.md).
- Information on using `gitlab-rake` to [check the configuration](https://docs.gitlab.com/ee/administration/raketasks/maintenance.html#check-gitlab-configuration).

### RPM 'package is already installed' error

If you are using RPM and you are upgrading from GitLab Community Edition to GitLab Enterprise Edition you may get an error like this:

```sh
package gitlab-7.5.2_omnibus.5.2.1.ci-1.el7.x86_64 (which is newer than gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64) is already installed
```

You can override this version check with the `--oldpackage` option:

```sh
sudo rpm -Uvh --oldpackage gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm
```
