---
stage: GitLab Delivery
group: Build, Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting Linux package installation
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Use this page to learn about common issues users can encounter when installing Linux packages.

## Hash Sum mismatch when downloading packages

`apt-get install` outputs something like:

```plaintext
E: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/pool/trusty/main/g/gitlab-ce/gitlab-ce_8.1.0-ce.0_amd64.deb  Hash Sum mismatch
```

Run the following to fix this:

```shell
sudo rm -rf /var/lib/apt/lists/partial/*
sudo apt-get update
sudo apt-get clean
```

See [Joe Damato's from Packagecloud comment](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/628#note_1824330) and [his blog article](https://blog.packagecloud.io/apt-hash-sum-mismatch/) for more context.

Another workaround is to download the package manually by selecting the correct package from the [CE packages](https://packages.gitlab.com/gitlab/gitlab-ce) or [EE packages](https://packages.gitlab.com/gitlab/gitlab-ee) repository:

```shell
curl -LJO "https://packages.gitlab.com/gitlab/gitlab-ce/packages/ubuntu/trusty/gitlab-ce_8.1.0-ce.0_amd64.deb/download"
dpkg -i gitlab-ce_8.1.0-ce.0_amd64.deb
```

## Installation on openSUSE and SLES platforms warns about unknown key signature

Linux packages are [signed with GPG keys](update/package_signatures.md) in
addition to the package repositories providing signed metadata. This ensures
authenticity and integrity of the packages that are distributed to the users.
However, the package manager used in openSUSE and SLES operating systems may
sometime raise false warnings with these signatures, similar to:

```plaintext
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no):
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no): yes
```

This is a known bug with zypper where zypper ignores the `gpgkey` keyword in the
repository configuration file. With later versions of Packagecloud, there may be
improvements regarding this, but currently users have to manually agree to
package installation.

So, in openSUSE or SLES systems, if such a warning is displayed, it is safe to
continue installation.

## apt/yum complains about GPG signatures

You already have GitLab repositories configured, and ran `apt-get update`,
`apt-get install` or `yum install`, and saw errors like the following:

```plaintext
The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
```

or

```plaintext
https://packages.gitlab.com/gitlab/gitlab-ee/el/7/x86_64/repodata/repomd.xml: [Errno -1] repomd.xml signature could not be verified for gitlab-ee
```

This is because on April 2020, GitLab changed the GPG keys used to sign
metadata of the apt and yum repositories available through the
[Packagecloud instance](https://packages.gitlab.com). If you see this error, it
generally means you do not have the public keys currently used to sign
repository metadata in your keyring. To fix this error, follow the
[steps to fetch the new key](update/package_signatures.md#fetch-latest-signing-key).

## Reconfigure shows an error: `NoMethodError - undefined method '[]=' for nil:NilClass`

You ran `sudo gitlab-ctl reconfigure` or package upgrade triggered the
reconfigure which produced error similar to:

```plaintext
 ================================================================================
 Recipe Compile Error in /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/default.rb
 ================================================================================

NoMethodError
-------------
undefined method '[]=' for nil:NilClass

Cookbook Trace:
---------------
  /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/config.rb:21:in 'from_file'
  /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/default.rb:26:in 'from_file'

Relevant File Content:
```

This error is thrown when `/etc/gitlab/gitlab.rb` configuration file contains
configuration that is invalid or unsupported. Double check that there are no
typos or that the configuration file does not contain obsolete configuration.

You can check the latest available configuration by using `sudo gitlab-ctl diff-config` or check the latest [`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).

## GitLab is unreachable in my browser

Try [specifying](settings/configuration.md#configure-the-external-url-for-gitlab) an `external_url` in
`/etc/gitlab/gitlab.rb`. Also check your firewall settings; port 80 (HTTP) or
443 (HTTPS) might be closed on your GitLab server.

Note that specifying the `external_url` for GitLab, or any other bundled service (Registry and
Mattermost) doesn't follow the `key=value` format that other parts of `gitlab.rb` follow. Make sure
that you have them set in the following format:

```ruby
external_url "https://gitlab.example.com"
registry_external_url "https://registry.example.com"
mattermost_external_url "https://mattermost.example.com"
```

{{< alert type="note" >}}

Don't add the equal sign (`=`) between `external_url` and the value.

{{< /alert >}}

## Emails are not being delivered

To test email delivery you can create a new GitLab account for an email that is
not used in your GitLab instance yet.

If necessary, you can modify the 'From' field of the emails sent by GitLab with
the following setting in `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

## TCP ports for GitLab services are already taken

By default, Puma listens at TCP address 127.0.0.1:8080. NGINX
listens on port 80 (HTTP) and/or 443 (HTTPS) on all interfaces.

The ports for Redis, PostgreSQL and Puma can be overridden in
`/etc/gitlab/gitlab.rb` as follows:

```ruby
redis['port'] = 1234
postgresql['port'] = 2345
puma['port'] = 3456
```

For NGINX port changes please see [Setting the NGINX listen port](settings/nginx.md#set-the-nginx-listen-port).

## Git user does not have SSH access

### SELinux-enabled systems

On SELinux-enabled systems the Git user's `.ssh` directory or its contents can
get their security context messed up. You can fix this by running `sudo
gitlab-ctl reconfigure`, which sets the `gitlab_shell_t` security context on
`/var/opt/gitlab/.ssh`.

To improve this behavior, we set the context permanently using
`semanage`. The runtime dependency `policycoreutils-python` has been added to the
RPM package for RHEL based operating systems in order to ensure the `semanage`
command is available.

#### Diagnose and resolve SELinux issues

Linux packages detect default path changes in `/etc/gitlab/gitlab.rb` and should apply
the correct file contexts.

{{< alert type="note" >}}

From GitLab 16.10 forward, administrators can try `gitlab-ctl apply-sepolicy`
to automatically fix SELinux issues. Consult
`gitlab-ctl apply-sepolicy --help` for runtime options.

{{< /alert >}}

For installations using custom data path configuration,
the administrator may have to manually resolve SELinux issues.

Data paths may be altered via `gitlab.rb`, however, a common scenario forces the
use of `symlink` paths. Administrators should be cautious, because `symlink` paths are
not supported for all scenarios, such as [Gitaly data paths](settings/configuration.md#store-git-data-in-an-alternative-directory).

For example, if `/data/gitlab` replaced `/var/opt/gitlab` as the base data directory, the following fixes the security context:

```shell
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/.ssh/
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/.ssh/authorized_keys
sudo restorecon -Rv /data/gitlab/
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/gitlab-shell/config.yml
sudo restorecon -Rv /data/gitlab/gitlab-shell/
sudo semanage fcontext -a -t gitlab_shell_t /data/gitlab/gitlab-rails/etc/gitlab_shell_secret
sudo restorecon -Rv /data/gitlab/gitlab-rails/
sudo semanage fcontext --list | grep /data/gitlab/
```

After the policies are applied, you can verify the SSH access is working
by getting the welcome message:

```shell
ssh -T git@gitlab-hostname
```

### All systems

The Git user is created, by default, with a locked password, shown by `'!'` in
/etc/shadow. Unless "UsePam yes" is enabled, the OpenSSH daemon prevents the
Git user from authenticating even with SSH keys. An alternative secure solution
is to unlock the password by replacing `'!'` with `'*'` in `/etc/shadow`. The Git
user is still unable to change the password because it runs in a restricted
shell and the `passwd` command for non-superusers requires entering the current
password prior to a new password. The user cannot enter a password that matches
`'*'`, which means the account continues to not have a password.

Keep in mind that the Git user must have access to the system so please review
your security settings at `/etc/security/access.conf` and make sure the Git user
is not blocked.

## Error: `FATAL: could not create shared memory segment: Cannot allocate memory`

The packaged PostgreSQL instance tries to allocate 25% of total memory as
shared memory. On some Linux (virtual) servers, there is less shared memory
available, which prevents PostgreSQL from starting. In
`/var/log/gitlab/postgresql/current`:

```plaintext
  1885  2014-08-08_16:28:43.71000 FATAL:  could not create shared memory segment: Cannot allocate memory
  1886  2014-08-08_16:28:43.71002 DETAIL:  Failed system call was shmget(key=5432001, size=1126563840, 03600).
  1887  2014-08-08_16:28:43.71003 HINT:  This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory or swap space, or exceeded your kernel's SHMALL parameter.  You can either reduce the request size or reconfigure the kernel with larger SHMALL.  To reduce the request size (currently 1126563840 bytes), reduce PostgreSQL's shared memory usage, perhaps by reducing shared_buffers or max_connections.
  1888  2014-08-08_16:28:43.71004       The PostgreSQL documentation contains more information about shared memory configuration.
```

You can manually lower the amount of shared memory PostgreSQL tries to allocate
in `/etc/gitlab/gitlab.rb`:

```ruby
postgresql['shared_buffers'] = "100MB"
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

## Error: `FATAL: could not open shared memory segment "/PostgreSQL.XXXXXXXXXX": Permission denied`

By default, PostgreSQL tries to detect the shared memory type to use. If you don't
have shared memory enabled, you might see this error in `/var/log/gitlab/postgresql/current`.
To fix this, you can disable PostgreSQL's shared memory detection. Set the
following value in `/etc/gitlab/gitlab.rb`:

```ruby
postgresql['dynamic_shared_memory_type'] = 'none'
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

## Error: `FATAL: remaining connection slots are reserved for non-replication superuser connections`

PostgreSQL has a setting for the maximum number of the concurrent connections
to the database server. If you see this error, it means that your GitLab instance is trying to exceed
this limit on the number of concurrent connections.

To check maximum connections and available connections:

1. Open a PostgreSQL database console:

   ```shell
   sudo gitlab-psql
   ```

1. Execute the following query in the database console:

   ```sql
   SELECT
     (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') AS max_connections,
     COUNT(*) AS current_connections,
     COUNT(*) FILTER (WHERE state = 'active') AS active_connections,
     ((SELECT setting::int FROM pg_settings WHERE name = 'max_connections') - COUNT(*)) AS remaining_connections
   FROM pg_stat_activity;
   ```

To fix this problem, you have two options:

- Either increase the max connections value:

  1. Edit `/etc/gitlab/gitlab.rb`:

     ```ruby
     postgresql['max_connections'] = 600
     ```

  1. Reconfigure GitLab:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

- Or, you can consider [using PgBouncer](https://docs.gitlab.com/administration/postgresql/pgbouncer/) which is a connection pooler for PostgreSQL.

## Reconfigure complains about the GLIBC version

```shell
$ gitlab-ctl reconfigure

/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.14' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.17' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
```

This can happen if the Linux package you installed was built for a different
OS release than the one on your server. Double-check that you downloaded and
installed the correct Linux package for your operating system.

## Reconfigure fails to create the Git user

This can happen if you run `sudo gitlab-ctl reconfigure` as the Git user.
Switch to another user.

More importantly: do not give sudo rights to the Git user or to any of the
other users used by the Linux package. Bestowing unnecessary privileges on a
system user weakens the security of your system.

## Failed to modify kernel parameters with sysctl

If sysctl cannot modify the kernel parameters you could possibly get an error with the following stack trace:

```plaintext
 * execute[sysctl] action run
================================================================================
Error executing action `run` on resource 'execute[sysctl]'
================================================================================


Mixlib::ShellOut::ShellCommandFailed
------------------------------------
Expected process to exit with [0], but received '255'
---- Begin output of /sbin/sysctl -p /etc/sysctl.conf ----
```

This is unlikely to happen with non virtualized machines but on a VPS with virtualization like openVZ, container might not have the required module enabled
or container doesn't have access to kernel parameters.

Try [enabling the module](https://serverfault.com/questions/477718/sysctl-p-etc-sysctl-conf-returns-error) on which sysctl errored out.

There is a reported workaround described in [this issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/361) which requires editing the GitLab' internal recipe by supplying the switch which ignores failures. Ignoring errors can have unexpected side effects on the performance of your GitLab server, so it isn't recommended to do so.

Another variation of this error reports the file system is read-only and shows following stack trace:

```plaintext
 * execute[load sysctl conf] action run
    [execute] sysctl: setting key "kernel.shmall": Read-only file system
              sysctl: setting key "kernel.shmmax": Read-only file system

    ================================================================================
    Error executing action `run` on resource 'execute[load sysctl conf]'
    ================================================================================

    Mixlib::ShellOut::ShellCommandFailed
    ------------------------------------
    Expected process to exit with [0], but received '255'
    ---- Begin output of cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p - ----
    STDOUT:
    STDERR: sysctl: setting key "kernel.shmall": Read-only file system
    sysctl: setting key "kernel.shmmax": Read-only file system
    ---- End output of cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p - ----
    Ran cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p - returned 255
```

This error is also reported to occur in virtual machines only, and the recommended workaround is to set the values in the host. The values needed for GitLab can be found inside the file `/opt/gitlab/embedded/etc/90-omnibus-gitlab.conf` in the virtual machine. After setting these values in `/etc/sysctl.conf` file in the host OS, run `cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p -` on the host. Then try running `gitlab-ctl reconfigure` inside the virtual machine. It should detect that the kernel is already running with the necessary settings, and not raise any errors.

You may have to repeat this process for other lines. For example, reconfigure fails three times, after having added something like this to `/etc/sysctl.conf`:

```plaintext
kernel.shmall = 4194304
kernel.sem = 250 32000 32 262
net.core.somaxconn = 2048
kernel.shmmax = 17179869184
```

You may find it easier to look at the line in the Chef output than to find the file (since the file
is different for each error). See the last line of this snippet.

```plaintext
* file[create /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf kernel.shmall] action create
  - create new file /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf
  - update content in file /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf from none to 6d765d
  --- /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf 2017-11-28 19:09:46.864364952 +0000
  +++ /opt/gitlab/embedded/etc/.chef-90-omnibus-gitlab-kernel.shmall.conf kernel.shmall20171128-13622-sduqoj 2017-11-28 19:09:46.864364952 +0000
  @@ -1 +1,2 @@
  +kernel.shmall = 4194304
```

## I am unable to install GitLab without root access

Occasionally people ask if they can install GitLab without root access.
This is problematic for several reasons.

### Installing the `.deb` or `.rpm`

To our knowledge there is no clean way to install Debian or RPM
packages as a non-privileged user. You cannot install Linux package
RPM's because the build process does not create source RPM's.

### Hassle-free hosting on port `80` and `443`

The most common way to deploy GitLab is to have a web server
(NGINX/Apache) running on the same server as GitLab, with the web
server listening on a privileged (below-1024) TCP port. In
Linux packages, we provide this convenience by bundling an
automatically configured NGINX service that needs to run its master
process as root to open ports `80` and `443`.

If this is problematic, administrators installing GitLab can disable
the bundled NGINX service, but this puts the burden on them to keep
the NGINX configuration in tune with GitLab during application
updates.

### Isolation between services

Bundled services in Linux packages (GitLab itself, NGINX, PostgreSQL,
Redis, Mattermost) are isolated from each other using Unix user
accounts. Creating and managing these user accounts requires root
access. By default, Linux packages create the required Unix
accounts during `gitlab-ctl reconfigure` but that behavior can be
[disabled](settings/configuration.md#disable-user-and-group-account-management).

In principle, Linux packages could do with only 2 user accounts (one
for GitLab and one for Mattermost) if we give each application its own
runit (runsvdir), PostgreSQL and Redis process. But this would be a
major change in the `gitlab-ctl reconfigure` Chef code and it would
probably create major upgrade pain for all existing Linux package
installations. We would probably have to rearrange the directory
structure under `/var/opt/gitlab`.

### Tweaking the operating system for better performance

During `gitlab-ctl reconfigure` we set and install several sysctl
tweaks to improve PostgreSQL performance and increase connection limits.
This can only be done with root access.

## `gitlab-rake assets:precompile` fails with `Permission denied`

Some users report that running `gitlab-rake assets:precompile` does not work
with the Linux packages. The short answer to this is: do not run that
command, it is only for GitLab installations from source.

The GitLab web interface uses CSS and JavaScript files, called "assets" in Ruby
on Rails-speak. In the [upstream GitLab repository](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets)
these files are stored in a developer-friendly way: easy to read and edit. When
you are a normal user of GitLab, you do not want these files to be in the
developer friendly format however because that makes GitLab slow. This is why
part of the GitLab setup process is to convert the assets from a
developer-friendly format to an end-user friendly (compact, fast) format; that
is what the `rake assets:precompile` script is for.

When you install GitLab from source (which was the only way to do it before we
had Linux packages), you must convert the assets on your GitLab server
every time you update GitLab. People used to overlook this step and there are
still posts, comments and mails out there on the internet where users recommend
each other to run `rake assets:precompile` (which has now been renamed
`gitlab:assets:compile`). With the Linux packages things are different. When
we build the package, [we compile the assets for you](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/1cfe925e0c015df7722bb85eddc0b4a3b59c1211/config/software/gitlab-rails.rb#L74).
When you install GitLab with a Linux package, the converted assets are
already there! That is why you do not need to run `rake assets:precompile` when
you install GitLab from a package.

When `gitlab-rake assets:precompile` fails with a permission error it fails for
a good reason from a security standpoint: the fact that the assets cannot
easily be rewritten makes it harder for an attacker to use your GitLab server
to serve evil JavaScript code to the visitors of your GitLab server.

If you want to run GitLab with custom JavaScript or CSS code you are probably
better off running GitLab from source, or building your own packages.

If you really know what you are doing,
you can execute `gitlab-rake gitlab:assets:compile` like this:

```shell
sudo NO_PRIVILEGE_DROP=true USE_DB=false gitlab-rake gitlab:assets:clean gitlab:assets:compile
# user and path might be different if you changed the defaults of
# user['username'], user['group'] and gitlab_rails['dir'] in gitlab.rb
sudo chown -R git:git /var/opt/gitlab/gitlab-rails/tmp/cache
```

## Error: `Short read or OOM loading DB`

Try [cleaning the old Redis session](https://docs.gitlab.com/administration/operations/).

## Error: `The requested URL returned error: 403`

When trying to install GitLab using the apt repo if you receive an error similar to:

```shell
W: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/DISTRO/dists/CODENAME/main/source/Sources  The requested URL returned error: 403
```

check if there is a repository cacher in front of your server, like for example `apt-cacher-ng`.

Add the following line to apt-cacher-ng config (for example in `/etc/apt-cacher-ng/acng.conf`):

```shell
PassThroughPattern: (packages\.gitlab\.com|packages-gitlab-com\.s3\.amazonaws\.com|*\.cloudfront\.net)
```

Read more about `apt-cacher-ng` and the reasons why this change is needed [on the packagecloud blog](https://blog.packagecloud.io/using-apt-cacher-ng-with-ssl-tls/).

## Using self signed certificate or custom certificate authorities

If you are installing GitLab in an isolated network with custom certificate authorities or using self-signed certificate make sure that the certificate can be reached by GitLab. Not doing so will cause errors like:

```shell
Faraday::SSLError (SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed)
```

when GitLab tries to connect with the internal services like GitLab Shell.

To fix these errors, see the [Install Custom Public Certificates](settings/ssl/_index.md#install-custom-public-certificates) section.

## Error: `proxyRoundTripper: XXX failed with: "net/http: timeout awaiting response headers"`

If GitLab Workhorse doesn't receive an answer from
GitLab within 1 minute (default), it will serve a 502 page.

There are various reasons why the request might timeout, perhaps user
was loading a very large diff or similar.

You can increase the default timeout value by setting the value in `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_workhorse['proxy_headers_timeout'] = "2m0s"
```

Save the file and [reconfigure GitLab](https://docs.gitlab.com/administration/restart_gitlab/#reconfigure-a-linux-package-installation) for the changes to take effect.

## The change you wanted was rejected

Most likely you have GitLab setup in an environment that has proxy in front
of GitLab and the proxy headers set in package by default are incorrect
for your environment.

See [Change the default proxy headers section of NGINX doc](settings/nginx.md#change-the-default-proxy-headers) for details on
how to override the default headers.

## Can't verify CSRF token authenticity Completed 422 Unprocessable

Most likely you have GitLab setup in an environment that has proxy in front
of GitLab and the proxy headers set in package by default are incorrect
for your environment.

See [Change the default proxy headers section of NGINX doc](settings/nginx.md#change-the-default-proxy-headers) for details on
how to override the default headers.

## Extension missing `pg_trgm`

[GitLab requires](https://docs.gitlab.com/install/postgresql_extensions/)
the PostgreSQL extension `pg_trgm`.
If you are using a Linux package with the bundled database, the extension
should be automatically enabled when you upgrade.

If you however, are using an external (non-packaged) database, you will need to
enable the extension manually. The reason for this is that Linux package instances
with an external database have no way of confirming if the extension exists,
and it also doesn't have a way of enabling the extension.

To fix this issue, you'll need to first install the `pg_trgm` extension.
The extension is located in the `postgresql-contrib` package. For Debian:

```shell
sudo apt-get install postgresql-contrib
```

After the extension is installed, access the `psql` as superuser and enable the
extension.

1. Access `psql` as superuser:

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

1. Enable the extension:

   ```plaintext
   CREATE EXTENSION pg_trgm;
   \q
   ```

1. Now run migrations again:

   ```shell
   sudo gitlab-rake db:migrate
   ```

---

If using Docker, you first need to access your container, then run the commands
above, and finally restart the container.

1. Access the container:

   ```shell
   docker exec -it gitlab bash
   ```

1. Run the commands above.

1. Restart the container:

   ```shell
   docker restart gitlab
   ```

## Error: `Errno::ENOMEM: Cannot allocate memory during backup or upgrade`

[GitLab requires](https://docs.gitlab.com/install/requirements/#memory)
2GB of available memory to run without errors. Having 2GB of memory installed may
not be enough depending on the resource usage of other processes on your server.
If GitLab runs fine when not upgrading or running a backup, then adding more swap
should solve your problem. If you see the server using swap during normal usage,
you can add more RAM to improve performance.

## NGINX error: `could not build server_names_hash, you should increase server_names_hash_bucket_size`

If your external URL for GitLab is longer than the default bucket size (64 bytes),
NGINX may stop working and show this error in the logs. To allow larger server
names, double the bucket size in `/etc/gitlab/gitlab.rb`:

```ruby
nginx['server_names_hash_bucket_size'] = 128
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

## Reconfigure fails due to `'root' cannot chown` with NFS root_squash

```shell
$ gitlab-ctl reconfigure

================================================================================
Error executing action `run` on resource 'ruby_block[directory resource: /gitlab-data/git-data]'
================================================================================

Errno::EPERM
------------
'root' cannot chown /gitlab-data/git-data. If using NFS mounts you will need to re-export them in 'no_root_squash' mode and try again.
Operation not permitted @ chown_internal - /gitlab-data/git-data
```

This can happen if you have directories mounted using NFS and configured in `root_squash`
mode. Reconfigure is not able to properly set the ownership of your directories. You
will need to switch to using `no_root_squash` in your NFS exports on the NFS server, or
[disable storage directory management](settings/configuration.md#disable-storage-directories-management)
and manage the permissions yourself.

## `gitlab-runsvdir` not starting

This applies to operating systems using systemd (e.g. Ubuntu 18.04+, CentOS, etc.).

`gitlab-runsvdir` starts during the `multi-user.target`
instead of `basic.target`. If you are having trouble starting this service
after upgrading GitLab, you may need to check that your system has properly
booted all the required services for `multi-user.target` via the command:

```shell
systemctl -t target
```

If everything is working properly, the output should show look something like this:

```plaintext
UNIT                   LOAD   ACTIVE SUB    DESCRIPTION
basic.target           loaded active active Basic System
cloud-config.target    loaded active active Cloud-config availability
cloud-init.target      loaded active active Cloud-init target
cryptsetup.target      loaded active active Encrypted Volumes
getty.target           loaded active active Login Prompts
graphical.target       loaded active active Graphical Interface
local-fs-pre.target    loaded active active Local File Systems (Pre)
local-fs.target        loaded active active Local File Systems
multi-user.target      loaded active active Multi-User System
network-online.target  loaded active active Network is Online
network-pre.target     loaded active active Network (Pre)
network.target         loaded active active Network
nss-user-lookup.target loaded active active User and Group Name Lookups
paths.target           loaded active active Paths
remote-fs-pre.target   loaded active active Remote File Systems (Pre)
remote-fs.target       loaded active active Remote File Systems
slices.target          loaded active active Slices
sockets.target         loaded active active Sockets
swap.target            loaded active active Swap
sysinit.target         loaded active active System Initialization
time-sync.target       loaded active active System Time Synchronized
timers.target          loaded active active Timers

LOAD   = Reflects whether the unit definition was properly loaded.
ACTIVE = The high-level unit activation state, i.e. generalization of SUB.
SUB    = The low-level unit activation state, values depend on unit type.

22 loaded units listed. Pass --all to see loaded but inactive units, too.
To show all installed unit files use 'systemctl list-unit-files'.
```

Every line should show `loaded active active`. As seen in the line below, if
you see `inactive dead`, this means there may be something wrong:

```plaintext
multi-user.target      loaded inactive dead   start Multi-User System
```

To examine which jobs may be queued by systemd, run:

```shell
systemctl list-jobs
```

If you see a `running` job, a service may be stuck and thus blocking GitLab
from starting. For example, some users have had trouble with Plymouth not
starting:

```plaintext
  1 graphical.target                     start waiting
107 plymouth-quit-wait.service           start running
  2 multi-user.target                    start waiting
169 ureadahead-stop.timer                start waiting
121 gitlab-runsvdir.service              start waiting
151 system-getty.slice                   start waiting
 31 setvtrgb.service                     start waiting
122 systemd-update-utmp-runlevel.service start waiting
```

In this case, consider uninstalling Plymouth.

## Init daemon detection in non-Docker container

In Docker containers, GitLab package detects existence of `/.dockerenv` file and
skips automatic detection of an init system. However, in non-Docker containers
(like containerd, cri-o, etc.), that file does not exist and package falls back
to sysvinit, and this can cause issues with installation. To prevent this, users
can explicitly disable init daemon detection by adding the following setting in
`gitlab.rb` file:

```ruby
package['detect_init'] = false
```

If using this configuration, runit service must be started before running
`gitlab-ctl reconfigure`, using the `runsvdir-start` command:

```shell
/opt/gitlab/embedded/bin/runsvdir-start &
```

## `gitlab-ctl reconfigure` hangs while using AWS Cloudformation

The GitLab systemd unit file by default uses `multi-user.target` for both `After`
and `WantedBy` fields. This is done to ensure service runs after `remote-fs` and
`network` targets, and thus GitLab will function properly.

However, this interacts poorly with [cloud-init](https://cloudinit.readthedocs.io/en/latest/)'s
own unit ordering, which is used by AWS Cloudformation.

To fix this, users can make use of `package['systemd_wanted_by']` and
`package['systemd_after']` settings in `gitlab.rb` to specify values needed for
proper ordering and run `sudo gitlab-ctl reconfigure`. After reconfigure has
completed, restart `gitlab-runsvdir` service for changes to take effect.

```shell
sudo systemctl restart gitlab-runsvdir
```

## Error: `Errno::EAFNOSUPPORT: Address family not supported by protocol - socket(2)`

When starting up GitLab, if an error similar to the following is observed:

```ruby
FATAL: Errno::EAFNOSUPPORT: Address family not supported by protocol - socket(2)
```

Check if the hostnames in use are resolvable and **IPv4**
addresses are returned:

```shell
getent hosts gitlab.example.com
# Example IPv4 output: 192.168.1.1 gitlab.example.com
# Example IPv6 output: 2002:c0a8:0101::c0a8:0101 gitlab.example.com

getent hosts localhost
# Example IPv4 output: 127.0.0.1 localhost
# Example IPv6 output: ::1 localhost
```

If an **IPv6** address format is returned, further check if
**IPv6** protocol support (keyword `ipv6`) is enabled on the
network interface:

```shell
ip addr # or 'ifconfig' on older operating systems
```

When **IPv6** network protocol support is absent or disabled,
but the DNS configuration resolves the hostnames as **IPv6** addresses,
GitLab services will be unable to establish network connections.

This can be resolved by fixing the DNS configurations (or `/etc/hosts`) to
resolve the hosts to an **IPv4** address instead of **IPv6**.

<!-- markdownlint-disable line-length -->

## Error: `URI::InvalidComponentError (bad component(expected host component: my_url.tld)` when `external_url` contains underscores

If you have set `external_url` with underscores (for example `https://my_company.example.com`), you may face the following issues with CI/CD:

- It will not be possible to open project's **Settings > CI/CD** page.
- Runners will not pick up jobs and will fail with an error 500.

If that's the case, [`production.log`](https://docs.gitlab.com/administration/logs/#productionlog) will contain the following error:

```plaintext
Completed 500 Internal Server Error in 50ms (ActiveRecord: 4.9ms | Elasticsearch: 0.0ms | Allocations: 17672)

URI::InvalidComponentError (bad component(expected host component): my_url.tld):

lib/api/helpers/related_resources_helpers.rb:29:in `expose_url'
ee/app/controllers/ee/projects/settings/ci_cd_controller.rb:19:in `show'
ee/lib/gitlab/ip_address_state.rb:10:in `with'
ee/app/controllers/ee/application_controller.rb:44:in `set_current_ip_address'
app/controllers/application_controller.rb:486:in `set_current_admin'
lib/gitlab/session.rb:11:in `with_session'
app/controllers/application_controller.rb:477:in `set_session_storage'
lib/gitlab/i18n.rb:73:in `with_locale'
lib/gitlab/i18n.rb:79:in `with_user_locale'
```

As a workaround, avoid using underscores in `external_url`. There is an open issue about it: [Setting `external_url` with underscore results in a broken GitLab CI/CD functionality](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6077).

<!-- markdownlint-enable line-length -->

## Upgrade fails with `timeout: run: /opt/gitlab/service/gitaly` error

If the package upgrade fails when running reconfigure with the following error,
check that all Gitaly processes are stopped and then rerun `sudo gitlab-ctl reconfigure`.

```plaintext
---- Begin output of /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly ----
STDOUT: timeout: run: /opt/gitlab/service/gitaly: (pid 4886) 15030s, got TERM
STDERR:
---- End output of /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly ----
Ran /opt/gitlab/embedded/bin/sv restart /opt/gitlab/service/gitaly returned 1
```

Refer to [issue 341573](https://gitlab.com/gitlab-org/gitlab/-/issues/341573) for more details.

## Reconfigure is stuck when re-installing GitLab

Because of a [known issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7776), you can see the reconfigure process stuck at
`ruby_block[wait for logrotate service socket] action run` after uninstalling GitLab and trying to install it again. This problem occurs when one of the `systemctl` commands are
not executed when [uninstalling GitLab](https://docs.gitlab.com/install/package/#uninstall-the-linux-package).

To resolve this issue:

- Make sure you followed all the steps when uninstalling GitLab and perform them if necessary.
- Follow the workaround in [issue 7776](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7776).

## Mirroring the GitLab `yum` repository with Pulp or Red Hat Satellite fails

Direct mirroring of the Linux package `yum` repositories located at <https://packages.gitlab.com/gitlab/> with [Pulp](https://pulpproject.org/) or
[Red Hat Satellite](https://www.redhat.com/en/technologies/management/satellite) fails
when syncing. Different errors are caused by different software:

- Pulp 2 or Satellite < 6.10 fails with `"Malformed repository: metadata is specified for different set of packages in filelists.xml and in other.xml"` error.
- Satellite 6.10 fails with `"pkgid"` error.
- Pulp 3 or Satellite > 6.10 seems to succeed, but only the repository metadata is synced.

These sync failures are caused by issues with the metadata in the GitLab `yum`
mirror repository. This metadata includes a `filelists.xml.gz` file that
normally includes a list of files for every RPM in the repository. The GitLab
`yum` repository leaves this file mostly empty to work around a size issue that
would be caused if the file was fully populated.

Each GitLab RPM contains an enormous number of files, which when multiplied by
the large number of RPMs in the repository, would result in a huge
`filelists.xml.gz` file if it was fully populated. Because of storage and build
constraints, we create the file but do not populate it. The empty file causes
Pulp and RedHat Satellite (which uses Pulp) repository mirroring of the file to
fail.

Refer to [issue 2766](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/2766) for details.

### Work around the issue

To work around the issue:

1. Use an alternative RPM repository mirroring tool like `reposync` or
   `createrepo` to make a local copy of the official GitLab `yum` repository. These
   tools recreate the repository metadata in the local data, which includes
   creating a fully-populated `filelists.xml.gz` file.
1. Point Pulp or Satellite at the local mirror.

### Local mirror example

The following is an example of how to do local mirroring. The example uses:

- [Apache](https://httpd.apache.org/) as the web server for the repository.
- [`reposync`](https://dnf-plugins-core.readthedocs.io/en/latest/reposync.html)
  and [`createrepo`](http://createrepo.baseurl.org/) to sync the GitLab
  repository to the local mirror. This local mirror can then be used as a source
  for Pulp or RedHat Satellite. You can use other tools like
  [Cobbler](https://cobbler.github.io/) as well.

In this example:

- The local mirror is running on a `RHEL 8`, `Rocky 8`, or `AlmaLinux 8` system.
- The host name used for the web-server is `mirror.example.com`.
- Pulp 3 syncs from the local mirror.
- Mirroring is of the [GitLab Enterprise Edition repository](https://packages.gitlab.com/gitlab/gitlab-ee).

#### Create and configure an Apache server

The following example shows how to install and configure a basic Apache 2
server to host one or more Yum repository mirrors.
Consult the [Apache](https://httpd.apache.org/) documentation for details on
configuring and securing your web server.

1. Install `httpd`:

   ```shell
   sudo dnf install httpd
   ```

1. Add a `Directory` stanza to `/etc/httpd/conf/httpd.conf`:

   ```apache
   <Directory "/var/www/html/repos">
   Options All Indexes FollowSymLinks
   Require all granted
   </Directory>
   ```

1. Complete the `httpd` configuration:

   ```shell
   sudo rm -f /etc/httpd/conf.d/welcome.conf
   sudo mkdir /var/www/html/repos
   sudo systemctl enable httpd --now
   ```

#### Get the mirrored Yum repository URL

1. Install the GitLab repository `yum` configuration file:

   ```shell
   curl "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh" | sudo bash
   sudo dnf config-manager --disable gitlab_gitlab-ee gitlab_gitlab-ee-source
   ```

1. Get the repository URL:

   ```shell
   sudo dnf config-manager --dump gitlab_gitlab-ee | grep baseurl
   baseurl = https://packages.gitlab.com/gitlab/gitlab-ee/el/8/x86_64
   ```

   You use the contents of `baseurl` as the source of the local mirror. For example,
   `https://packages.gitlab.com/gitlab/gitlab-ee/el/8/x86_64`.

#### Create the local mirror

1. Install the `createrepo` package:

   ```shell
   sudo dnf install createrepo
   ```

1. Run `reposync` to copy RPMs to the local mirror:

   ```shell
   sudo dnf reposync --arch x86_64 --repoid=gitlab_gitlab-ee --download-path=/var/www/html/repos --newest-only
   ```

   The `--newest-only` option only downloads the latest RPM. If you omit this
   option, all RPMs in the repo (approximately 1 GB each) are downloaded.

1. Run `createrepo` to recreate the repository metadata:

   ```shell
   sudo createrepo -o /var/www/html/repos/gitlab_gitlab-ee /var/www/html/repos/gitlab_gitlab-ee
   ```

The local mirror repository should now be available at
<http://mirror.example.com/repos/gitlab_gitlab-ee/>.

#### Update the local mirror

Your local mirror should be updated periodically to get new RPMs as new GitLab
versions are released. One way of doing this is using `cron`.

Create `/etc/cron.daily/sync-gitlab-mirror` with the following contents:

```shell
#!/bin/sh

dnf reposync --arch x86_64 --repoid=gitlab_gitlab-ee --download-path=/var/www/html/repos --newest-only --delete
createrepo -o /var/www/html/repos/gitlab_gitlab-ee /var/www/html/repos/gitlab_gitlab-ee
```

The `--delete` option used in the `dnf reposync` command deletes RPMs in the
local mirror that are no longer present in the corresponding GitLab repository.

#### Using the local mirror

1. Create the Pulp `repository` and `remote`:

   ```shell
   pulp rpm repository create --retain-package-versions=1 --name "gitlab-ee"
   pulp rpm remote create --name gitlab-ee --url "http://mirror.example.com/repos/gitlab_gitlab-ee/" --policy immediate
   pulp rpm repository update --name gitlab-ee --remote gitlab-ee
   ```

1. Sync the repository:

   ```shell
   pulp rpm repository sync --name gitlab-ee
   ```

   This command must be run periodically to update the local mirror with changes
   to the GitLab repository.

After the repository is synced, you can create a publication and distribution to
make it available. See <https://docs.pulpproject.org/pulp_rpm/> for details.

## Error: `E: connection refused to d20rj4el6vkp4c.cloudfront.net 443`

When you install a package hosted on our package repository at `packages.gitlab.com`, your client will receive and follow a redirect to the CloudFront address `d20rj4el6vkp4c.cloudfront.net`. Servers in an air-gapped environment can receive the following errors:

```shell
E: connection refused to d20rj4el6vkp4c.cloudfront.net 443
```

```shell
Failed to connect to d20rj4el6vkp4c.cloudfront.net port 443: Connection refused
```

To resolve this issue, you have three options:

- If you can allowlist by domain, add the endpoint `d20rj4el6vkp4c.cloudfront.net` to your firewall settings.
- If you cannot allowlist by domain, add the [CloudFront IP address ranges](https://d7uri8nf7uskq.cloudfront.net/tools/list-cloudfront-ips) to your firewall settings. You must
  keep this list synced with your firewall settings because they can change.
- Manually download the package file and upload it to your server.

## Check if `net.core.somaxconn` is set too low

The following may assist in identifying if the value of `net.core.somaxconn`
is set too low:

```shell
$ netstat -ant | grep -c SYN_RECV
4
```

The return value from `netstat -ant | grep -c SYN_RECV` is the number of connections
waiting to be established. If the value is greater than `net.core.somaxconn`:

```shell
$ sysctl net.core.somaxconn
net.core.somaxconn = 1024
```

You may experience timeouts or HTTP 502 errors and is recommended to increase this
value by updating the `puma['somaxconn']` variable in your `gitlab.rb`.

## Error: `exec request failed on channel 0` or `shell request failed on channel 0`

When pulling or pushing by using Git over SSH, you might see the following errors:

- `exec request failed on channel 0`
- `shell request failed on channel 0`

These errors can happen if the number of processes from the `git` user is above the limit.

To try and resolve this issue:

1. Increase the `nproc` setting for the `git` user in the `/etc/security/limits.conf` file on the nodes where `gitlab-shell` is running.
   Typically, `gitlab-shell` runs on GitLab Rails nodes.
1. Retry the pull or push Git command.

## Hung installation after SSH connection loss

If you're installing GitLab on a remote virtual machine and your SSH connection gets lost,
the installation could hang with a zombie `dpkg` process. To resume the installation:

1. Run `top` to find the process ID of the associated `apt` process, which is the parent of the `dpkg` process.
1. Kill the `apt` process by running `sudo kill <PROCESS_ID>`.
1. Only if doing a fresh install, run `sudo gitlab-ctl cleanse`. This step erases existing data, so must not be used on upgrades.
1. Run `sudo dpkg configure -a`.
1. Edit the `gitlab.rb` file to include the desired external URL and any other configuration that might be missing.
1. Run `sudo gitlab-ctl reconfigure`.

## Redis-related error when reconfiguring GitLab

You might encounter the following error when reconfiguring GitLab:

```plaintext
RuntimeError: redis_service[redis] (redis::enable line 19) had an error: RuntimeError: ruby_block[warn pending redis restart] (redis::enable line 77) had an error: RuntimeError: Execution of the command /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket INFO failed with a non-zero exit code (1)
```

The error message indicates that Redis might have restarted or shut down while trying to establish a connection with `redis-cli`. Given that recipe runs
`gitlab-ctl restart redis` and tries to check the version right away, there might be a race condition that causes the error.

To resolve this problem, run the following command:

```shell
sudo gitlab-ctl reconfigure
```

If that fails, check the output of `gitlab-ctl tail redis` and try to run `redis-cli`.
