---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configuration options for Linux package installations
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

To configure GitLab, set the relevant options in the `/etc/gitlab/gitlab.rb` file.

[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)
contains a complete list of available options. New installations have all the
options of the template listed in `/etc/gitlab/gitlab.rb` by default.

{{< alert type="note" >}}

The examples provided when you edit `/etc/gitlab/gitlab.rb` might not always reflect the default settings for an instance.

{{< /alert >}}

For a list of default settings, see the
[package defaults](https://docs.gitlab.com/administration/package_information/defaults/).

## Configure the external URL for GitLab

To display the correct repository clone links to your users,
you must provide GitLab with the URL your users use to reach the repository.
You can use the IP of your server, but a Fully Qualified Domain Name (FQDN)
is preferred. See the [DNS documentation](dns.md)
for more details about the use of DNS in a GitLab Self-Managed instance.

To change the external URL:

1. Optional. Before you change the external URL, determine if you have previously
   defined a [custom **Home page URL** or **After sign-out path**](https://docs.gitlab.com/administration/settings/sign_in_restrictions/#sign-in-information).
   Both of these settings might cause unintentional redirecting after configuring
   a new external URL. If you have defined any URLs, remove them completely.

1. Edit `/etc/gitlab/gitlab.rb` and change `external_url` to your preferred URL:

   ```ruby
   external_url "http://gitlab.example.com"
   ```

   Alternatively, you can use the IP address of your server:

   ```ruby
   external_url "http://10.0.0.1"
   ```

   In the previous examples we use plain HTTP. If you want to use HTTPS, see
   how to [configure SSL](ssl/_index.md).

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Optional. If you had been using GitLab for a while, after you change the
   external URL, you should also
   [invalidate the Markdown cache](https://docs.gitlab.com/administration/invalidate_markdown_cache/).

### Specify the external URL at the time of installation

If you use the Linux package, you can set up your GitLab instance
with the minimum number of commands by using the `EXTERNAL_URL` environment variable.
If this variable is set, it is automatically detected and its value is written
as `external_url` in the `gitlab.rb` file.

The `EXTERNAL_URL` environment variable affects only the installation and upgrade
of packages. For regular reconfigure runs, the value
in `/etc/gitlab/gitlab.rb` is used.

As part of package updates, if you have `EXTERNAL_URL` variable set
inadvertently, it replaces the existing value in `/etc/gitlab/gitlab.rb`
without any warning. So, we recommended not to set the variable globally, but
rather pass it specifically to the installation command:

```shell
sudo EXTERNAL_URL="https://gitlab.example.com" apt-get install gitlab-ee
```

## Configure a relative URL for GitLab

{{< details >}}

- Status: Beta

{{< /details >}}

{{< alert type="warning" >}}

Configuring a relative URL for GitLab has [known issues with Geo](https://gitlab.com/gitlab-org/gitlab/-/issues/456427) and
[testing limitations](https://gitlab.com/gitlab-org/gitlab/-/issues/439943).

{{< /alert >}}

While we recommended installing GitLab in its own (sub)domain, sometimes
it is not possible. In that case, GitLab can also
be installed under a relative URL, for example, `https://example.com/gitlab`.

By changing the URL, all remote URLs change as well, so you must
manually edit them in any local repository that points to your GitLab instance.

These instructions are for Linux package installations. For instructions for self-compiled (source) installations, see
[install GitLab under a relative URL](https://docs.gitlab.com/install/relative_url/).

To enable relative URL in GitLab:

1. Set the `external_url` in `/etc/gitlab/gitlab.rb`:

   ```ruby
   external_url "https://example.com/gitlab"
   ```

   In this example, the relative URL under which GitLab is served is
   `/gitlab`. Change it to your liking.

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

If you have any issues, see the [troubleshooting section](#relative-url-troubleshooting).

## Load external configuration file from non-root user

Linux package installations load all configuration from `/etc/gitlab/gitlab.rb` file.
This file has strict file permissions and is owned by the `root` user. The reason for strict permissions
and ownership is that `/etc/gitlab/gitlab.rb` is being executed as Ruby code by the `root` user during `gitlab-ctl reconfigure`. This means
that users who have write access to `/etc/gitlab/gitlab.rb` can add a configuration that is executed as code by `root`.

In certain organizations, it is allowed to have access to the configuration files but not as the root user.
You can include an external configuration file inside `/etc/gitlab/gitlab.rb` by specifying the path to the file:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   from_file "/home/admin/external_gitlab.rb"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

When you use `from_file`:

- Code you include into `/etc/gitlab/gitlab.rb` using `from_file` runs with
  `root` privileges when you reconfigure GitLab.
- Any configuration that is set in `/etc/gitlab/gitlab.rb` after `from_file` is
  included, takes precedence over the configuration from the included file.

## Read certificate from file

Certificates can be stored as separate files and loaded into memory when running `sudo gitlab-ctl reconfigure`. Files containing
certificates must be plaintext.

In this example, the [PostgreSQL server certificate](database.md#configuring-ssl) is read directly from a file rather than copying and pasting into `/etc/gitlab/gitlab.rb` directly.

```ruby
postgresql['internal_certificate'] = File.read('/path/to/server.crt')
```

## Migrating from `git_data_dirs`

Starting in 18.0, `git_data_dirs` will no longer be a supported means of configuring
Gitaly storage locations. If you explicitly define `git_data_dirs`, you'll need to
migrate the configuration.

For example, for the Gitaly service, if your `/etc/gitlab/gitlab.rb` configuration is as follows:

```ruby
git_data_dirs({
  "default" => {
    "path" => "/mnt/nas/git-data"
   }
})
```

you'll need to redefine the configuration under `gitaly['configuration']` instead.
Note that the `/repositories` suffix must be appended to the path because it was previously
appended internally.

```ruby
gitaly['configuration'] = {
  storage: [
    {
      name: 'default',
      path: '/mnt/nas/git-data/repositories',
    },
  ],
}
```

<!-- vale gitlab_base.SubstitutionWarning = NO -->

It's important to note that the parent directory of the `path` must also be managed by
Omnibus. Following the example above, Omnibus must modify the permissions of
`/mnt/nas/git-data` on reconfiguration and may store data in that directory during
runtime. You should select an appropriate `path` that allows for this behavior.

<!-- vale gitlab_base.SubstitutionWarning = YES -->

For Rails and Sidekiq clients, if your `/etc/gitlab/gitlab.rb` configuration is as follows:

```ruby
git_data_dirs({
  "default" => {
    "gitaly_address" => "tcp://gitaly1.internal:8075"
   }
})
```

You'll need to redefine the configuration under `gitlab_rails['repositories_storages']` instead:

```ruby
gitlab_rails['repositories_storages'] = {
  "default" => {
    "gitaly_address" => "tcp://gitaly1.internal:8075"
  }
}
```

## Store Git data in an alternative directory

By default, Linux package installations store the Git repository data under
`/var/opt/gitlab/git-data/repositories`, and the Gitaly service listens on
`unix:/var/opt/gitlab/gitaly/gitaly.socket`.

To change the location of the directory,

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitaly['configuration'] = {
     storage: [
       {
         name: 'default',
         path: '/mnt/nas/git-data/repositories',
       },
     ],
   }
   ```

   You can also add more than one Git data directory:

   ```ruby
   gitaly['configuration'] = {
     storage: [
       {
         name: 'default',
         path: '/var/opt/gitlab/git-data/repositories',
       },
       {
         name: 'alternative',
         path: '/mnt/nas/git-data/repositories',
       },
     ],
   }
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Optional. If you already have existing Git repositories in `/var/opt/gitlab/git-data`, you
   can move them to the new location:
   1. Prevent users from writing to the repositories while you move them:

      ```shell
      sudo gitlab-ctl stop
      ```

   1. Sync the repositories to the new location. Note there is _no_ slash behind
      `repositories`, but there _is_ a slash behind `git-data`:

      ```shell
      sudo rsync -av --delete /var/opt/gitlab/git-data/repositories /mnt/nas/git-data/
      ```

   1. Reconfigure to start the necessary processes and fix any wrong permissions:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. Double-check the directory layout in `/mnt/nas/git-data/`. The expected output
      should be `repositories`:

      ```shell
      sudo ls /mnt/nas/git-data/
      ```

   1. Start GitLab and verify that you can browse through the repositories in
      the web interface:

      ```shell
      sudo gitlab-ctl start
      ```

If you're running Gitaly on a separate server, see
[the documentation on configuring Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-gitaly-clients).

If you're not looking to move all repositories, but instead want to move specific
projects between existing repository storages, use the
[Edit Project API](https://docs.gitlab.com/api/projects/#edit-a-project)
endpoint and specify the `repository_storage` attribute.

## Change the name of the Git user or group

{{< alert type="warning" >}}

We do not recommend changing the user or group of an existing installation because it can cause unpredictable side effects.

{{< /alert >}}

By default, Linux package installations use the user name `git` for Git GitLab Shell login,
ownership of the Git data itself, and SSH URL generation on the web interface.
Similarly, the `git` group is used for group ownership of the Git data.

To change the user and group on a new Linux package installation:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   user['username'] = "gitlab"
   user['group'] = "gitlab"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

If you are changing the username of an existing installation, the reconfigure run
doesn't change the ownership of the nested directories, so you must do that manually.

At the very least, you must change ownership of the repositories and uploads
directories:

```shell
sudo chown -R gitlab:gitlab /var/opt/gitlab/git-data/repositories
sudo chown -R gitlab:gitlab /var/opt/gitlab/gitlab-rails/uploads
```

## Specify numeric user and group identifiers

Linux package installations create users for GitLab, PostgreSQL, Redis, NGINX, etc. To
specify the numeric identifiers for these users:

1. Write down the old user and group identifiers, as you might need them later:

   ```shell
   sudo cat /etc/passwd
   ```

1. Edit `/etc/gitlab/gitlab.rb` and change any of the identifiers you want:

   ```ruby
   user['uid'] = 1234
   user['gid'] = 1234
   postgresql['uid'] = 1235
   postgresql['gid'] = 1235
   redis['uid'] = 1236
   redis['gid'] = 1236
   web_server['uid'] = 1237
   web_server['gid'] = 1237
   registry['uid'] = 1238
   registry['gid'] = 1238
   mattermost['uid'] = 1239
   mattermost['gid'] = 1239
   prometheus['uid'] = 1240
   prometheus['gid'] = 1240
   ```

1. Stop, reconfigure, and then start GitLab:

   ```shell
   sudo gitlab-ctl stop
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl start
   ```

1. Optional. If you're changing `user['uid']` and `user['gid']`, make sure to update the uid/guid of any files not managed by the Linux package
   directly, for example, the logs:

   ```shell
   find /var/log/gitlab -uid <old_uid> | xargs -I:: chown git ::
   find /var/log/gitlab -gid <old_uid> | xargs -I:: chgrp git ::
   find /var/opt/gitlab -uid <old_uid> | xargs -I:: chown git ::
   find /var/opt/gitlab -gid <old_uid> | xargs -I:: chgrp git ::
   ```

## Disable user and group account management

By default, Linux package installations create system user and group accounts,
as well as keeping the information updated.
These system accounts run various components of the package.
Most users don't need to change this behavior.
However, if your system accounts are managed by other software, for example, LDAP, you
might need to disable account management done by the GitLab package.

By default, the Linux package installations expect the following users and groups to exist:

| Linux user and group | Required                                | Description                                                           | Default home directory       | Default shell |
|----------------------|-----------------------------------------|-----------------------------------------------------------------------|------------------------------|---------------|
| `git`                | Yes                                     | GitLab user/group                                                     | `/var/opt/gitlab`            | `/bin/sh`     |
| `gitlab-www`         | Yes                                     | Web server user/group                                                 | `/var/opt/gitlab/nginx`      | `/bin/false`  |
| `gitlab-prometheus`  | Yes                                     | Prometheus user/group for Prometheus monitoring and various exporters | `/var/opt/gitlab/prometheus` | `/bin/sh`     |
| `gitlab-redis`       | Only when using the packaged Redis      | Redis user/group for GitLab                                           | `/var/opt/gitlab/redis`      | `/bin/false`  |
| `gitlab-psql`        | Only when using the packaged PostgreSQL | PostgreSQL user/group                                                 | `/var/opt/gitlab/postgresql` | `/bin/sh`     |
| `gitlab-consul`      | Only when using GitLab Consul           | GitLab Consul user/group                                              | `/var/opt/gitlab/consul`     | `/bin/sh`     |
| `registry`           | Only when using GitLab Registry         | GitLab Registry user/group                                            | `/var/opt/gitlab/registry`   | `/bin/sh`     |
| `mattermost`         | Only when using GitLab Mattermost       | GitLab Mattermost user/group                                          | `/var/opt/gitlab/mattermost` | `/bin/sh`     |
| `gitlab-backup`      | Only when using `gitlab-backup-cli`     | GitLab Backup Cli User                                                | `/var/opt/gitlab/backups`    | `/bin/sh`     |

To disable user and group accounts management:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   manage_accounts['enable'] = false
   ```

1. Optional. You can also use different user/group names, but then you must specify the user/group details:

   ```ruby
   # GitLab
   user['username'] = "git"
   user['group'] = "git"
   user['shell'] = "/bin/sh"
   user['home'] = "/var/opt/custom-gitlab"

   # Web server
   web_server['username'] = 'webserver-gitlab'
   web_server['group'] = 'webserver-gitlab'
   web_server['shell'] = '/bin/false'
   web_server['home'] = '/var/opt/gitlab/webserver'

   # Prometheus
   prometheus['username'] = 'gitlab-prometheus'
   prometheus['group'] = 'gitlab-prometheus'
   prometheus['shell'] = '/bin/sh'
   prometheus['home'] = '/var/opt/gitlab/prometheus'

   # Redis (not needed when using external Redis)
   redis['username'] = "redis-gitlab"
   redis['group'] = "redis-gitlab"
   redis['shell'] = "/bin/false"
   redis['home'] = "/var/opt/redis-gitlab"

   # Postgresql (not needed when using external Postgresql)
   postgresql['username'] = "postgres-gitlab"
   postgresql['group'] = "postgres-gitlab"
   postgresql['shell'] = "/bin/sh"
   postgresql['home'] = "/var/opt/postgres-gitlab"

   # Consul
   consul['username'] = 'gitlab-consul'
   consul['group'] = 'gitlab-consul'
   consul['dir'] = "/var/opt/gitlab/registry"

   # Registry
   registry['username'] = "registry"
   registry['group'] = "registry"
   registry['dir'] = "/var/opt/gitlab/registry"
   registry['shell'] = "/usr/sbin/nologin"

   # Mattermost
   mattermost['username'] = 'mattermost'
   mattermost['group'] = 'mattermost'
   mattermost['home'] = '/var/opt/gitlab/mattermost'
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Move the home directory for a user

For the GitLab user, we recommended that the home directory
is set on a local disk and not on shared storage like NFS, for better performance. When setting it in
NFS, Git requests must make another network request to read the Git
configuration and this increases latency in Git operations.

To move an existing home directory, GitLab services need to be stopped and some downtime is required:

1. Stop GitLab:

   ```shell
   sudo gitlab-ctl stop
   ```

1. Stop the runit server:

   ```shell
   sudo systemctl stop gitlab-runsvdir
   ```

1. Change the home directory:

   ```shell
   sudo usermod -d /path/to/home <username>
   ```

   If you had existing data, you need to manually copy/rsync it to the new location:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   user['home'] = "/var/opt/custom-gitlab"
   ```

1. Start the runit server:

   ```shell
   sudo systemctl start gitlab-runsvdir
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Disable storage directories management

The Linux package takes care of creating all the necessary directories
with the correct ownership and permissions, as well as keeping this updated.

Some of the directories hold large amounts of data so in certain setups,
those directories are most likely mounted on an NFS (or some other) share.

Some types of mounts don't allow the automatic creation of directories by the root user
(default user for initial setup), for example, NFS with `root_squash` enabled on the
share. To work around this, the Linux package attempts to create
those directories using the directory's owner user.

### Disable the `/etc/gitlab` directory management

If you have the `/etc/gitlab` directory mounted, you can turn off the management of
that directory:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   manage_storage_directories['manage_etc'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Disable the `/var/opt/gitlab` directory management

If you are mounting all GitLab storage directories, each on a separate mount,
you should completely disable the management of storage directories.

Linux package installations expect these directories to exist
on the file system. It is up to you to create and set correct
permissions if this setting is set.

Enabling this setting prevents the creation of the following directories:

| Default location                                       | Permissions | Ownership        | Purpose |
|--------------------------------------------------------|-------------|------------------|---------|
| `/var/opt/gitlab/git-data`                             | `2770`      | `git:git`        | Holds repositories directory |
| `/var/opt/gitlab/git-data/repositories`                | `2770`      | `git:git`        | Holds Git repositories |
| `/var/opt/gitlab/gitlab-rails/shared`                  | `0751`      | `git:gitlab-www` | Holds large object directories |
| `/var/opt/gitlab/gitlab-rails/shared/artifacts`        | `0700`      | `git:git`        | Holds CI artifacts |
| `/var/opt/gitlab/gitlab-rails/shared/external-diffs`   | `0700`      | `git:git`        | Holds external merge request diffs |
| `/var/opt/gitlab/gitlab-rails/shared/lfs-objects`      | `0700`      | `git:git`        | Holds LFS objects |
| `/var/opt/gitlab/gitlab-rails/shared/packages`         | `0700`      | `git:git`        | Holds package repository |
| `/var/opt/gitlab/gitlab-rails/shared/dependency_proxy` | `0700`      | `git:git`        | Holds dependency proxy |
| `/var/opt/gitlab/gitlab-rails/shared/terraform_state`  | `0700`      | `git:git`        | Holds terraform state |
| `/var/opt/gitlab/gitlab-rails/shared/ci_secure_files`  | `0700`      | `git:git`        | Holds uploaded secure files |
| `/var/opt/gitlab/gitlab-rails/shared/pages`            | `0750`      | `git:gitlab-www` | Holds user pages |
| `/var/opt/gitlab/gitlab-rails/uploads`                 | `0700`      | `git:git`        | Holds user attachments |
| `/var/opt/gitlab/gitlab-ci/builds`                     | `0700`      | `git:git`        | Holds CI build logs |
| `/var/opt/gitlab/.ssh`                                 | `0700`      | `git:git`        | Holds authorized keys |

To disable the management of storage directories:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   manage_storage_directories['enable'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Start Linux package installation services only after a given file system is mounted

If you want to prevent Linux package installation services (NGINX, Redis, Puma, etc.)
from starting before a given file system is mounted, you can set the
`high_availability['mountpoint']` setting:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # wait for /var/opt/gitlab to be mounted
   high_availability['mountpoint'] = '/var/opt/gitlab'
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   {{< alert type="note" >}}

   If the mount point doesn't exist, GitLab fails to reconfigure.

   {{< /alert >}}

## Configure the runtime directory

When Prometheus monitoring is enabled, the GitLab Exporter conducts measurements
of each Puma process (Rails metrics). Every Puma process needs to write
a metrics file to a temporary location for each controller request.
Prometheus then collects all these files and processes their values.

To avoid creating disk I/O, the Linux package uses a
runtime directory.

During `reconfigure`, the package check if `/run` is a `tmpfs` mount.
If it is not, the following warning is shown and Rails metrics are disabled:

```plaintext
Runtime directory '/run' is not a tmpfs mount.
```

To enable the Rails metrics again:

1. Edit `/etc/gitlab/gitlab.rb` to create a `tmpfs` mount
   (note that there is no `=` in the configuration):

   ```ruby
   runtime_dir '/path/to/tmpfs'
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configure a failed authentication ban

You can configure a
[failed authentication ban](https://docs.gitlab.com/security/rate_limits/#failed-authentication-ban-for-git-and-container-registry)
for Git and the container registry. When a client is banned, a 403 error code
is returned.

The following settings can be configured:

| Setting        | Description |
|----------------|-------------|
| `enabled`      | `false` by default. Set this to `true` to enable the Git and registry authentication ban. |
| `ip_whitelist` | IPs to not block. They must be formatted as strings in a Ruby array. You can use either single IPs or CIDR notation, for example, `["127.0.0.1", "127.0.0.2", "127.0.0.3", "192.168.0.1/24"]`. |
| `maxretry`     | The maximum amount of times a request can be made in the specified time. |
| `findtime`     | The maximum amount of time in seconds that failed requests can count against an IP before it's added to the denylist. |
| `bantime`      | The total amount of time in seconds that an IP is blocked. |

To configure the Git and container registry authentication ban:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['rack_attack_git_basic_auth'] = {
     'enabled' => true,
     'ip_whitelist' => ["127.0.0.1"],
     'maxretry' => 10, # Limit the number of Git HTTP authentication attempts per IP
     'findtime' => 60, # Reset the auth attempt counter per IP after 60 seconds
     'bantime' => 3600 # Ban an IP for one hour (3600s) after too many auth attempts
   }
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Disable automatic cache cleaning during installation

If you have a large GitLab installation, you might not want to run a `rake cache:clear` task
as it can take a long time to finish. By default, the cache clear task runs automatically
during reconfiguring.

To disable automatic cache cleaning during installation:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # This is an advanced feature used by large gitlab deployments where loading
   # whole RAILS env takes a lot of time.
   gitlab_rails['rake_cache_clear'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Error Reporting and Logging with Sentry

{{< alert type="warning" >}}

From GitLab 17.0, only Sentry versions 21.5.0 or later will be supported. If
you use an earlier version of a Sentry instance that you host, you must
[upgrade Sentry](https://develop.sentry.dev/self-hosted/releases/) to continue
collecting errors from your GitLab environments.

{{< /alert >}}

Sentry is an open source error reporting and logging tool which can be used as
SaaS (<https://sentry.io/welcome/>) or [host it yourself](https://develop.sentry.dev/self-hosted/).

To configure Sentry:

1. Create a project in Sentry.
1. Find the
   [Data Source Name (DSN)](https://docs.sentry.io/concepts/key-terms/dsn-explainer/)
   of the project you created.
1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['sentry_enabled'] = true
   gitlab_rails['sentry_dsn'] = 'https://<public_key>@<host>/<project_id>'            # value used by the Rails SDK
   gitlab_rails['sentry_clientside_dsn'] = 'https://<public_key>@<host>/<project_id>' # value used by the Browser JavaScript SDK
   gitlab_rails['sentry_environment'] = 'production'
   ```

   The [Sentry environment](https://docs.sentry.io/concepts/key-terms/environments/)
   can be used to track errors and issues across several deployed GitLab
   environments, for example, lab, development, staging, and production.

1. Optional. To set custom [Sentry tags](https://docs.sentry.io/concepts/key-terms/enrich-data/)
   on every event sent from a particular server, the `GITLAB_SENTRY_EXTRA_TAGS`
   an environment variable can be set. This variable is a JSON-encoded hash representing any
   tags that should be passed to Sentry for all exceptions from that server.

   For instance, setting:

   ```ruby
   gitlab_rails['env'] = {
     'GITLAB_SENTRY_EXTRA_TAGS' => '{"stage": "main"}'
   }
   ```

   Would add the `stage` tag with a value of `main`.

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Set a Content Delivery Network URL

Service static assets with a Content Delivery Network (CDN) or asset host
using `gitlab_rails['cdn_host']`. This configures a [Rails asset host](https://guides.rubyonrails.org/configuring.html#config-asset-host).

To set a CDN/asset host:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['cdn_host'] = 'https://mycdnsubdomain.fictional-cdn.com'
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Additional documentation for configuring common services to act as an asset host
is tracked in [this issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5708).

## Set a Content Security Policy

Setting a Content Security Policy (CSP) can help thwart JavaScript
cross-site scripting (XSS) attacks. See
[the Mozilla documentation on CSP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP) for more
details.

[CSP and nonce-source with inline JavaScript](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/script-src) is available on GitLab.com.
It is [not configured by default](https://gitlab.com/gitlab-org/gitlab/-/issues/30720) on GitLab Self-Managed.

{{< alert type="note" >}}

Improperly configuring the CSP rules could prevent GitLab from working
properly. Before rolling out a policy, you may also want to change
`report_only` to `true` to test the configuration.

{{< /alert >}}

To add a CSP:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['content_security_policy'] = {
       enabled: true,
       report_only: false
   }
   ```

   GitLab automatically provides secure default values for the CSP.
   Explicitly setting the `<default_value>` value for a directive is equivalent to
   not setting a value and will use the default values.

   To add a custom CSP:

   ```ruby
   gitlab_rails['content_security_policy'] = {
       enabled: true,
       report_only: false,
       directives: {
         default_src: "'none'",
         script_src: "https://example.com"
       }
   }
   ```

   Secure default values are used for directives that aren't explicitly configured.

   To unset a CSP directive, set a value of `false`.

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Set allowed hosts to prevent host header attacks

To prevent GitLab from accepting a host header other than
what's intended:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['allowed_hosts'] = ['gitlab.example.com']
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

There are no known security issues in GitLab caused by not configuring `allowed_hosts`,
but it's recommended for defense in depth against potential [HTTP Host header attacks](https://portswigger.net/web-security/host-header).

If using a custom external proxy such as Apache, it may be necessary to add the localhost address or name (`localhost` or `127.0.0.1`). You should add filters to the external proxy to mitigate potential HTTP Host header attacks passed through the proxy to workhorse.

```ruby
gitlab_rails['allowed_hosts'] = ['gitlab.example.com', '127.0.0.1', 'localhost']
```

## Session cookie configuration

To change the prefix of the generated web session cookie values:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['session_store_session_cookie_token_prefix'] = 'custom_prefix_'
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

The default value is an empty string `""`.

## Provide sensitive configuration to components without plain text storage

Some components expose an `extra_config_command` option in `gitlab.rb`. This allows an external script to provide secrets
dynamically rather than read them from plain text storage.

The available options are:

| `gitlab.rb` setting                          | Responsibility |
|----------------------------------------------|----------------|
| `redis['extra_config_command']`              | Provides extra configuration to the Redis server configuration file. |
| `gitlab_rails['redis_extra_config_command']` | Provides extra configuration to the Redis configuration files used by GitLab Rails application. (`resque.yml`, `redis.yml`, `redis.<redis_instance>.yml` files) |
| `gitlab_rails['db_extra_config_command']`    | Provides extra configuration to the DB configuration file used by GitLab Rails application. (`database.yml`) |
| `gitlab_kas['extra_config_command']`         | Provides extra configuration to GitLab agent server for Kubernetes (KAS). |
| `gitlab_workhorse['extra_config_command']`   | Provides extra configuration to GitLab Workhorse. |
| `gitlab_exporter['extra_config_command']`    | Provides extra configuration to GitLab Exporter. |

The value assigned to any of these options should be an absolute path to an executable script
that writes the sensitive configuration in the required format to STDOUT. The
components:

1. Execute the supplied script.
1. Replace values set by user and default configuration files with those emitted
   by the script.

### Provide Redis password to Redis server and client components

As an example, you can use the script and `gitlab.rb` snippet below to specify
the password to Redis server and components that need to connect to Redis.

{{< alert type="note" >}}

When specifying password to Redis server, this method only saves the user from
having the plaintext password in `gitlab.rb` file. The password will end up in
plaintext in the Redis server configuration file present at
`/var/opt/gitlab/redis/redis.conf`.

{{< /alert >}}

1. Save the script below as `/opt/generate-redis-conf`

   ```ruby
   #!/opt/gitlab/embedded/bin/ruby

   require 'json'
   require 'yaml'

   class RedisConfig
     REDIS_PASSWORD = `echo "toomanysecrets"`.strip # Change the command inside backticks to fetch Redis password

     class << self
       def server
         puts "requirepass '#{REDIS_PASSWORD}'"
         puts "masterauth '#{REDIS_PASSWORD}'"
       end

       def rails
         puts YAML.dump({
           'password' => REDIS_PASSWORD
         })
       end

       def kas
         puts YAML.dump({
           'redis' => {
             'password' => REDIS_PASSWORD
           }
         })
       end

       def workhorse
         puts JSON.dump({
           redis: {
             password: REDIS_PASSWORD
           }
         })
       end

       def gitlab_exporter
         puts YAML.dump({
           'probes' => {
             'sidekiq' => {
               'opts' => {
                 'redis_password' => REDIS_PASSWORD
               }
             }
           }
         })
       end
     end
   end

   def print_error_and_exit
     $stdout.puts "Usage: generate-redis-conf <COMPONENT>"
     $stderr.puts "Supported components are: server, rails, kas, workhorse, gitlab_exporter"

     exit 1
   end

   print_error_and_exit if ARGV.length != 1

   component = ARGV.shift
   begin
     RedisConfig.send(component.to_sym)
   rescue NoMethodError
     print_error_and_exit
   end
   ```

1. Ensure the script created above is executable:

   ```shell
   chmod +x /opt/generate-redis-conf
   ```

1. Add the snippet below to `/etc/gitlab/gitlab.rb`:

   ```ruby
   redis['extra_config_command'] = '/opt/generate-redis-conf server'

   gitlab_rails['redis_extra_config_command'] = '/opt/generate-redis-conf rails'
   gitlab_workhorse['extra_config_command'] = '/opt/generate-redis-conf workhorse'
   gitlab_kas['extra_config_command'] = '/opt/generate-redis-conf kas'
   gitlab_exporter['extra_config_command'] = '/opt/generate-redis-conf gitlab_exporter'
   ```

1. Run `sudo gitlab-ctl reconfigure`.

### Provide the PostgreSQL user password to GitLab Rails

As an example, you can use the script and configuration below to provide the
password that GitLab Rails should use to connect to the PostgreSQL server.

1. Save the script below as `/opt/generate-db-config`:

   ```ruby
   #!/opt/gitlab/embedded/bin/ruby

   require 'yaml'

   db_password = `echo "toomanysecrets"`.strip # Change the command inside backticks to fetch DB password

   puts YAML.dump({
    'main' => {
      'password' => db_password
    },
    'ci' => {
      'password' => db_password
    }
   })
   ```

1. Ensure the script created above is executable:

   ```shell
   chmod +x /opt/generate-db-config
   ```

1. Add the snippet below to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['db_extra_config_command'] = '/opt/generate-db-config'
   ```

1. Run `sudo gitlab-ctl reconfigure`.

## Related topics

- [Disable impersonation](https://docs.gitlab.com/api/rest/authentication/#disable-impersonation)
- [Set up LDAP sign-in](https://docs.gitlab.com/administration/auth/ldap/)
- [Smartcard authentication](https://docs.gitlab.com/administration/auth/smartcard/)
- [Set up NGINX](nginx.md) for things like:
  - Set up HTTPS
  - Redirect `HTTP` requests to `HTTPS`
  - Change the default port and the SSL certificate locations
  - Set the NGINX listen-address or addresses
  - Insert custom NGINX settings into the GitLab server block
  - Insert custom settings into the NGINX configuration
  - Enable `nginx_status`
- [Use a non-packaged web-server](nginx.md#use-a-non-bundled-web-server)
- [Use a non-packaged PostgreSQL database management server](database.md)
- [Use a non-packaged Redis instance](redis.md)
- [Add `ENV` vars to the GitLab runtime environment](environment-variables.md)
- [Changing `gitlab.yml` and `application.yml` settings](gitlab.yml.md)
- [Send application email via SMTP](smtp.md)
- [Set up OmniAuth (Google, Twitter, GitHub login)](https://docs.gitlab.com/integration/omniauth/)
- [Adjust Puma settings](https://docs.gitlab.com/administration/operations/puma/)

## Troubleshooting

### Relative URL troubleshooting

If you notice any issues with GitLab assets appearing broken after moving to a
relative URL configuration (like missing images or unresponsive components),
please raise an issue in [GitLab](https://gitlab.com/gitlab-org/gitlab)
with the `Frontend` label.

### Error: `Mixlib::ShellOut::ShellCommandFailed: linux_user[GitLab user and group]`

When [moving the home directory for a user](#move-the-home-directory-for-a-user),
if the runit service is not stopped and the home directories are not manually
moved for the user, GitLab will encounter an error while reconfiguring:

```plaintext
account[GitLab user and group] (package::users line 28) had an error: Mixlib::ShellOut::ShellCommandFailed: linux_user[GitLab user and group] (/opt/gitlab/embedded/cookbooks/cache/cookbooks/package/resources/account.rb line 51) had an error: Mixlib::ShellOut::ShellCommandFailed: Expected process to exit with [0], but received '8'
---- Begin output of ["usermod", "-d", "/var/opt/gitlab", "git"] ----
STDOUT:
STDERR: usermod: user git is currently used by process 1234
---- End output of ["usermod", "-d", "/var/opt/gitlab", "git"] ----
Ran ["usermod", "-d", "/var/opt/gitlab", "git"] returned 8
```

Make sure to stop `runit` before moving the home directory.

### GitLab responds with 502 after changing the name of the Git user or group

If you changed the [name of the Git user or group](#change-the-name-of-the-git-user-or-group)
on an existing installation, this can cause many side effects.

You can check for errors that relate to files unable to access and try to
fix their permissions:

```shell
gitlab gitlab-ctl tail -f
```
