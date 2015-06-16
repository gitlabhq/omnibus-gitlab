# Omnibus-gitlab changelog

The latest version of this file can be found at the master branch of the
omnibus-gitlab repository.

7.12.0

- Allow install_dir to be changed to allow different build paths (DJ Mountney) d205dc9e4da86ea39af18a6715f9538d3893488cf
- Switched to omnibus fork 99c713cb579e8371a334b4e43a7d7863794d8374
- Upgraded chef to 12.4.0.rc.0 b1a3870bd5a5bc60335655a4965f8f80a9be939f
- Remove generated gitlab_shell_secret file during build 8ba8e9221516a0235f565bc5560bd0cec9c3c48e
- Update redis to 2.8.20 6589e23ed79c883988e0ebefc356699f5f94228f
- Exit on package installation if backup failed and wasn't skipped 710253c318a029bf1bb158c6c9fc81f0f695fe34
- Added sslmode and sslrootcert database configuration option (Anthony Brodard) dbeb00346ccafdda50e52cf601c6b457b5981b74
- Added option to disable HTTPS on nginx to support proxied SSL for GitLab CI
- Added custom listen_port for GitLab CI nginx to support reverse proxies
- IMPORTANT: secret_token in gitlab.rb for GitLab, GitLab-shell and GitLab CI will now take presedence over the auto generated one
- Automatically authorise GitLab CI with GitLab when they are on the same server
- Transmit gitlab-shell logs with remote_syslog 9242b83525cc18df22d1f44fb002a67e94b4ad5c
- Moved GitLab CI cronjob from root to the gitlab-ci user 4b9926b8c016c2c10f8511a5b083f6d5a7071041
- gitlab-rake and gitlab-ci-rake can be ran without sudo 4d4e3702ffee890eabed1d4cb61dd351baf2b554
- Git username and email are removed from git users gitconfig 1911109c0679f90e5184415c52ad5da4e31b7171
- Updated openssl to 1.0.1o 163305cac9ecd37425c3b1e10a390176a753717c
- Updated git version to 2.4.3 88186e3e71064c0d9e7ae674c5f68450226dfa68
- Updated SSL ciphers to exclude all DHE suites 08f790400b31eb3fbf4ce0ee736f7cc9082b28fc
- Updated rubygems version to 2.2.5 c85aed400bd8e17c5e919d19cd93c08616190e0b

7.11.0

- Set the default certificate authority bundle to the embedded copy (Stan Hu) 673ac210216b9c01d58196e826b98db780a4ccd5
- Use a different mirror for libossp-uuid (DJ Mountney) 7f46d70855a4d97eb2b833fc2d120ddfc514dfd4
- Update omnibus-software 42839a91c297b9c637a13fbe4beb05058672abe2
- Add option to disable gitlab-rails when using only CI a784851e268ca1f23ce817c13a8d421c3211f96a
- Point to different state file for gitlab logrotate 42591805f64c48cb845538012b2a43fe765637d2
- Allow setting ssl_dhparam in nginx config 7b0c80ed9c1d85bebeedfc211a9b9e395593278c

7.10.0

