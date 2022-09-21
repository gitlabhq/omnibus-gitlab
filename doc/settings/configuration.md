---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configuration options for the GitLab Linux package **(FREE SELF)**

To configure GitLab, set the relevant options in the `/etc/gitlab/gitlab.rb` file.

[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)
contains a complete list of available options. New installations have all the
options of the template listed in `/etc/gitlab/gitlab.rb` by default.

For a list of default settings, see the
[package defaults](https://docs.gitlab.com/ee/administration/package_information/defaults.html).

## Configure the external URL for GitLab

To display the correct repository clone links to your users,
you must provide GitLab with the URL your users use to reach the repository.
You can use the IP of your server, but a Fully Qualified Domain Name (FQDN)
is preferred. See the [DNS documentation](dns.md)
for more details about the use of DNS in a self-managed GitLab instance.

To change the external URL:

1. Optional. Before you change the external URL, determine if you have previously
   defined a [custom **Home page URL** or **After sign-out path**](https://docs.gitlab.com/ee/user/admin_area/settings/sign_in_restrictions.html#sign-in-information).
   Both of these settings might cause unintentional redirecting after configuring
   a new external URL. If you have defined any URLs, remove them completely.

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   external_url "http://gitlab.example.com"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. After you change the external URL, we recommended you also
   [invalidate the Markdown cache](https://docs.gitlab.com/ee/administration/invalidate_markdown_cache.html).

### Specify the external URL at the time of installation

If you use the GitLab Linux package, you can set up your GitLab instance
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

NOTE:
For installations from source, there is a
[separate document](https://docs.gitlab.com/ee/install/relative_url.html).

While we recommended installing GitLab in its own (sub)domain, sometimes
it is not possible. In that case, GitLab can also
be installed under a relative URL, for example, `https://example.com/gitlab`.

By changing the URL, all remote URLs change as well, so you must
manually edit them in any local repository that points to your GitLab instance.

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

Omnibus GitLab package loads all configuration from `/etc/gitlab/gitlab.rb` file.
This file has strict file permissions and is owned by the `root` user. The reason for strict permissions
and ownership is that `/etc/gitlab/gitlab.rb` is being executed as Ruby code by the `root` user during `gitlab-ctl reconfigure`. This means
that users who have to write access to `/etc/gitlab/gitlab.rb` can add configuration that is executed as code by `root`.

In certain organizations, it is allowed to have access to the configuration files but not as the root user.
You can include an external configuration file inside `/etc/gitlab/gitlab.rb` by specifying the path to the file:

```ruby
from_file "/home/admin/external_gitlab.rb"
```

Code you include into `/etc/gitlab/gitlab.rb` using `from_file` runs with `root` privileges when you run `sudo gitlab-ctl reconfigure`.
Any configuration that is set in `/etc/gitlab/gitlab.rb` after `from_file` is included, takes precedence over the configuration from the included file.

## Store Git data in an alternative directory

By default, Omnibus GitLab stores the Git repository data under
`/var/opt/gitlab/git-data`. The repositories are stored in a subfolder called
`repositories`.

To change the location of the `git-data` parent directory:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   git_data_dirs({ "default" => { "path" => "/mnt/nas/git-data" } })
   ```

   You can also add more than one Git data directories:

   ```ruby
   git_data_dirs({
     "default" => { "path" => "/var/opt/gitlab/git-data" },
     "alternative" => { "path" => "/mnt/nas/git-data" }
   })
   ```

   The target directories and any of its subpaths must not be a symlink.

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

If you're running Gitaly on its own server remember to also include the
`gitaly_address` for each Git data directory. See
[the documentation on configuring Gitaly](https://docs.gitlab.com/ee/administration/gitaly/configure_gitaly.html#configure-gitaly-clients).

If you're not looking to move all repositories, but instead want to move specific
projects between existing repository storages, use the
[Edit Project API](https://docs.gitlab.com/ee/api/projects.html#edit-project)
endpoint and specify the `repository_storage` attribute.

## Change the name of the Git user or group

NOTE:
We do not recommend changing the user or group of an existing installation because it can cause unpredictable side-effects.

By default, Omnibus GitLab uses the user name `git` for Git GitLab Shell login,
ownership of the Git data itself, and SSH URL generation on the web interface.
Similarly, the `git` group is used for group ownership of the Git data.

To change the user and group:

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
Make sure that the new user can access the `repositories` and `uploads` directories.

## Specify numeric user and group identifiers

Omnibus GitLab creates users for GitLab, PostgreSQL, Redis, NGINX, etc. To
specify the numeric identifiers for these users:

1. Edit `/etc/gitlab/gitlab.rb`:

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

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Optional. If you're changing `user['uid']` and `user['gid']`, make sure to update the uid/guid of any files not managed by Omnibus directly, for example the logs:

```shell
find /var/log/gitlab -uid <old_uid> | xargs -I:: chown git ::
find /var/log/gitlab -gid <old_uid> | xargs -I:: chgrp git ::
find /var/opt/gitlab -uid <old_uid> | xargs -I:: chown git ::
find /var/opt/gitlab -gid <old_uid> | xargs -I:: chgrp git ::
```

## Disable user and group account management

By default, Omnibus GitLab creates system user and group accounts,
as well as keeping the information updated.
These system accounts run various components of the package.
Most users don't need to change this behavior.
However, if your system accounts are managed by other software, for example LDAP, you
might need to disable account management done by the GitLab package.

By default, the Omnibus GitLab package expects that following users and groups to exist:

| Linux user and group | Required                                | Description                                                          |
| -------------------- | --------------------------------------- | -------------------------------------------------------------------- |
| `git`                | Yes                                     | GitLab user/group                                                    |
| `gitlab-www`         | Yes                                     | Web server user/group                                                |
| `gitlab-redis`       | Only when using the packaged Redis      | Redis user/group for GitLab                                          |
| `gitlab-psql`        | Only when using the packaged PostgreSQL | PostgreSQL user/group                                                |
| `gitlab-prometheus`  | Yes                                     | Prometheus user/group for Prometheus monitoring and various exporters|
| `mattermost`         | Only when using GitLab Mattermost       | GitLab Mattermost user/group                                         |
| `registry`           | Only when using GitLab Registry         | GitLab Registry user/group                                           |
| `gitlab-consul`      | Only when using GitLab Consul           | GitLab Consul user/group                                             |

To disable user and group accounts management:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   manage_accounts['enable'] = false
   ```

1. Optional. You can also use different user/group names, but then you must specify the user/group details:

   ```ruby
   # GitLab
   user['username'] = "custom-gitlab"
   user['group'] = "custom-gitlab"
   user['shell'] = "/bin/sh"
   user['home'] = "/var/opt/custom-gitlab"

   # Web server
   web_server['username'] = 'webserver-gitlab'
   web_server['group'] = 'webserver-gitlab'
   web_server['shell'] = '/bin/false'
   web_server['home'] = '/var/opt/gitlab/webserver'

   # Postgresql (not needed when using external Postgresql)
   postgresql['username'] = "postgres-gitlab"
   postgresql['group'] = "postgres-gitlab"
   postgresql['shell'] = "/bin/sh"
   postgresql['home'] = "/var/opt/postgres-gitlab"

   # Redis (not needed when using external Redis)
   redis['username'] = "redis-gitlab"
   redis['group'] = "redis-gitlab"
   redis['shell'] = "/bin/false"
   redis['home'] = "/var/opt/redis-gitlab"

   # And so on for users/groups for GitLab Mattermost
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Move the home directory for a user

For the GitLab user, we recommended that the home directory
is set in local disk and not on a shared storage like NFS, for better performance. When setting it in
NFS, Git requests must make another network request to read the Git
configuration and this increases latency in Git operations.

To move an existing home directory, GitLab services need to be stopped and some downtime is required:

1. Stop GitLab:

   ```shell
   gitlab-ctl stop
   ```

1. Stop the runit server:

   ```shell
   sudo systemctl stop gitlab-runsvdir
   ```

1. Change the home directory:

   ```shell
   usermod -d /path/to/home <username>
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

The Omnibus GitLab package takes care of creating all the necessary directories
with the correct ownership and permissions, as well as keeping this updated.

Some of the directories hold large amounts of data, so in certain setups,
those directories are most likely mounted on an NFS (or some other) share.

Some types of mounts don't allow automatic creation of directories by the root user
(default user for initial setup), for example NFS with `root_squash` enabled on the
share. To work around this, the Omnibus GitLab package attempts to create
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

The Omnibus GitLab package expects these directories to exist
on the file system. It is up to you to create and set correct
permissions if this setting is set.

Enabling this setting prevents the creation of the following directories:

| Default location                                       | Permissions   | Ownership        | Purpose                            |
|--------------------------------------------------------|---------------|------------------|------------------------------------|
| `/var/opt/gitlab/git-data`                             | `0700`        | `git:git`        | Holds repositories directory       |
| `/var/opt/gitlab/git-data/repositories`                | `2770`        | `git:git`        | Holds Git repositories             |
| `/var/opt/gitlab/gitlab-rails/shared`                  | `0751`        | `git:gitlab-www` | Holds large object directories     |
| `/var/opt/gitlab/gitlab-rails/shared/artifacts`        | `0700`        | `git:git`        | Holds CI artifacts                 |
| `/var/opt/gitlab/gitlab-rails/shared/external-diffs`   | `0700`        | `git:git`        | Holds external merge request diffs |
| `/var/opt/gitlab/gitlab-rails/shared/lfs-objects`      | `0700`        | `git:git`        | Holds LFS objects                  |
| `/var/opt/gitlab/gitlab-rails/shared/packages`         | `0700`        | `git:git`        | Holds package repository           |
| `/var/opt/gitlab/gitlab-rails/shared/dependency_proxy` | `0700`        | `git:git`        | Holds dependency proxy             |
| `/var/opt/gitlab/gitlab-rails/shared/terraform_state`  | `0700`        | `git:git`        | Holds terraform state              |
| `/var/opt/gitlab/gitlab-rails/shared/ci_secure_files`  | `0700`        | `git:git`        | Holds uploaded secure files        |
| `/var/opt/gitlab/gitlab-rails/shared/pages`            | `0750`        | `git:gitlab-www` | Holds user pages                   |
| `/var/opt/gitlab/gitlab-rails/uploads`                 | `0700`        | `git:git`        | Holds user attachments             |
| `/var/opt/gitlab/gitlab-ci/builds`                     | `0700`        | `git:git`        | Holds CI build logs                |
| `/var/opt/gitlab/.ssh`                                 | `0700`        | `git:git`        | Holds authorized keys              |

To disable the management of storage directories:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   manage_storage_directories['enable'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Start Omnibus GitLab services only after a given file system is mounted

If you want to prevent Omnibus GitLab services (NGINX, Redis, Puma, etc.)
from starting before a given file system is mounted:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # wait for /var/opt/gitlab to be mounted
   high_availability['mountpoint'] = '/var/opt/gitlab'
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configure the runtime directory

When Prometheus monitoring is enabled, the GitLab Exporter conducts measurements
of each Puma process (Rails metrics). Every Puma process needs to write
a metrics file to a temporary location for each controller request.
Prometheus then collects all these files and process their values.

To avoid creating disk I/O, the Omnibus GitLab package uses a
runtime directory.

During `reconfigure`, the package check if `/run` is a `tmpfs` mount.
If it is not, the following warning is shown and Rails metrics is disabled:

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

You can configure a [failed authentication ban](https://docs.gitlab.com/ee/security/rate_limits.html#failed-authentication-ban-for-git-and-container-registry)
for Git and the container registry:

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

The following settings can be configured:

- `enabled`: By default this is set to `false`. Set this to `true` to enable Rack Attack.
- `ip_whitelist`: IPs to not block. They must be formatted as strings in a
  Ruby array. CIDR notation is supported in GitLab 12.1 and later.
  For example, `["127.0.0.1", "127.0.0.2", "127.0.0.3", "192.168.0.1/24"]`.
- `maxretry`: The maximum amount of times a request can be made in the
  specified time.
- `findtime`: The maximum amount of time that failed requests can count against an IP
  before it's added to the denylist (in seconds).
- `bantime`: The total amount of time that an IP is blocked (in seconds).

## Disable automatic cache cleaning during installation

If you have large GitLab installation, you might not want to run a `rake cache:clear` task
as it can take a long time to finish. By default, the cache clear task runs automatically
during reconfigure.

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

[Sentry](https://sentry.io) is an error reporting and logging tool which can be
used as SaaS or on premise. It's Open Source, and you can
[browse its source code repositories](https://github.com/getsentry).

To configure Sentry:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['sentry_enabled'] = true
   gitlab_rails['sentry_dsn'] = 'https://<key>@sentry.io/<project>'
   gitlab_rails['sentry_clientside_dsn'] = 'https://<key>@sentry.io/<project>'
   gitlab_rails['sentry_environment'] = 'production'
   ```

   The [Sentry environment](https://docs.sentry.io/product/sentry-basics/environments/)
   can be used to track errors and issues across several deployed GitLab
   environments, for example lab, development, staging, production.

1. Optional. To set custom [Sentry tags](https://docs.sentry.io/product/sentry-basics/guides/enrich-data/)
   on every event sent from a particular server, the `GITLAB_SENTRY_EXTRA_TAGS`
   environment variable can be set. This variable is a JSON-encoded hash representing any
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
[the Mozilla documentation on CSP](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) for more
details.

GitLab 12.2 added support for
[CSP and nonce-source with inline JavaScript](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/script-src).
It is [not configured on by default yet](https://gitlab.com/gitlab-org/gitlab/-/issues/30720).

NOTE:
Improperly configuring the CSP rules could prevent GitLab from working
properly. Before rolling out a policy, you may also want to change
`report_only` to `true` to test the configuration.

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

   [In GitLab 14.9 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80303), secure default values
   are used for the directives that aren't explicitly configured.

   To unset a CSP directive, set a value of `false`.

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Set initial root password on installation

The initial password for the administrator user `root` can be set at the installation time
with the `GITLAB_ROOT_PASSWORD` environment variable:

```shell
sudo GITLAB_ROOT_PASSWORD="<strongpassword>" EXTERNAL_URL="http://gitlab.example.com" apt install gitlab-ee
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

If using a custom external proxy such as apache, it may be necessary to add the localhost. Administrators should add filters to the external proxy to mitigate potential HTTP Host header attacks passed through the proxy to workhorse.

```ruby
gitlab_rails['allowed_hosts'] = ['gitlab.example.com', '127.0.0.1']
```

## Related topics

- [Disable impersonation](https://docs.gitlab.com/ee/api/index.html#disable-impersonation)
- [Set up LDAP sign-in](https://docs.gitlab.com/ee/administration/auth/ldap/index.html)
- [Smartcard authentication](https://docs.gitlab.com/ee/administration/auth/smartcard.html)
- [Set up NGINX](nginx.md) for things like:
  - Set up HTTPS
  - Redirect `HTTP` requests to `HTTPS`
  - Change the default port and the SSL certificate locations
  - Set the NGINX listen address or addresses
  - Insert custom NGINX settings into the GitLab server block
  - Insert custom settings into the NGINX configuration
  - Enable `nginx_status`
- [Use a non-packaged web-server](nginx.md#using-a-non-bundled-web-server)
- [Use a non-packaged PostgreSQL database management server](database.md)
- [Use a non-packaged Redis instance](redis.md)
- [Add `ENV` vars to the GitLab runtime environment](environment-variables.md)
- [Changing `gitlab.yml` and `application.yml` settings](gitlab.yml.md)
- [Send application email via SMTP](smtp.md)
- [Set up OmniAuth (Google, Twitter, GitHub login)](https://docs.gitlab.com/ee/integration/omniauth.html)
- [Adjust Puma settings](https://docs.gitlab.com/ee/administration/operations/puma.html)

## Troubleshooting

### Relative URL troubleshooting

If you notice any issues with GitLab assets appearing broken after moving to a
relative URL configuration (like missing images or unresponsive components),
please raise an issue in [GitLab](https://gitlab.com/gitlab-org/gitlab)
with the `Frontend` label.

### `Mixlib::ShellOut::ShellCommandFailed: linux_user[GitLab user and group]`

When [moving the home directory for a user](#move-the-home-directory-for-a-user),
if the runit service is not stopped and the home directories are not manually
moved for the user, GitLab will encounter an error while reconfiguring:

```plaintext
account[GitLab user and group] (gitlab::users line 28) had an error: Mixlib::ShellOut::ShellCommandFailed: linux_user[GitLab user and group] (/opt/gitlab/embedded/cookbooks/cache/cookbooks/package/resources/account.rb line 51) had an error: Mixlib::ShellOut::ShellCommandFailed: Expected process to exit with [0], but received '8'
---- Begin output of ["usermod", "-d", "/var/opt/gitlab", "git"] ----
STDOUT:
STDERR: usermod: user git is currently used by process 1234
---- End output of ["usermod", "-d", "/var/opt/gitlab", "git"] ----
Ran ["usermod", "-d", "/var/opt/gitlab", "git"] returned 8
```

Make sure to stop `runit` before moving the home directory.
