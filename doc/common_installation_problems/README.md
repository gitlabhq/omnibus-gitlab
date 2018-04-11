# Common installation problems

Below you can find the most common issues users encounter when installing omnibus-gitlab packages.

### Hash Sum mismatch when downloading packages

apt-get install outputs something like:

```
E: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/ubuntu/pool/trusty/main/g/gitlab-ce/gitlab-ce_8.1.0-ce.0_amd64.deb  Hash Sum mismatch
```

Please run the following to fix this:

```
sudo rm -rf /var/lib/apt/lists/partial/*
sudo apt-get update
sudo apt-get clean
```

See [Joe Damato's from Packagecloud comment](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/628#note_1824330) and [his blog article](http://blog.packagecloud.io/eng/2016/03/21/apt-hash-sum-mismatch/) for more context.

Another workaround is to download the package manually by selecting the correct package from [packages.gitlab.com CE](https://packages.gitlab.com/gitlab/gitlab-ce) [or EE repository](https://packages.gitlab.com/gitlab/gitlab-ee):

```
curl -LJO https://packages.gitlab.com/gitlab/gitlab-ce/packages/ubuntu/trusty/gitlab-ce_8.1.0-ce.0_amd64.deb/download
dpkg -i gitlab-ce_8.1.0-ce.0_amd64.deb
```

### Installation on openSUSE and SLES platforms warns about unknown key signature

Omnibus GitLab packages are [signed with GPG
keys](https://docs.gitlab.com/omnibus/update/package_signatures.html) in
addition to the package repositories providing signed metadata. This ensures
authenticity and integrity of the packages that are distributed to the users.
However, the package manager used in openSUSE and SLES operating systems may
sometime raise false warnings with these signatures, similar to
```
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no):
File 'repomd.xml' from repository 'gitlab_gitlab-ce' is signed with an unknown key '14219A96E15E78F4'. Continue? [yes/no] (no): yes
```

This is a known bug with zypper where zypper ignores the `gpgkey` keyword in the
repo configuration file. With later versions of Packagecloud, there may be
improvements regarding this, but currently users have to manually agree to
package installation.

So, in openSUSE or SLES systems, if such a warning is displayed, it is safe to
continue installation.

### Reconfigure shows an error: NoMethodError - undefined method '[]=' for nil:NilClass

You ran `sudo gitlab-ctl reconfigure` or package upgrade triggered the
reconfigure which produced error similar to:

```
================================================================================
Recipe Compile Error in /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/default.rb
================================================================================

NoMethodError
-------------
undefined method `[]=' for nil:NilClass

Cookbook Trace:
---------------
  /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/config.rb:21:in `from_file'
  /opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/recipes/default.rb:26:in `from_file'

Relevant File Content:
```

This error is thrown when `/etc/gitlab/gitlab.rb` configuration file contains
configuration that is invalid or unsupported. Double check that there are no
typos or that the configuration file does not contain obsolete configuration.

You can check the latest available configuration by using `sudo gitlab-ctl diff-config` (Command available starting with GitLab 8.17) or check the latest [gitlab.rb.template][].

### GitLab is unreachable in my browser

Try [specifying](#configuring-the-external-url-for-gitlab) an `external_url` in
`/etc/gitlab/gitlab.rb`. Also check your firewall settings; port 80 (HTTP) or
443 (HTTPS) might be closed on your GitLab server.

### Emails are not being delivered

To test email delivery you can create a new GitLab account for an email that is
not used in your GitLab instance yet.

If necessary, you can modify the 'From' field of the emails sent by GitLab with
the following setting in `/etc/gitlab/gitlab.rb`:

```
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

### Reconfigure freezes at `ruby_block[supervise_redis_sleep] action run`

If you uninstall and reinstall GitLab, it's possible that the process
supervisor (runit) may not be in the proper state if it continued to run.
To troubleshoot this error:

1. First check that the runit directory exists:

    ```sh
    $ ls -al /opt/gitlab/sv/redis/supervise
    ```

2. If you see the message, continue to the next step:

    ```
    ls: cannot access /opt/gitlab/sv/redis/supervise: No such file or directory
    ```

3.  Restart the runit server.  
    Using systemctl (Debian => 9 - Stretch):

    ```
    $ sudo systemctl restart gitlab-runsvdir
    ```

    Using upstart (Ubuntu <= 14.04):

    ```
    $ sudo initctl restart gitlab-runsvdir
    ```

    Using systemd (CentOS, Ubuntu >= 16.04):

    ```
    $ systemctl restart gitlab-runsvdir.service
    ```

*Note* This should be resolved starting from 7.13 omnibus-gitlab packages.

During the first `gitlab-ctl reconfigure` run, omnibus-gitlab needs to figure
out if your Linux server is using SysV Init, Upstart or Systemd so that it can
install and activate the `gitlab-runsvdir` service. If `gitlab-ctl reconfigure`
makes the wrong decision, it will later hang at
`ruby_block[supervise_redis_sleep] action run`.

The choice of init system is currently made in [the embedded Runit
cookbook][runit-cookbook]  by essentially
looking at the output of `uname -a`, `/etc/issue` and others. This mechanism
can make the wrong decision in situations such as:

- your OS release looks like 'Debian 7' but it is really some variant which
  uses Upstart instead of SysV Init;
- your OS release is unknown to the Runit cookbook (e.g. ClearOS 6.5).

Solving problems like this would require changes to the embedded Runit
cookbook; Merge Requests are welcome. Until this problem is fixed, you can work
around it by manually performing the appropriate installation steps for your
particular init system. For instance, to manually set up `gitlab-runsvdir` with
Upstart, you can do the following:

```
sudo cp /opt/gitlab/embedded/cookbooks/runit/files/default/gitlab-runsvdir.conf /etc/init/
sudo initctl start gitlab-runsvdir
sudo gitlab-ctl reconfigure # Resume gitlab-ctl reconfigure
```

### TCP ports for GitLab services are already taken

By default, Unicorn listens at TCP address 127.0.0.1:8080. Nginx
listens on port 80 (HTTP) and/or 443 (HTTPS) on all interfaces.

The ports for Redis, PostgreSQL and Unicorn can be overriden in
`/etc/gitlab/gitlab.rb` as follows:

```ruby
redis['port'] = 1234
postgresql['port'] = 2345
unicorn['port'] = 3456
```

For Nginx port changes please see [settings/nginx.md](../settings/nginx.md).

### Git user does not have SSH access
#### SELinux-enabled systems

On SELinux-enabled systems the git user's `.ssh` directory or its contents can
get their security context messed up. You can fix this by running `sudo
gitlab-ctl reconfigure`, which will set the `ssh_home_t` security context on
`/var/opt/gitlab/.ssh`.

In GitLab 10.0 this behavior was improved by setting the context permanently using
`semanage`. The runtime dependency `policycoreutils-python` has been added to the
RPM package for RHEL based operating systems in order to ensure the `semanage`
command is available.

#### All systems

The git user is created, by default, with a locked password, shown by `'!'` in
/etc/shadow. Unless "UsePam yes" is enabled, the OpenSSH daemon will prevent the
git user from authenticating even with ssh keys. An alternative secure solution
is to unlock the password by replacing `'!'` with `'*'` in `/etc/shadow`. The git
user will still be unable to change the password because it runs in a restricted
shell and the `passwd` command for non-superusers requires entering the current
password prior to a new password. The user cannot enter a password that will
match `'*'` and therefore the account remains password-less.

Keep in mind that the git user must have access to the system so please review
your security settings at `/etc/security/access.conf` and make sure the git user
is not blocked.

### Postgres error 'FATAL:  could not create shared memory segment: Cannot allocate memory'

The packaged Postgres instance will try to allocate 25% of total memory as
shared memory. On some Linux (virtual) servers, there is less shared memory
available, which will prevent Postgres from starting. In
`/var/log/gitlab/postgresql/current`:

```
  1885  2014-08-08_16:28:43.71000 FATAL:  could not create shared memory segment: Cannot allocate memory
  1886  2014-08-08_16:28:43.71002 DETAIL:  Failed system call was shmget(key=5432001, size=1126563840, 03600).
  1887  2014-08-08_16:28:43.71003 HINT:  This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory or swap space, or exceeded your kernel's SHMALL parameter.  You can either reduce the request size or reconfigure the kernel with larger SHMALL.  To reduce the request size (currently 1126563840 bytes), reduce PostgreSQL's shared memory usage, perhaps by reducing shared_buffers or max_connections.
  1888  2014-08-08_16:28:43.71004       The PostgreSQL documentation contains more information about shared memory configuration.
```

You can manually lower the amount of shared memory Postgres tries to allocate
in `/etc/gitlab/gitlab.rb`:

```ruby
postgresql['shared_buffers'] = "100MB"
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

### Postgres error 'FATAL:  could not open shared memory segment "/PostgreSQL.XXXXXXXXXX": Permission denied'
By default, Postgres will try to detect the shared memory type to use. If you don't
have shared memory enabled, you might see this error in `/var/log/gitlab/postgresql/current`.
To fix this, you can disable postgresql's shared memory detection. Set the
following value in `/etc/gitlab/gitlab.rb`:

```ruby
postgresql['dynamic_shared_memory_type'] = 'none'
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

### Reconfigure complains about the GLIBC version

```
$ gitlab-ctl reconfigure
/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.14' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
/opt/gitlab/embedded/bin/ruby: /lib64/libc.so.6: version `GLIBC_2.17' not found (required by /opt/gitlab/embedded/lib/libruby.so.2.1)
```

This can happen if the omnibus package you installed was built for a different
OS release than the one on your server. Double-check that you downloaded and
installed the correct omnibus-gitlab package for your operating system.

### Reconfigure fails to create the git user

This can happen if you run `sudo gitlab-ctl reconfigure` as the git user.
Switch to another user.

More importantly: do not give sudo rights to the git user or to any of the
other users used by omnibus-gitlab. Bestowing unnecessary privileges on a
system user weakens the security of your system.

### Failed to modify kernel parameters with sysctl

If sysctl cannot modify the kernel parameters you could possibly get an error with the following stack trace:

```
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

Try enabling the module on which sysctl errored out, on how to enable the module see example [here](http://serverfault.com/questions/477718/sysctl-p-etc-sysctl-conf-returns-error).

There is a reported workaround described in [this issue](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/361) which requires editing the GitLab' internal recipe by supplying the switch which will ignore failures. Ignoring errors can have unexpected side effects on performance of your GitLab server so it is not recommended to do so.

Another variation of this error reports the file system is read-only and shows following stack trace:

```
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

This error is also reported to occur in virtual machines only, and the recommended workaround is to set the values in the host. The values needed for GitLab can be found inside the file `/opt/gitlab/embedded/etc/90-omnibus-gitlab.conf` in the virtual machine. After setting these values in `/etc/sysctl.conf` file in the host OS, run `cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p - ` on the host. Then try running `gitlab-ctl reconfigure` inside the virtual machine. It should detect that the kernel is already running with the necessary settings, and not raise any errors.

Also note you may need to repeat this process for a couple other lines, e.g. reconfigure will fail 3 times and you will eventually have added something like this to `/etc/sysctl.conf`:

```
kernel.shmall = 4194304
kernel.sem = 250 32000 32 262
net.core.somaxconn = 1024
kernel.shmmax = 17179869184
```

Tip: You may find it easier to look at the line in the Chef output than to find the file (since the file is different for each error). See the last line of this snippet.

```
* file[create /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf kernel.shmall] action create
  - create new file /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf
  - update content in file /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf from none to 6d765d
  --- /opt/gitlab/embedded/etc/90-omnibus-gitlab-kernel.shmall.conf	2017-11-28 19:09:46.864364952 +0000
  +++ /opt/gitlab/embedded/etc/.chef-90-omnibus-gitlab-kernel.shmall.conf kernel.shmall20171128-13622-sduqoj	2017-11-28 19:09:46.864364952 +0000
  @@ -1 +1,2 @@
  +kernel.shmall = 4194304
```

### I am unable to install omnibus-gitlab without root access

Occasionally people ask if they can install GitLab without root access.
This is problematic for several reasons.

#### Installing the .deb or .rpm

To our knowledge there is no clean way to install Debian or RPM
packages as a non-privileged user. You cannot install omnibus-gitlab
RPM's because the Omnibus build process does not create source RPM's.

#### Hassle-free hosting on port 80 and 443

The most common way to deploy GitLab is to have a web server
(NGINX/Apache) running on the same server as GitLab, with the web
server listening on a privileged (below-1024) TCP port. In
omnibus-gitlab we provide this convenience by bundling an
automatically configured NGINX service that needs to run its master
process as root to open ports 80 and 443.

If this is problematic, administrators installing GitLab can disable
the bundled NGINX service, but this puts the burden on them to keep
the NGINX configuration in tune with GitLab during application
updates.

#### Isolation between Omnibus services

Bundled services in omnibus-gitlab (GitLab itself, NGINX, Postgres,
Redis, Mattermost) are isolated from each other using Unix user
accounts. Creating and managing these user accounts requires root
access. By default, omnibus-gitlab will create the required Unix
accounts during 'gitlab-ctl reconfigure' but that behavior can be
[disabled](../settings/configuration.html#disable-user-and-group-account-management).

In principle omnibus-gitlab could do with only 2 user accounts (one
for GitLab and one for Mattermost) if we give each application its own
Runit (runsvdir), Postgres and Redis process. But this would be a
major change in the 'gitlab-ctl reconfigure' Chef code and it would
probably create major upgrade pain for all existing omnibus-gitlab
installations. (We would probably have to rearrange the directory
structure under /var/opt/gitlab.)

#### Tweaking the operating system for better performance

During 'gitlab-ctl reconfigure' we set and install several sysctl
tweaks to improve Postgres performance and increase connection limits.
This can only be done with root access.

### gitlab-rake assets:precompile fails with 'Permission denied'

Some users report that running `gitlab-rake assets:precompile` does not work
with the omnibus packages. The short answer to this is: do not run that
command, it is only for GitLab installations from source.

The GitLab web interface uses CSS and JavaScript files, called 'assets' in Ruby
on Rails-speak. In the [upstream GitLab
repository](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/assets)
these files are stored in a developer-friendly way: easy to read and edit. When
you are a normal user of GitLab, you do not want these files to be in the
developer friendly format however because that makes GitLab slow. This is why
part of the GitLab setup process is to convert the assets from a
developer-friendly format to an end-user friendly (compact, fast) format; that
is what the `rake assets:precompile` script is for.

When you install GitLab from source (which was the only way to do it before we
had omnibus packages) you need to convert the assets on your GitLab server
every time you update GitLab. People used to overlook this step and there are
still posts, comments and mails out there on the internet where users recommend
each other to run `rake assets:precompile` (which has now been renamed
`gitlab:assets:compile`). With the omnibus packages things are different: when
we build the package [we compile the assets for you](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/1cfe925e0c015df7722bb85eddc0b4a3b59c1211/config/software/gitlab-rails.rb#L74).
When you install GitLab with an omnibus package, the converted assets are
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

### 'Short read or OOM loading DB' error

Try cleaning the old redis session by following the [documentation here.](https://docs.gitlab.com/ce/operations/cleaning_up_redis_sessions.html)

### Apt error 'The requested URL returned error: 403'

When trying to install GitLab using the apt repo if you receive an error similar to:

```bash
W: Failed to fetch https://packages.gitlab.com/gitlab/gitlab-ce/DISTRO/dists/CODENAME/main/source/Sources  The requested URL returned error: 403
```

check if there is a repository cacher in front of your server, like for example `apt-cacher-ng`.

Add the following line to apt-cacher-ng config(eg. in  `/etc/apt-cacher-ng/acng.conf`):

```bash
PassThroughPattern: (packages\.gitlab\.com|packages-gitlab-com\.s3\.amazonaws\.com)
```

Read more about `apt-cacher-ng` and the reasons why this change is needed [on the packagecloud blog](http://blog.packagecloud.io/eng/2015/05/05/using-apt-cacher-ng-with-ssl-tls/).

### Using self signed certificate or custom certificate authorities

If you are installing GitLab in an isolated network with custom certificate authorities or using self-signed certificate make sure that the certificate can be reached by GitLab. Not doing so will cause errors like:

```bash
Faraday::SSLError (SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed)
```

when GitLab tries to connect with the internal services like gitlab-shell.

To fix these errors, see the [Custom SSL settings](../settings/ssl.md) section.

### error: proxyRoundTripper: XXX failed with: "net/http: timeout awaiting response headers"

Starting with version 8.3, gitlab-workorse is the default router for any requests
going to GitLab.

If gitlab-workhorse doesn't receive an answer from
GitLab within 1 minute (default), it will serve a 502 page.

There are various reasons why the request might timeout, perhaps user
was loading a very large diff or similar.

You can increase the default timeout value by setting the value in `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_workhorse['proxy_headers_timeout'] = "2m0s"
```

Save the file and [reconfigure GitLab][] for the changes to take effect.

### The change you wanted was rejected

Most likely you have GitLab setup in an environment that has proxy in front
of GitLab and the proxy headers set in package by default are incorrect
for your environment.

See [Change the default proxy headers section of nginx doc][] for details on
how to override the default headers.

### Can't verify CSRF token authenticity Completed 422 Unprocessable

Most likely you have GitLab setup in an environment that has proxy in front
of GitLab and the proxy headers set in package by default are incorrect
for your environment.

See [Change the default proxy headers section of nginx doc][] for details on
how to override the default headers.

### Extension missing pg_trgm

Starting from GitLab 8.6, [GitLab requires](https://docs.gitlab.com/ce/install/requirements.html#postgresql-requirements)
the PostgreSQL extension `pg_trgm`.
If you are using omnibus-gitlab package with the bundled database, the extension
should be automatically enabled when you upgrade.

If you however, are using an external (non-packaged) database, you will need to
enable the extension manually. The reason for this is that omnibus-gitlab
package with external database has no way of confirming if the extension exists,
and it also doesn't have a way of enabling the extension.


To fix this issue, you'll need to first install the `pg_trgm` extension.
The extension is located in the `postgresql-contrib` package. For Debian:

```
sudo apt-get install postgresql-contrib
```

Once the extension is installed, access the `psql` as superuser and enable the
extension.

1. Access `psql` as superuser:

    ```
    sudo gitlab-psql -d gitlabhq_production
    ```

1. Enable the extension:

    ```
    CREATE EXTENSION pg_trgm;
    \q
    ```
1. Now run migrations again:

    ```
    sudo gitlab-rake db:migrate
    ```
---

If using Docker, you first need to access your container, then run the commands
above, and finally restart the container.

1. Access the container:

    ```
    docker exec -it gitlab bash
    ```

1. Run the commands above

1. Restart the container:

    ```
    docker restart gitlab
    ```

### Errno::ENOMEM: Cannot allocate memory during backup or upgrade

[GitLab requires](https://docs.gitlab.com/ce/install/requirements.html#memory)
2GB of available memory to run without errors. Having 2GB of memory installed may
not be enough depending on the resource usage of other processes on your server.
If GitLab runs fine when not upgrading or running a backup, then adding more swap
should solve your problem. If you see the server using swap during normal usage,
you can add more RAM to improve performance.

### NGINX error: 'could not build server_names_hash, you should increase server_names_hash_bucket_size'

If your external url for GitLab is longer than the default bucket size (64 bytes),
NGINX may stop working and show this error in the the logs. To allow larger server
names, double the bucket size in `/etc/gitlab/gitlab.rb`:

```ruby
nginx['server_names_hash_bucket_size'] = 128
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.

### Reconfigure fails due to "'root' cannot chown" with NFS root_squash

```
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
[disable storage directory management](../settings/configuration.md#disable-storage-directories-management)
 and manage the permissions yourself.

[certificate link shell script]: https://gitlab.com/snippets/6285
[script source]: https://www.madboa.com/geek/openssl/#verify-new
[Change the default proxy headers section of nginx doc]: ../settings/nginx.md
[reconfigure GitLab]: https://docs.gitlab.com/ce/administration/restart_gitlab.html#omnibus-gitlab-reconfigure
[runit-cookbook]: https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/files/gitlab-cookbooks/runit/recipes/default.rb