- Add option to disable HTTPS on nginx to support proxied SSL (Stan Hu) 80f4204052ceb3d47a0fdde2e006e79c099e5237
- Add openssh as runtime dependency e9b4f537a67ea6a060d8a974d3fc56f927a218b2
- Upgrade chef-gem version to 11.18.0 5a5300fe6b43c3ce11b796bb0ffc9fe62c731b1b
- Upgrade gitlab-ctl version to 0.3.3 cdcbb3b4bc299ef264633188570228d886d1a5c4
- Specify build directory for pip for docutils build a0e240c9693ebd8ec272282d37626f12dfee5da5
- Upgrade ruby to 2.1.6 5058dd591df5bcea08b98ed365eb29f955715ea6
- Add archive_repo sidekiq queue 3ed5e6e162794f4dc173a5e801dab975be6f61a2
- Add CI services to remote syslog 5fa5235aef0b8b119b3deb1ab1274a9e72ac6a2d
- Set number of unicorn workers to CPU core count + 1 5ad7e8b89c10417d8663520ecc43432bf3d8a0db
- Upgrade omnibusy-ruby to 4.0.0 d8d6a20551cd8376e2cfc05b53487911da7aa7b1
- Upgrade postgresql version to 9.2.9  d8d6a20551cd8376e2cfc05b53487911da7aa7b1
- Upgrade nginx to 1.7.11 528658852f9f5a1cc75a80ea86f48f92b75d54a3
- Upgrade zlib to 1.2.8 20ed5ce4d0a6eb5326319761fc7fd53dbcebb620
- Create database using the database name in attributes c5dfbe87869f85f45d6df16b1ebd3f4967fc7eb0
- Add gitlab_email_reply_to property (Stan Hu) e34317a289ae2a904c981b1ff6db7c4098571835
- Add configuration option for gitlab-www user home dir e975b3ab47a4ccb795da4721ef32b54340434354
- Restart nginx instead of issuing a HUP signal changes so that changes in listen_address work (Stan Hu) 72d09b9b29a1a974e35aa6088912b6a6c4d7e4ac
- Automatically stop GitLab, backup, reconfigure and start after a new package is installed
- Rename the package from 'gitlab' to 'gitlab-ce' / 'gitlab-ee'
- Update cacerts version e57085281e9f4d3ae15d4f2e14a88b3399cb4df3
- Better parsing of DB settings in gitlab.rb 503fad5f9d0a4653d8540331f77f487a7b51ce3d
- Update omnibus-ctl version to 0.3.4 b5972560c801bc22658d459ad00fa4f33a6c34d2
- Try to detect init system in use on Debian (nextime) 7dd0234c19616e1cbe0656e55ef8a53be3fe882b
- Devuan support added in runit (nextime) 7dd0234c19616e1cbe0656e55ef8a53be3fe882b
- Disable EC2 plugin 70ba5285e1e89ababf25c9cb9ac817bb582f5a43
- Disable multiple ohai plugins 0026ba26757a2b7168e7de86ab0652c0aec62ddf

7.9.0

- Respect gitlab_email_enabled property (Daniel Serodio) e2982692d49772c4f896a775e476a62b4831b8a1
- Use correct cert for CI (Flávio J. Saraiva) 484227e2dfe33f59e3683a5757be6842d7ce79d2
- Add ca_path and ca_file params for smtp email configuration (Thireus) fa9c1464bc1eb173660edfded1a2f7add7ac24b3
- Add custom listen_port to nginx config for reverse proxies (Stan Hu) 8c438a68fb155bd3489c32a1478484ccfd9b3ffb
- Update openssl to 1.0.1k 0aa00aecf0867e5d454ebf089cb3a23d4645632c
- DEPRECATION: 'gitlab_signup_enabled', 'gitlab_signin_enabled', 'gitlab_default_projects_limit', 'gravatar_enabled' are deprecated, settings can be changed in admin section of GitLab UI
- DEPRECATION: CI setting `gitlab_ci_add_committer` is deprecated. Use `gitlab_ci_add_pusher` to notify user who pushed the commit of a failing build
- DEPRECATION: 'issues_tracker_redmine', 'issues_tracker_jira' and related settings are deprecated. Configuring external issues tracker has been moved to Project Services section of GitLab UI
- Change default number of unicorn workers from 2 to 3 3d3f6e632b61326f6ff0376d7151cf7cf945383b
- Use systemd for debian 8 6f8a9e2c8258de883a437d1b8104d69726a18bdd
- Increase unicorn timeout to 1 hour f21dddc2d2e20c7a7d3376dc2839fff2629ec406
- Add nodejs dependency
- Added option to add keys needed for bitbucket importer c8c720f97098774679bca2c1d1200e2a8126827f
- Add rack attack and email_display name config options e3dcc9a7efcec9b4ddf7e715fed9da7ac971cc57

7.8.0

- Add gitlab-ci to logrotate (François Conil) 397ce5bab202d9d86e30a62538dca1323b7f6f4c
- New LDAP defaults, port and method 7a65245c59fd094e88784f924ecd968d134716fa
- Disable GCE plugin 35b7b89c78fe7e1c35bb7063c2a03e70d6915c1d

7.7.0

- Update ruby to 2.1.5 79e6833045e70a43ac66f65252d40773c20438df
- Change the root_password setting to initial_root_password 577a4b7b895e17cbe159bf317169d173c6d3567a
- Include CI Oauth settings option 2e5ae7414ecd9f73cbfe284af5d38ee65ac892e4
- Include option to set global git config options 8eae0942ec27ffeec534ba02e4171a3b6cd6d193

