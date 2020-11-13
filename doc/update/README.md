---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Update GitLab installed with the Omnibus GitLab package

Before following these instructions, note the following:

- [Supported upgrade paths](https://docs.gitlab.com/ee/update/README.html#upgrade-paths)
  has suggestions on when to upgrade.
- If you are upgrading from a non-Omnibus installation to an Omnibus installation, see
  [Upgrading from a non-Omnibus installation to an Omnibus installation](convert_to_omnibus.md).

CAUTION: **Caution:**
If you aren't [using the current major version](#mandatory-upgrade-paths-for-version-upgrades),
you **must** follow the
[supported upgrade paths](https://docs.gitlab.com/ee/update/README.html#upgrade-paths)
when updating to the current version.

## Background migrations

DANGER: **Warning:**
It's important to ensure that any background migrations have been fully completed
before upgrading to a new major version. Upgrading before background migrations have
finished may lead to data corruption.

To see the current size of the `background_migration` queue,
[check for background migrations before upgrading](https://docs.gitlab.com/ee/update/README.html#checking-for-background-migrations-before-upgrading).

## Version-specific changes

We recommend performing upgrades between major and minor releases no more than once per
week, to allow time for background migrations to finish. Decrease the time required to
complete these migrations by increasing the number of
[Sidekiq workers](https://docs.gitlab.com/ee/administration/operations/extra_sidekiq_processes.html)
that can process jobs in the `background_migration` queue.

Updating to major versions might need some manual intervention. For more information,
check the version your are updating to:

- [GitLab 13](gitlab_13_changes.md)
- [GitLab 12](gitlab_12_changes.md)
- [GitLab 11](gitlab_11_changes.md)
- [GitLab 10](gitlab_10_changes.md)
- [GitLab 8](gitlab_8_changes.md)
- [GitLab 7](gitlab_7_changes.md)
- [GitLab 6](gitlab_6_changes.md)

## Mandatory upgrade paths for version upgrades

From GitLab 10.8, upgrade paths are enforced for version upgrades by
default. This restricts performing direct upgrades that skip major versions (for
example 10.3 to 12.7 in one jump) that **can break GitLab
installations** due to multiple reasons like deprecated or removed configuration
settings, upgrade of internal tools and libraries etc. Users will have to follow
the [official upgrade paths](https://docs.gitlab.com/ee/update/README.html#upgrade-paths)
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

When upgrading to a new major version, remember to first [check for background migrations](https://docs.gitlab.com/ee/update/README.html#checking-for-background-migrations-before-upgrading).

Unless you are following the steps in [Zero downtime updates](#zero-downtime-updates), your GitLab application will not be available to users while an update is in progress. They will either see a "Deploy in progress" message or a "502" error in their web browser.

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

When following an [upgrade path](https://docs.gitlab.com/ee/update/README.html#upgrade-paths)
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
   sudo apt upgrade gitlab-ee=12.0.12-ee.0
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

CAUTION: **Caution:**
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
   curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
   ```

   **For CentOS/RHEL**

   ```shell
   curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash
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

NOTE: **Note:**
If you want to use `dpkg`/`rpm` instead of `apt-get`/`yum`, go through the first
step to find the current GitLab version and then follow
[Update using a manually-downloaded package](#update-using-a-manually-downloaded-package).

## Zero downtime updates

It's possible to upgrade to a newer version of GitLab without having to take
your GitLab instance offline.

Verify that you can upgrade with no downtime by checking the
[Upgrading without downtime section](https://docs.gitlab.com/ee/update/README.html#upgrading-without-downtime) of the update document.

If you meet all the requirements above, follow these instructions in order. There are three sets of steps, depending on your deployment type:

| Deployment type                                                 | Description                                       |
| --------------------------------------------------------------- | ------------------------------------------------  |
| [Single-node](#single-node-deployment)                          | GitLab CE/EE on a single node                     |
| [Gitaly Cluster](#gitaly-cluster)                               | GitLab CE/EE using HA architecture for Gitaly Cluster             |
| [Multi-node / PostgreSQL HA](#use-postgresql-ha)                | GitLab CE/EE using HA architecture for PostgreSQL |
| [Multi-node / Redis HA](#use-redis-ha-using-sentinel)           | GitLab CE/EE using HA architecture for Redis |
| [Geo](#geo-deployment)                                          | GitLab EE with Geo enabled                        |
| [Multi-node / HA with Geo](#multi-node--ha-deployment-with-geo) | GitLab CE/EE on multiple nodes                    |

Each type of deployment will require that you hot reload the `puma` (or `unicorn`) and `sidekiq` processes on all nodes running these
services after you've upgraded. The reason for this is that those processes each load the GitLab Rails application which reads and loads
the database schema into memory when starting up. Each of these processes will need to be reloaded (or restarted in the case of `sidekiq`)
to re-read any database changes that have been made by post-deployment migrations.

### Single-node deployment

Before following these instructions, note the following **important** information:

- On single-node Omnibus deployments, zero down-time updates are not possible when
  using Puma because Puma always requires a complete restart (Puma replaced Unicorn as
  the default in GitLab 13.0 unless
  [specifically disabled](../settings/unicorn.md#enabling-unicorn)). This is because the
  [phased restart](https://github.com/puma/puma/blob/master/README.md#clustered-mode)
  feature of Puma does not work with the way it is configured in GitLab's all-in-one
  packages (cluster-mode with app preloading).
- While it is possible to minimize downtime on a single-node instance by following
  these instructions, **it is not possible to always achieve true zero downtime
  updates**. Users may see some connections timeout or be refused for a few minutes,
  depending on which services need to restart.

1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
   installation only, this will prevent the upgrade from running
   `gitlab-ctl reconfigure` and automatically running database migrations

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. Update the GitLab package:

   - For GitLab Community Edition:

     ```shell
     # Debian/Ubuntu
     sudo apt-get update
     sudo apt-get install gitlab-ce

     # Centos/RHEL
     sudo yum install gitlab-ce
     ```

   - For GitLab [Enterprise Edition](https://about.gitlab.com/pricing/):

     ```shell
     # Debian/Ubuntu
     sudo apt-get update
     sudo apt-get install gitlab-ee

     # Centos/RHEL
     sudo yum install gitlab-ee
     ```

1. To get the regular migrations and latest code in place, run

   ```shell
   sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
   ```

1. Once the node is updated and `reconfigure` finished successfully, complete the migrations with

   ```shell
   sudo gitlab-rake db:migrate
   ```

1. Hot reload `unicorn` (or `puma`) and `sidekiq` services

   ```shell
   sudo gitlab-ctl hup unicorn
   sudo gitlab-ctl restart sidekiq
   ```

If you do not want to run zero downtime upgrades in the future, make
sure you remove `/etc/gitlab/skip-auto-reconfigure` after
you've completed these steps.

### Multi-node / HA deployment

#### Use a load balancer in front of web (Puma/Unicorn) nodes

With Puma, single node zero-downtime updates are no longer possible. To achieve
HA with zero-downtime updates, at least two nodes are required to be used with a
load balancer which distributes the connections properly across both nodes.

The load balancer in front of the application nodes must be configured to check
proper health check endpoints to check if the service is accepting traffic or
not. For Puma and Unicorn, the `/-/readiness` endpoint should be used, while
`/readiness` endpoint can be used for Sidekiq and other services.

Upgrades on web (Puma/Unicorn) nodes must be done in a rolling manner, one after
another, ensuring at least one node is always up to serve traffic. This is
required to ensure zero-downtime.

Both Puma and Unicorn will enter a blackout period as part of the upgrade,
during which they continue to accept connections but will mark their respective
health check endpoints to be unhealthy. On seeing this, the load balancer should
disconnect them gracefully.

Both Puma and Unicorn will restart only after completing all the currently
processing requests. This ensures data and service integrity. Once they have
restarted, the health check end points will be marked healthy.

The nodes must be updated in the following order to update an HA instance using
load balancer to latest GitLab version.

1. Select one application node as a deploy node and complete the following steps
   on it:

    1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This will
       prevent the upgrade from running `gitlab-ctl reconfigure` and
       automatically running database migrations:

        ```shell
        sudo touch /etc/gitlab/skip-auto-reconfigure
        ```

    1. Update the GitLab package:

       ```shell
       # Debian/Ubuntu
       sudo apt-get update && sudo apt-get install gitlab-ce

       # Centos/RHEL
       sudo yum install gitlab-ce
       ```

       If you are an Enterprise Edition user, replace `gitlab-ce` with
       `gitlab-ee` in the above command.

    1. Get the regular migrations and latest code in place:

       ```shell
       sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
       ```

    1. Ensure services use the latest code:

       ```shell
       sudo gitlab-ctl hup puma
       sudo gitlab-ctl restart sidekiq
       ```

1. Complete the following steps on the other Puma/Unicorn/Sidekiq nodes, one
   after another. Always ensure at least one of such nodes is up and running,
   and connected to the load balancer before proceeding to the next node.

    1. Update the GitLab package and ensure a `reconfigure` is run as part of
       it. If not (due to `/etc/gitlab/skip-auto-reconfigure` file being
       present), run `sudo gitlab-ctl reconfigure` manually.

    1. Ensure services use latest code:

       ```shell
       sudo gitlab-ctl hup puma
       sudo gitlab-ctl restart sidekiq
       ```

1. On the deploy node, run the post-deployment migrations:

      ```shell
      sudo gitlab-rake db:migrate
      ```

#### Gitaly Cluster

[Gitaly Cluster](https://docs.gitlab.com/ee/administration/gitaly/praefect.html) is built using
Gitaly and the Praefect component. It has its own PostgreSQL database, independent of the rest of
the application.

Before you update the main application you need to update Praefect.
Out of your Praefect nodes, pick one to be your Praefect deploy node.
This is where you will install the new Omnibus package first and run
database migrations.

**Praefect deploy node**

- Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
  installation only, this will prevent the upgrade from running
  `gitlab-ctl reconfigure` and restarting GitLab before database migrations have been applied:

  ```shell
  sudo touch /etc/gitlab/skip-auto-reconfigure
  ```

- Ensure that `praefect['auto_migrate'] = true` is set in `/etc/gitlab/gitlab.rb`

**All other Praefect nodes (not the Praefect deploy node)**

- Ensure that `praefect['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`

**Praefect deploy node**

- Update the GitLab package:

  ```shell
  # Debian/Ubuntu
  sudo apt-get update && sudo apt-get install gitlab-ce

  # Centos/RHEL
  sudo yum install gitlab-ce
  ```

  If you are an Enterprise Edition user, replace `gitlab-ce` with `gitlab-ee` in the above command.

- To apply the Praefect database migrations and restart Praefect, run:

  ```shell
  sudo gitlab-ctl reconfigure
  ```

**All other Praefect nodes (not the Praefect deploy node)**

- Update the GitLab package:

  ```shell
  sudo apt-get update && sudo apt-get install gitlab-ce
  ```

  If you are an Enterprise Edition user, replace `gitlab-ce` with `gitlab-ee` in the above command.

- Ensure nodes are running the latest code:

  ```shell
  sudo gitlab-ctl reconfigure
  ```

#### Use PostgreSQL HA

Pick a node to be the `Deploy Node`. It can be any node, but it must be the same
node throughout the process.

**Deploy node**

- Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
  installation only, this will prevent the upgrade from running
  `gitlab-ctl reconfigure` and restarting GitLab before database migrations have been applied.

  ```shell
  sudo touch /etc/gitlab/skip-auto-reconfigure
  ```

**All nodes (including the Deploy node)**

- Ensure that `gitlab_rails['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`

**Gitaly only nodes**

- Update the GitLab package

  ```shell
  # Debian/Ubuntu
  sudo apt-get update && sudo apt-get install gitlab-ce

  # Centos/RHEL
  sudo yum install gitlab-ce
  ```

  If you are an Enterprise Edition user, replace `gitlab-ce` with `gitlab-ee` in the above command.

- Ensure nodes are running the latest code

  ```shell
  sudo gitlab-ctl reconfigure
  ```

**Deploy node**

- Update the GitLab package

  ```shell
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

  ```shell
  sudo gitlab-ctl repmgr cluster show
  ```

  Then, in your `gitlab.rb` file on the deploy node, update
  `gitlab_rails['db_host']` and `gitlab_rails['db_port']` with the database
  master's host and port.

- To get the regular database migrations and latest code in place, run

  ```shell
  sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
  ```

**All other nodes (not the Deploy node)**

- Update the GitLab package

  ```shell
  sudo apt-get update && sudo apt-get install gitlab-ce
  ```

  If you are an Enterprise Edition user, replace `gitlab-ce` with `gitlab-ee` in the above command.

- Ensure nodes are running the latest code

  ```shell
  sudo gitlab-ctl reconfigure
  ```

**Deploy node**

- Run post-deployment database migrations on deploy node to complete the migrations with

  ```shell
  sudo gitlab-rake db:migrate
  ```

**For nodes that run Puma/Unicorn or Sidekiq**

- Hot reload `puma` (or `unicorn`) and `sidekiq` services

  ```shell
  sudo gitlab-ctl hup puma
  sudo gitlab-ctl restart sidekiq
  ```

- If you're using PgBouncer:

  Change your `gitlab.rb` to point back to PgBouncer and run:

  ```shell
  sudo gitlab-ctl reconfigure
  ```

If you do not want to run zero downtime upgrades in the future, make
sure you remove `/etc/gitlab/skip-auto-reconfigure` and revert
setting `gitlab_rails['auto_migrate'] = false` in
`/etc/gitlab/gitlab.rb` after you've completed these steps.

#### Use Redis HA (using Sentinel) **(PREMIUM ONLY)**

Package upgrades may involve version updates to the bundled Redis service. On
instances using [Redis for scaling](https://docs.gitlab.com/ee/administration/redis/index.html),
upgrades must follow a proper order to ensure minimum downtime, as specified
below. This doc assumes the official guides are being followed to setup Redis
HA.

##### In the application node

According to [official Redis docs](https://redis.io/topics/admin#upgrading-or-restarting-a-redis-instance-without-downtime),
the easiest way to update an HA instance using Sentinel is to upgrade the
secondaries one after the other, perform a manual failover from current
primary (running old version) to a recently upgraded secondary (running a new
version), and then upgrade the original primary. For this, we need to know
the address of the current Redis primary.

- If your application node is running GitLab 12.7.0 or later, you can use the
following command to get address of current Redis primary

  ```shell
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

     ```shell
     sudo /opt/gitlab/embedded/bin/redis-cli -h <sentinel host> -p <sentinel port> SENTINEL get-master-addr-by-name <redis master name>
     ```

##### In the Redis secondary nodes

1. Install package for new version.

1. Run `sudo gitlab-ctl reconfigure`, if a reconfigure is not run as part of
   installation (due to `/etc/gitlab/skip-auto-reconfigure` file being present).

1. If reconfigure warns about a pending Redis/Sentinel restart, restart the
   corresponding service

   ```shell
   sudo gitlab-ctl restart redis
   sudo gitlab-ctl restart sentinel
   ```

##### In the Redis primary node

Before upgrading the Redis primary node, we need to perform a failover so that
one of the recently upgraded secondary nodes becomes the new primary. Once the
failover is complete, we can go ahead and upgrade the original primary node.

1. Stop Redis service in Redis primary node so that it fails over to a secondary
   node

   ```shell
   sudo gitlab-ctl stop redis
   ```

1. Wait for failover to be complete. You can verify it by periodically checking
   details of the current Redis primary node (as mentioned above). If it starts
   reporting a new IP, failover is complete.

1. Start Redis again in that node, so that it starts following the current
   primary node.

   ```shell
   sudo gitlab-ctl start redis
   ```

1. Install package corresponding to new version.

1. Run `sudo gitlab-ctl reconfigure`, if a reconfigure is not run as part of
   installation (due to `/etc/gitlab/skip-auto-reconfigure` file being present).

1. If reconfigure warns about a pending Redis/Sentinel restart, restart the
   corresponding service

   ```shell
   sudo gitlab-ctl restart redis
   sudo gitlab-ctl restart sentinel
   ```

##### Update the application node

Install the package for new version and follow regular package upgrade
procedure.

### Geo deployment **(PREMIUM ONLY)**

The order of steps is important. While following these steps, make
sure you follow them in the right order, on the correct node.

Log in to your **primary** node, executing the following:

1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
   installation only, this will prevent the upgrade from running
   `gitlab-ctl reconfigure` and automatically running database migrations

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. Update the GitLab package

   ```shell
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. To get the database migrations and latest code in place, run

   ```shell
   sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
   ```

1. Hot reload `puma` (or `unicorn`) and `sidekiq` services

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   ```

On each **secondary** node, executing the following:

1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
   installation only, this will prevent the upgrade from running
   `gitlab-ctl reconfigure` and automatically running database migrations

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. Update the GitLab package

   ```shell
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. To get the database migrations and latest code in place, run

   ```shell
   sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
   ```

1. Hot reload `puma` (or `unicorn`), `sidekiq` and restart `geo-logcursor` services

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart geo-logcursor
   ```

1. Run post-deployment database migrations, specific to the Geo database

   ```shell
   sudo gitlab-rake geo:db:migrate
   ```

After all **secondary** nodes are updated, finalize
the update on the **primary** node:

- Run post-deployment database migrations

   ```shell
   sudo gitlab-rake db:migrate
   ```

After updating all nodes (both **primary** and all **secondaries**), check their status:

- Verify Geo configuration and dependencies

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

If you do not want to run zero downtime upgrades in the future, make
sure you remove `/etc/gitlab/skip-auto-reconfigure` and revert
setting `gitlab_rails['auto_migrate'] = false` in
`/etc/gitlab/gitlab.rb` after you've completed these steps.

### Multi-node / HA deployment with Geo **(PREMIUM ONLY)**

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

Deploy nodes must be configured to be running Puma/Unicorn or Sidekiq or the `geo-logcursor` daemon. In order
to avoid any downtime, they must not be in use during the update:

- If running Puma/Unicorn, remove the deploy node from the load balancer.
- If running Sidekiq, ensure the deploy node is not processing jobs:

  ```shell
  sudo gitlab-ctl stop sidekiq
  ```

- If running `geo-logcursor` daemon, ensure the deploy node is not processing events:

  ```shell
  sudo gitlab-ctl stop geo-logcursor
  ```

For zero-downtime, Puma/Unicorn, Sidekiq, and `geo-logcursor` must be running on other nodes during the update.

#### Step 2: Update the Geo primary multi-node deployment

**On all nodes _including_ the primary "deploy node"**

Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
installation only, this will prevent the upgrade from running
`gitlab-ctl reconfigure` and automatically running database migrations.

```shell
sudo touch /etc/gitlab/skip-auto-reconfigure
```

**On all other nodes _excluding_ the primary "deploy node"**

1. Ensure that `gitlab_rails['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`.

1. Ensure nodes are running the latest code

   ```shell
   sudo gitlab-ctl reconfigure
   ```

**On primary Gitaly only nodes**

1. Update the GitLab package

   ```shell
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. Ensure nodes are running the latest code

   ```shell
   sudo gitlab-ctl reconfigure
   ```

**On the primary "deploy node"**

1. Update the GitLab package

   ```shell
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. To get the regular database migrations and latest code in place, run

   ```shell
   sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
   ```

1. If this deploy node is normally used to serve requests or process jobs,
   then you may return it to service at this point.

   - To serve requests, add the deploy node to the load balancer.
   - To process Sidekiq jobs again, start Sidekiq:

     ```shell
     sudo gitlab-ctl start sidekiq
     ```

**On all other nodes _excluding_ the primary "deploy node"**

1. Update the GitLab package

   ```shell
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. Ensure nodes are running the latest code

   ```shell
   sudo gitlab-ctl reconfigure
   ```

**For all nodes that run Puma/Unicorn or Sidekiq _including_ the primary "deploy node"**

Hot reload `puma` (or `unicorn`) and `sidekiq` services:

```shell
sudo gitlab-ctl hup puma
sudo gitlab-ctl restart sidekiq
```

#### Step 3: Update each Geo secondary multi-node deployment

Only proceed if you have successfully completed all steps on the Geo **primary** multi-node deployment.

**On all nodes _including_ the secondary "deploy node"**

Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. During software
installation only, this will prevent the upgrade from running
`gitlab-ctl reconfigure` and automatically running database migrations.

```shell
sudo touch /etc/gitlab/skip-auto-reconfigure
```

**On all other nodes _excluding_ the secondary "deploy node"**

1. Ensure that `geo_secondary['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`

1. Ensure nodes are running the latest code

   ```shell
   sudo gitlab-ctl reconfigure
   ```

**On secondary Gitaly only nodes**

1. Update the GitLab package

   ```shell
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. Ensure nodes are running the latest code

   ```shell
   sudo gitlab-ctl reconfigure
   ```

**On the secondary "deploy node"**

1. Update the GitLab package

   ```shell
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. To get the regular database migrations and latest code in place, run

   ```shell
   sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
   ```

1. If this deploy node is normally used to serve requests or perform
   background processing, then you may return it to service at this point.

   - To serve requests, add the deploy node to the load balancer.
   - To process Sidekiq jobs again, start Sidekiq:

     ```shell
     sudo gitlab-ctl start sidekiq
     ```

   - To process Geo events again, start the `geo-logcursor` daemon:

     ```shell
     sudo gitlab-ctl start geo-logcursor
     ```

**On all nodes _excluding_ the secondary "deploy node"**

1. Update the GitLab package

   ```shell
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. Ensure nodes are running the latest code

   ```shell
   sudo gitlab-ctl reconfigure
   ```

**For all nodes that run Puma/Unicorn, Sidekiq, or the `geo-logcursor` daemon _including_ the secondary "deploy node"**

Hot reload `puma` (or `unicorn`), `sidekiq` and ``geo-logcursor`` services:

```shell
sudo gitlab-ctl hup puma
sudo gitlab-ctl restart sidekiq
sudo gitlab-ctl restart geo-logcursor
```

#### Step 4: Run post-deployment migrations and checks

**On the primary "deploy node"**

1. Run post-deployment database migrations:

   ```shell
   sudo gitlab-rake db:migrate
   ```

1. Verify Geo configuration and dependencies

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

**On all secondary "deploy nodes"**

1. Run post-deployment database migrations, specific to the Geo database:

   ```shell
   sudo gitlab-rake geo:db:migrate
   ```

1. Wait for the **primary** migrations to finish.

1. Wait for the **primary** migrations to replicate. You can find "Data
   replication lag" for each node listed on `Admin Area > Geo`.

1. Verify Geo configuration and dependencies

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

1. Verify Geo status

   ```shell
   sudo gitlab-rake geo:status
   ```

## Upgrade Gitaly servers

Gitaly servers must be upgraded to the newer version prior to upgrading the application server.
This prevents the gRPC client on the application server from sending RPCs that the old Gitaly version
does not support.

## Downgrade

This section contains general information on how to revert to an earlier version
of a package.

CAUTION: **Warning:**
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

    # If running Unicorn
   sudo gitlab-ctl stop unicorn

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

1. Restore your backup:

   ```shell
   # Restore your backup and reconfigure
   sudo gitlab-backup restore BACKUP=XXXXXXXXXX_2020_XX_XX_13.0.5-ee
   sudo gitlab-ctl reconfigure
   ```

1. Restart GitLab:

   ```shell
   sudo gitlab-ctl restart
   ```

1. Check GitLab:

   ```shell
   # It may take a few seconds for Sidekiq and gitlab-shell to start
   sudo gitlab-rake gitlab:check SANITIZE=true
   ```

## Update GitLab CI from prior `5.4.0` to version `7.14` via Omnibus GitLab

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

Where `url` is the URL to the GitLab instance.

Make sure to run `sudo gitlab-ctl reconfigure` after saving the configuration.

## Troubleshooting

### Get the status of a GitLab installation

```shell
sudo gitlab-ctl status
sudo gitlab-rake gitlab:check SANITIZE=true
```

- Information on using `gitlab-ctl` to perform [maintenance tasks](../maintenance/README.md).
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
