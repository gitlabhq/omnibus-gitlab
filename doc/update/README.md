# Updating GitLab installed with the Omnibus GitLab package

See the [upgrade recommendations](https://docs.gitlab.com/ee/policy/maintenance.html#upgrade-recommendations)
for suggestions on when to upgrade.
If you are upgrading from a non-Omnibus installation to an Omnibus installation,
[check this guide](convert_to_omnibus.md).

## Version specific changes

It's important to ensure that any background migrations have been fully completed
before upgrading to a new major version. To see the current size of the `background_migration` queue,
[check for background migrations before upgrading](https://docs.gitlab.com/ee/update/README.html#checking-for-background-migrations-before-upgrading).

Updating to major versions might need some manual intervention. For more info,
check the version your are updating to:

- [GitLab 12](gitlab_12_changes.md)
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

Both will automatically back up the GitLab database before installing a newer
GitLab version. You may skip this automatic backup by creating an empty file
at `/etc/gitlab/skip-auto-backup`:

```sh
sudo touch /etc/gitlab/skip-auto-backup
```

NOTE: **Note:**
For safety reasons, you should maintain an up-to-date backup on your own if you plan to use this flag.

NOTE: **Note**
When upgrading to a new major version, remember to first [check for background migrations](https://docs.gitlab.com/ee/update/README.html#checking-for-background-migrations-before-upgrading).

### Updating using the official repositories

If you have installed Omnibus GitLab [Community Edition](https://about.gitlab.com/install/?version=ce)
or [Enterprise Edition](https://about.gitlab.com/install/), then the
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

   The above command will find your OS version and automatically set up the
   repository. If you are not comfortable installing the repository through a
   piped script, you can first
   [check its contents](https://packages.gitlab.com/gitlab/gitlab-ee/install).

1. Next, install the `gitlab-ee` package. Note that this will automatically
   uninstall the `gitlab-ce` package on your GitLab server. `reconfigure`
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
[Updating using a manually downloaded package](#updating-using-a-manually-downloaded-package).

## Zero downtime updates

NOTE: **Note:**
This is only available in GitLab 9.1.0 or newer. Skipping restarts during `reconfigure` with `/etc/gitlab/skip-auto-reconfigure` was added in [version 10.6](https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/2270). If running a version prior to 10.6, you will need to create `/etc/gitlab/skip-auto-migrations`.

It's possible to upgrade to a newer version of GitLab without having to take
your GitLab instance offline.

Verify that you can upgrade with no downtime by checking the
[Upgrading without downtime section](https://docs.gitlab.com/ee/update/README.html#upgrading-without-downtime) of the update document.

If you meet all the requirements above, follow these instructions in order. There are three sets of steps, depending on your deployment type:

| Deployment type                                                 | Description                                       |
| --------------------------------------------------------------- | ------------------------------------------------  |
| [Single](#single-deployment)                                    | GitLab CE/EE on a single node                     |
| [Multi-node / PG HA](#using-postgresql-ha)                      | GitLab CE/EE using HA architecture for PostgreSQL |
| [Multi-node / Redis HA](#using-redis-ha-using-sentinel)         | GitLab CE/EE using HA architecture for Redis      |
| [Geo](#geo-deployment)                                          | GitLab EE with Geo enabled                        |
| [Multi-node / HA with Geo](#multi-node--ha-deployment-with-geo) | GitLab CE/EE on multiple nodes                    |

### Single deployment

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

1. To get the regular migrations and latest code in place, run

   ```sh
   sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
   ```

1. Once the node is updated and `reconfigure` finished successfully, complete the migrations with

   ```sh
   sudo gitlab-rake db:migrate
   ```

1. Hot reload `unicorn`, `puma` and `sidekiq` services

   ```sh
   sudo gitlab-ctl hup unicorn
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   ```

NOTE: **Note:**
If you do not want to run zero downtime upgrades in the future, make
sure you remove `/etc/gitlab/skip-auto-reconfigure` after
you've completed these steps.

### Multi-node / HA deployment

#### Using PostgreSQL HA

Pick a node to be the `Deploy Node`.  It can be any node, but it must be the same
node throughout the process.

**Deploy node**

- Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
  installation only, this will prevent the upgrade from running
  `gitlab-ctl reconfigure` and automatically running database migrations

  ```sh
  sudo touch /etc/gitlab/skip-auto-reconfigure
  ```

**All nodes (including the Deploy node)**

- Ensure that `gitlab_rails['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`

**Gitaly only nodes**

- Update the GitLab package

  ```sh
  # Debian/Ubuntu
  sudo apt-get update && sudo apt-get install gitlab-ce

  # Centos/RHEL
  sudo yum install gitlab-ce
  ```

  If you are an Enterprise Edition user, replace `gitlab-ce` with `gitlab-ee` in the above command.

- Ensure nodes are running the latest code

  ```sh
  sudo gitlab-ctl reconfigure
  ```

**Deploy node**

- Update the GitLab package

  ```sh
  # Debian/Ubuntu
  sudo apt-get update && sudo apt-get install gitlab-ce

  # Centos/RHEL
  sudo yum install gitlab-ce
  ```

  If you are an Enterprise Edition user, replace `gitlab-ce` with `gitlab-ee` in the above command.

- If you're using PgBouncer:

  You'll need to bypass PgBouncer and connect directly to the database master
  before running migrations.

  Rails uses an advisory lock when attempting to run a migration to prevent
  concurrent migrations from running on the same database. These locks are
  not shared across transactions, resulting in `ActiveRecord::ConcurrentMigrationError`
  and other issues when running database migrations using PgBouncer in transaction
  pooling mode.

  To find the master node, run the following on a database node:

  ```sh
  sudo gitlab-ctl repmgr cluster show
  ```

  Then, in your `gitlab.rb` file on the deploy node, update
  `gitlab_rails['db_host']` and `gitlab_rails['db_port']` with the database
  master's host and port.

- To get the regular database migrations and latest code in place, run

  ```sh
  sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
  ```

**All other nodes (not the Deploy node)**

- Update the GitLab package

  ```sh
  sudo apt-get update && sudo apt-get install gitlab-ce
  ```

  If you are an Enterprise Edition user, replace `gitlab-ce` with `gitlab-ee` in the above command.

- Ensure nodes are running the latest code

  ```sh
  sudo gitlab-ctl reconfigure
  ```

**Deploy node**

- Run post-deployment database migrations on deploy node to complete the migrations with

  ```sh
  sudo gitlab-rake db:migrate
  ```

**For nodes that run Unicorn, Puma or Sidekiq**

- Hot reload `unicorn`, `puma` and `sidekiq` services

  ```sh
  sudo gitlab-ctl hup unicorn
  sudo gitlab-ctl hup puma
  sudo gitlab-ctl restart sidekiq
  ```

- If you're using PgBouncer:

  Change your `gitlab.rb` to point back to PgBouncer and run:

  ```sh
  sudo gitlab-ctl reconfigure
  ```

NOTE: **Note:**
If you do not want to run zero downtime upgrades in the future, make
sure you remove `/etc/gitlab/skip-auto-reconfigure` and revert
setting `gitlab_rails['auto_migrate'] = false` in
`/etc/gitlab/gitlab.rb` after you've completed these steps.

#### Using Redis HA (using Sentinel)

Package upgrades may involve version updates to the bundled Redis service. On
instances using [Redis HA](https://docs.gitlab.com/ee/administration/high_availability/redis.html),
upgrades must follow a proper order to ensure minimum downtime, as specified
below. This doc assumes the official guides are being followed to setup Redis
HA.

##### In the application node

According to [official Redis docs](https://redis.io/topics/admin#upgrading-or-restarting-a-redis-instance-without-downtime),
the easiest way to update an HA instance using Sentinel is to upgrade the
secondaries one after the other, performa a manual failover from current
primary (running old version) to a recently upgraded secondary (running a new
version), and then upgrade the original primary. For this, we need to know
the address of the current Redis primary.

- If your application node is running GitLab 12.7.0 or later, you can use the
following command to get address of current Redis primary

  ```
  sudo gitlab-ctl get-redis-master
  ```

- If your application node is running a version older than GitLab 12.7.0, you
  will have to run the underlying `redis-cli` command (which `get-redis-master`
  command uses) to fetch information about the primary.

    1. Get the address of one of the sentinel nodes specified as
       `gitlab_rails['redis_sentinels']` in `/etc/gitlab/gitlab.rb`

    1. Get the Redis master name specified as `redis['master_name']` in
       `/etc/gitlab/gitlab.rb`

    1. Run the following command

        ```
        sudo /opt/gitlab/embedded/bin/redis-cli -h <sentinel host> -p <sentinel port> SENTINEL get-master-addr-by-name <redis master name>
        ```

##### In the Redis secondary nodes

1. Install package for new version.

1. Run `sudo gitlab-ctl reconfigure`, if a reconfigure is not run as part of
   installation (due to `/etc/gitlab/skip-auto-reconfigure` file being present).

1. If reconfigure warns about a pending Redis/Sentinel restart, restart the
   corresponding service

   ```
   sudo gitlab-ctl restart redis
   sudo gitlab-ctl restart sentinel
   ```

##### In the Redis primary node

Before upgrading the Redis primary node, we need to perform a failover so that
one of the recently upgraded secondary nodes becomes the new primary. Once the
failover is complete, we can go ahead and upgrade the original primary node.

1. Stop Redis service in Redis primary node so that it fails over to a secondary
   node

   ```
   sudo gitlab-ctl stop redis
   ```

1. Wait for failover to be complete. You can verify it by periodically checking
   details of the current Redis primary node (as mentioned above). If it starts
   reporting a new IP, failover is complete.

1. Start Redis again in that node, so that it starts following the current
   primary node.

   ```
   sudo gitlab-ctl start redis
   ```

1. Install package corresponding to new version.

1. Run `sudo gitlab-ctl reconfigure`, if a reconfigure is not run as part of
   installation (due to `/etc/gitlab/skip-auto-reconfigure` file being present).

1. If reconfigure warns about a pending Redis/Sentinel restart, restart the
   corresponding service

   ```
   sudo gitlab-ctl restart redis
   sudo gitlab-ctl restart sentinel
   ```

##### Update the application node

Install the package for new version and follow regular package upgrade
procedure.

### Geo deployment

NOTE: **Note:**
The order of steps is important. While following these steps, make
sure you follow them in the right order, on the correct node.

Log in to your **primary** node, executing the following:

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

1. To get the database migrations and latest code in place, run

   ```sh
   sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
   ```

NOTE: **Note:**
After this step you can get an outdated FDW remote schema on your
secondary nodes. While it is not important to worry about at this
point, you can check out the
[Geo troubleshooting documentation](https://docs.gitlab.com/ee/administration/geo/replication/troubleshooting.html#geo-database-has-an-outdated-fdw-remote-schema-error)
to resolve this.

1. Hot reload `unicorn`, `puma` and `sidekiq` services

   ```sh
   sudo gitlab-ctl hup unicorn
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   ```

On each **secondary** node, executing the following:

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

1. To get the database migrations and latest code in place, run

   ```sh
   sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
   ```

1. Hot reload `unicorn`, `puma`, `sidekiq` and restart `geo-logcursor` services

   ```sh
   sudo gitlab-ctl hup unicorn
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart geo-logcursor
   ```

1. Run post-deployment database migrations, specific to the Geo database

   ```sh
   sudo gitlab-rake geo:db:migrate
   ```

After all **secondary** nodes are updated, finalize
the update on the **primary** node:

- Run post-deployment database migrations

   ```sh
   sudo gitlab-rake db:migrate
   ```

On each **secondary**, ensure the FDW tables are up-to-date.

1. Wait for the **primary** migrations to finish.

1. Wait for the **primary** migrations to replicate. You can find "Data
   replication lag" for each node listed on `Admin Area > Geo`.

1. Refresh Foreign Data Wrapper tables

   ```sh
   sudo gitlab-rake geo:db:refresh_foreign_tables
   ```

After updating all nodes (both **primary** and all **secondaries**), check their status:

- Verify Geo configuration and dependencies

   ```sh
   sudo gitlab-rake gitlab:geo:check
   ```

NOTE: **Note:**
If you do not want to run zero downtime upgrades in the future, make
sure you remove `/etc/gitlab/skip-auto-reconfigure` and revert
setting `gitlab_rails['auto_migrate'] = false` in
`/etc/gitlab/gitlab.rb` after you've completed these steps.

### Multi-node / HA deployment with Geo

This section describes the steps required to upgrade a multi-node / HA
deployment with Geo. Some steps must be performed on a particular node. This
node will be known as the “deploy node” and is noted through the following
instructions.

Updates must be performed in the following order:

1. Update Geo **primary** multi-node deployment.
1. Update Geo **secondary** multi-node deployments.
1. Post-deployment migrations and checks.

#### Step 1: Choose a "deploy node" for each deployment

You now need to choose:

- One instance for use as the **primary** "deploy node" on the Geo **primary** multi-node deployment.
- One instance for use as the **secondary** "deploy node" on each Geo **secondary** multi-node deployment.

Deploy nodes must be configured to be running Unicorn or Sidekiq or the `geo-logcursor` daemon. In order
to avoid any downtime, they must not be in use during the update:

- If running Unicorn, remove the deploy node from the load balancer.
- If running Sidekiq, ensure the deploy node is not processing jobs:

  ```sh
  sudo gitlab-ctl stop sidekiq
  ```

- If running `geo-logcursor` daemon, ensure the deploy node is not processing events:

  ```sh
  sudo gitlab-ctl stop geo-logcursor
  ```

For zero-downtime, Unicorn, Sidekiq, and `geo-logcursor` must be running on other nodes during the update.

#### Step 2: Updating the Geo primary multi-node deployment

**On all nodes _including_ the primary "deploy node"**

Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
installation only, this will prevent the upgrade from running
`gitlab-ctl reconfigure` and automatically running database migrations.

```sh
sudo touch /etc/gitlab/skip-auto-reconfigure
```

**On all other nodes _excluding_ the primary "deploy node"**

1. Ensure that `gitlab_rails['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`.

1. Ensure nodes are running the latest code

   ```sh
   sudo gitlab-ctl reconfigure
   ```

**On primary Gitaly only nodes**

1. Update the GitLab package

   ```sh
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. Ensure nodes are running the latest code

   ```sh
   sudo gitlab-ctl reconfigure
   ```

**On the primary "deploy node"**

1. Update the GitLab package

   ```sh
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. To get the regular database migrations and latest code in place, run

   ```sh
   sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
   ```

1. If this deploy node is normally used to serve requests or process jobs,
   then you may return it to service at this point.

   - To serve requests, add the deploy node to the load balancer.
   - To process Sidekiq jobs again, start Sidekiq:

     ```sh
     sudo gitlab-ctl start sidekiq
     ```

**On all other nodes _excluding_ the primary "deploy node"**

1. Update the GitLab package

   ```sh
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. Ensure nodes are running the latest code

   ```sh
   sudo gitlab-ctl reconfigure
   ```

**For all nodes that run Unicorn or Sidekiq**

Hot reload `unicorn` and `sidekiq` services:

```sh
sudo gitlab-ctl hup unicorn
sudo gitlab-ctl restart sidekiq
```

#### Step 3: Updating each Geo secondary multi-node deployment

NOTE: **Note:**
Only proceed if you have successfully completed all steps on the Geo **primary** multi-node deployment.

**On all nodes _including_ the secondary "deploy node"**

Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
installation only, this will prevent the upgrade from running
`gitlab-ctl reconfigure` and automatically running database migrations.

```sh
sudo touch /etc/gitlab/skip-auto-reconfigure
```

**On all other nodes _excluding_ the secondary "deploy node"**

1. Ensure that `geo_secondary['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`

1. Ensure nodes are running the latest code

   ```sh
   sudo gitlab-ctl reconfigure
   ```

**On secondary Gitaly only nodes**

1. Update the GitLab package

   ```sh
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. Ensure nodes are running the latest code

   ```sh
   sudo gitlab-ctl reconfigure
   ```

**On the secondary "deploy node"**

1. Update the GitLab package

   ```sh
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. To get the regular database migrations and latest code in place, run

   ```sh
   sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
   ```

1. If this deploy node is normally used to serve requests or perform
   background processing, then you may return it to service at this point.

   - To serve requests, add the deploy node to the load balancer.
   - To process Sidekiq jobs again, start Sidekiq:

     ```sh
     sudo gitlab-ctl start sidekiq
     ```

   - To process Geo events again, start the `geo-logcursor` daemon:

     ```sh
     sudo gitlab-ctl start geo-logcursor
     ```

**On all nodes _excluding_ the secondary "deploy node"**

1. Update the GitLab package

   ```sh
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. Ensure nodes are running the latest code

   ```sh
   sudo gitlab-ctl reconfigure
   ```

**For all nodes that run Unicorn, Sidekiq, or the `geo-logcursor` daemon**

Hot reload `unicorn`, `sidekiq` and ``geo-logcursor`` services:

```sh
sudo gitlab-ctl hup unicorn
sudo gitlab-ctl restart sidekiq
sudo gitlab-ctl restart geo-logcursor
```

#### Step 4: Run post-deployment migrations and checks

**On the primary "deploy node"**

1. Run post-deployment database migrations:

   ```sh
   sudo gitlab-rake db:migrate
   ```

1. Verify Geo configuration and dependencies

   ```sh
   sudo gitlab-rake gitlab:geo:check
   ```

**On all secondary "deploy nodes"**

1. Run post-deployment database migrations, specific to the Geo database:

   ```sh
   sudo gitlab-rake geo:db:migrate
   ```

1. Wait for the **primary** migrations to finish.

1. Wait for the **primary** migrations to replicate. You can find "Data
   replication lag" for each node listed on `Admin Area > Geo`. These wait steps
   help ensure the FDW tables are up-to-date.

1. Refresh Foreign Data Wrapper tables

   ```sh
   sudo gitlab-rake geo:db:refresh_foreign_tables
   ```

1. Verify Geo configuration and dependencies

   ```sh
   sudo gitlab-rake gitlab:geo:check
   ```

1. Verify Geo status

   ```sh
   sudo gitlab-rake geo:status
   ```

## Upgrading Gitaly servers

Gitaly servers must be upgraded to the newer version prior to upgrading the application server.
This prevents the gRPC client on the application server from sending RPCs that the old Gitaly version
does not support.

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

First download a GitLab 12.x.x [CE](https://packages.gitlab.com/gitlab/gitlab-ce) or
[EE (subscribers only)](https://gitlab.com/subscribers/gitlab-ee/blob/master/doc/install/packages.md)
package.

Steps:

1. Stop GitLab:

   ```sh
   # Stop GitLab and remove its supervision process
   sudo gitlab-ctl stop unicorn
   sudo gitlab-ctl stop puma
   sudo gitlab-ctl stop sidekiq
   sudo systemctl stop gitlab-runsvdir
   sudo systemctl disable gitlab-runsvdir
   sudo rm /usr/lib/systemd/system/gitlab-runsvdir.service
   sudo systemctl daemon-reload
   sudo gitlab-ctl uninstall
   ```

1. Downgrade GitLab to 12.x:

   ```sh
   # Ubuntu
   sudo dpkg -r gitlab
   sudo dpkg -i gitlab-12.x.x-yyy.deb

   # CentOS:
   sudo rpm -e gitlab
   sudo rpm -ivh gitlab-12.x.x-yyy.rpm
   ```

1. Prepare GitLab for receiving the backup restore.

1. Reconfigure GitLab (includes database migrations):

   ```sh
   sudo gitlab-ctl reconfigure
   ```

1. Restore your backup:

    ```sh
    sudo gitlab-backup restore BACKUP=12345 # where 12345 is your backup timestamp
    ```

    NOTE: **Note**
    For GitLab 12.1 and earlier, use `gitlab-rake gitlab:backup:restore`.

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

### Package obsoleted by installed package

CE and EE packages are marked as obsoleting and replacing each other so that both aren't installed and running at the same time.

If you are using local RPM files to switch from CE to EE or vice versa, use `rpm` for installing the package rather than `yum`. If you try to use yum, then you may get an error like this:

```text
Cannot install package gitlab-ee-11.8.3-ee.0.el6.x86_64. It is obsoleted by installed package gitlab-ce-11.8.3-ce.0.el6.x86_64
```

To avoid this issue, either:

- Use the same instructions provided in the [Updating using a manually downloaded package](#updating-using-a-manually-downloaded-package) section.
- Temporarily disable obsoletion checking in yum by adding `--setopt=obsoletes=0` to the options given to the command.