7.6.0
- Update git to 2.0.5 0749ffc43b4583fae6fc8ac1b91111340a225f92
- Update libgit2 and rugged to version 0.21.2 66ac2e805a166ecb10bdf8ba001b106acd7e49f3
- Generate SMTP settings using one template for both applications (Michael Ruoss) a6d6ff11f102c6fa9da6209f80162c5e137feeb9
- Add gitlab-shell configuration settings for http_settings, audit_usernames, log_level 5e4310442a608c5c420ffe670a9ab6f111489151
- Enable Sidekiq MemoryKiller by default with a 1,000,000 kB limit 99bbe20b8f0968c4e3c4a42281014db3d3635a7f
- Change runit recipe for Fedora to systemd (Nathan) fbb7687f3cc2f38faaf6609d1396b76d2f6f7507
- Added kerberos lib to support gitlab dependency 66fd3a85cce74754e850034894a87d554fdb04b7
- gitlab.rb now lists all available configuration options 6080f125697f9fe7113af1dc80e0a7bc9ddb284e
- Add option to insert configuration settings in nginx template (Sander Boom) 5ba0485a489549a0bb33531e027a206b1775b3c0


7.5.0
- Use system UIDs and GIDs when creating accounts (Tim Bishop) cfc04342129a4c4dca5c4827d541c8888adadad3
- Bundle GitLab CI with the package 3715204d86900e8501483f70c6370ba4e3f2bb3d
- Fix inserting external_url in gitlab.rb after installation 59f5976562ce3439fb3a6e43caac489a5c230db4
- Avoid duplicate sidekiq log entries on remote syslog servers cb514282f03add2fa87427e4601438653882fa03
- Update nginx config and SSL ciphers (Ben Bodenmiller) 0722d29c 89afa691
- Remove duplicate http headers (Phill Campbell) 8ea0d201c32527f095d3afa707a38865984e27d2
- Parallelize bundle install during build c53e92b80f423c90f2169fbd2d9ef33ce0233cb6
- Use Ruby 2.1.4 e083162579f00814086f34c1cf02c96dc9796f69
- Remove exec symlinks after gitlab uninstall 70c9a6e00be8814b8cad337b1e6d212be88a3f99
- Generate required gitlab_shell_secret d65d4832f1164dfe62036a65d1899ccf80cbe0c6

7.4.0
- Fix broken environment variable removal
- Hard-code the environment directory for gitlab-rails
- Set PATH and RAILS_ENV via the env directory
- Set the environment for gitlab-rails and gitlab-rake via chpst
- Configure bundle exec wrapper with gitlab-rails-rc
- Add a logrotate service for `gitlab-rails/production.log` etc.
- Again using backwards compatible ssl ciphers
- Increased Unicorn timeout to 60s
- For non-bundled webserver added an option of supplying external webserver user username
- Add option for using backup uploader
- Update openssl to 1.0.1j
- If hostname is correctly set, omnibus will prefill external_url

7.3.1
- Fix web-server recipe order
- Make /var/opt/gitlab/nginx gitlab-www's home dir
- Remove unneeded write privileges from gitlab-www

7.3.0
- Add systemd support for Centos 7
- Add a Centos 7 SELinux module for ssh-keygen permissions
- Log `rake db:migrate` output in /tmp
- Support `issue_closing_pattern` via gitlab.rb (Michael Hill)
- Use SIGHUP for zero-downtime NGINX configuration changes
- Give NGINX its own working directory
- Use the default NGINX directory layout
- Raise the default Unicorn socket backlog to 1024 (upstream default)
- Connect to Redis via sockets by default
- Set Sidekiq shutdown timeout to 4 seconds
- Add the ability to insert custom NGINX settings into the gitlab server block
- Change the owner of gitlab-rails/public back to root:root
- Restart Redis and PostgreSQL immediately after configuration changes
- Perform chown 7.2.x security fix in postinst

7.2.0
- Pass environment variables to Unicorn and Sidekiq (Chris Portman)
- Add openssl_verify_mode to SMTP email configuration (Dionysius Marquis)
- Enable the 'ssh_host' field in gitlab.yml (Florent Baldino)
- Create git's home directory if necessary
- Update openssl to 1.0.1i
- Fix missing sidekiq.log in the GitLab admin interface
- Defer more gitlab.yml defaults to upstream
- Allow more than one NGINX listen address
- Enable NGINX SSL session caching by default
- Update omnibus-ruby to 3.2.1
- Add rugged and libgit2 as dependencies at the omnibus level
- Remove outdated Vagrantfile

7.1.0
- Build: explicitly use .forward for sending notifications
- Fix MySQL build for Ubuntu 14.04
- Built-in UDP log shipping (Enterprise Edition only)
- Trigger Unicorn/Sidekiq restart during version change
- Recursively set the SELinux type of ~git/.ssh
- Add support for the LDAP admin_group attribute (GitLab EE)
- Fix TLS issue in SMTP email configuration (provides new attribute tls) (Ricardo Langner)
- Support external Redis instances (sponsored by O'Reilly Media)
- Only reject SMTP attributes which are nil
- Support changing the 'restricted_visibility_levels' option (Javier Palomo)
- Only start omnibus-gitlab services after a given filesystem is mounted
- Support the repository_downloads_path setting in gitlab.yml
- Use Ruby 2.1.2
- Pin down chef-gem's ohai dependency to 7.0.4
- Raise the default maximum Git output to 20 MB

7.0.0-ee.omnibus.1
- Fix MySQL build for Ubuntu 14.04

7.0.0
- Specify numeric user / group identifiers
- Support AWS S3 attachment storage
- Send application email via SMTP
- Support changing the name of the "git" user / group (Michael Fenn)
- Configure omniauth in gitlab.yml
- Expose more fields under 'extra' in gitlab.yml
- Zero-downtime Unicorn restarts
- Support changing the 'signin_enabled' option (Konstantinos Paliouras)
- Fix Nginx HTTP-to-HTTPS log configuration error (Konstantinos Paliouras)
- Create the authorized-keys.lock file for gitlab-shell 1.9.4
- Include Python and docutils for reStructuredText support
- Update Ruby to version 2.1.1
- Update Git to version 2.0.0
- Make Runit log rotation configurable
- Change default Runit log rotation from 10x1MB to 30x24h
- Security: Restrict redis and postgresql log directory permissions to 0700
- Add a 'gitlab-ctl deploy-page' command
- Automatically create /etc/gitlab/gitlab.rb after the package is installed
- Security: Use sockets and peer authentication for Postgres
- Avoid empty Piwik or Google Analytics settings
- Respect custom Unicorn port setting in gitlab-shell

6.9.4-ee.omnibus.1
- Security: Use sockets and peer authentication for Postgres

6.9.2.omnibus.2
- Security: Use sockets and peer authentication for Postgres

6.9.2
- Create the authorized-keys.lock file for gitlab-shell 1.9.4

6.9.1
- Fix Nginx HTTP-to-HTTPS log configuration error (Konstantinos Paliouras)

6.9.0
- Make SSH port in clone URLs configurable (Julien Pivotto)
- Fix default Postgres port for non-packaged DBMS (Drew Blessing)
- Add migration instructions coming from an existing GitLab installation (Goni Zahavy)
- Add a gitlab.yml conversion support script
- Correct default gravatar configuration (#112) (Julien Pivotto)
- Update Ruby to 2.0.0p451
- Fix name clash between release.sh and `make release`
- Fix Git CRLF bug
- Enable the 'sign_in_text' field in gitlab.yml (Mike Nestor)
- Use more fancy SSL ciphers for Nginx
- Use sane LDAP defaults
- Clear the Rails cache after modifying gitlab.yml
- Only run `rake db:migrate` when the gitlab-rails version has changed
- Ability to change the Redis port

6.8.1
- Use gitlab-rails 6.8.1

6.8.0
- MySQL client support (EE only)
- Update to omnibus-ruby 3.0
- Update omnibus-software (e.g. Postgres to 9.2.8)
- Email notifications in release.sh
- Rewrite parts of release.sh as a Makefile
- HTTPS support (Chuck Schweizer)
- Specify the Nginx bind address (Marco Wessel)
- Debian 7 build instructions (Kay Strobach)

6.7.3-ee.omnibus.1
- Update gitlab-rails to v6.7.3-ee

6.7.3-ee.omnibus

6.7.4.omnibus
- Update gitlab-rails to v6.7.4

6.7.2-ee.omnibus.2
- Update OpenSSL to 1.0.1g to address CVE-2014-0160

6.7.3.omnibus.3
- Update OpenSSL to 1.0.1g to address CVE-2014-0160
