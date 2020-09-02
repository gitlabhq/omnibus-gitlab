# Omnibus-gitlab changelog

The latest version of this file can be found at the master branch of the
omnibus-gitlab repository.

## 13.3.4 (2020-09-02)

- No changes.

## 13.3.3 (2020-09-02)

- No changes.

## 13.3.2 (2020-08-28)

- No changes.

## 13.3.1 (2020-08-25)

- No changes.

## 13.3.0 (2020-08-22)

### Removed (3 changes)

- Remove gitlab_rails['db_pool'] setting. !4426
- Does not refresh the foreign tables on the Geo secondary server. !4475
- Remove Foreign Data Wrapper support for Geo. !4491

### Fixed (6 changes)

- Re-apply gitlab-pages SSL_CERT_DIR change. !4411
- Recording rules: Fix potential CPU overcounting problem. !4420
- Allow postgres-exporter to use local socket and Rails db_name. !4439
- Revert Block requests to the grafana avatar endpoint. !4484
- Add rhel 8 to helper and selinux files. !4501
- libatomic is required on both armhf and aarch64.

### Changed (4 changes)

- Update chef dependencies to 15.15.22. !4384
- Update Praefect defaults. !4416
- Remove read-only config toggle from Praefect. !4462
- Bump Container Registry to v2.10.1-gitlab. !4480

### Added (9 changes)

- Add PostgreSQL 12 support. !4399
- Add support for ActionCable in-app mode. !4407
- Upgrade Grafana Dashboard to v1.8.0. !4409
- Add free space check to pre-flight for pg-upgrade. !4421
- Add -domain-config-source for GitLab Pages. !4428
- Add cron settings for expired PAT notification. !4465
- Add support for configuring AWS server side encryption. !4469
- Upgrade Git to v2.28.0. !4483
- Support units other than milliseconds for the pg-upgrade timeout option. !4493

### Other (5 changes)

- Use S3-compatible remote directory for Terraform state storage. !4412
- Record average CPU and memory utilization for Usage Ping. !4455
- Use gcc v6.3 for CentOS 6 to build Rails C extensions. !4466
- Use new CMake for building libgit2 as part of Gitaly build. !4468
- Update Mattermost to 5.25.3.


## 13.2.7 (2020-09-02)

- No changes.

## 13.2.6 (2020-08-18)

- No changes.

## 13.2.5 (2020-08-17)

- No changes.

## 13.2.4 (2020-08-11)

### Fixed (1 change)

- Fix Geo replication resuming. !4461


## 13.2.3 (2020-08-05)

- No changes.

## 13.2.2 (2020-07-29)

### Fixed (1 change)

- Disable crond if LetsEncrypt disabled. !4434


## 13.2.1 (2020-07-23)

### Fixed (1 change)

- Make actioncable recipe and control files match new runit requirement. !4419


## 13.2.0 (2020-07-22)

### Fixed (9 changes)

- Grafana Server SHOULD have serve_from_sub_path set to true. !4160
- Fix reconfigure failure with sidekiq_cluster config. !4337
- Convert a standalone PostgreSQL to a Patroni member. !4350
- Ensure we are properly restarting the unicorn service. !4354
- Absolute SSL path should work for postgres recipe. !4356
- Allow patroni to receive the term signal. !4366
- Centralize upgrade version check in order to include docker upgrades. !4381
- Merge Chef attributes more conservatively. !4394
- Handle a down server when checking if a database is in standby. !4404

### Changed (6 changes, 1 of them is from the community)

- Geo: Check if replication/verification is up-to-date in promotion preflight checks. !4314
- Add Commands to Pause/Resume Replication. !4331
- Update alertmanager to 0.21.0. !4347
- Allow backup-etc to follow symlinks. !4349 (mterhar)
- Add --delete-untagged alias for registry-garbage-collect command. !4371
- Geo: Remove confirm-removing-keys option from promote-to-primary-node command. !4403

### Performance (1 change)

- Lower gzip compression threshold. !4387

### Added (7 changes)

- Allow forced ssl on defined cidr_addresses. !3724
- Add Patroni sub-commands to gitlab-ctl. !4286
- Add Ubuntu 20.04 packaging jobs. !4344
- Update Grafana Dashboards. !4348
- Praefect: support of TLS. !4352
- Support consolidated object storage configuration. !4368
- Add get-postgresql-primary command to gitlab-ctl. !4383

### Other (12 changes)

- Upgrade Chef libraries to Chef 15. !4092
- Add setting to specify external Prometheus address to the rails application. !4309
- Geo: Add force mode to promote-to-primary-node command. !4321
- Bump GitLab Exporter to 7.0.6. !4328
- Update builder image to 0.0.65, to pick up license_finder update. !4338
- Add recording rules to support Prometheus usage pings. !4343
- Record application server type in Prometheus. !4374
- Update webdevops/go-crond from 0.6.1 to 20.7.0. !4385
- Update gitlab-org/gitlab-exporter from 7.0.6 to 7.1.0. !4391
- Add deprecation message for Geo::MigratedLocalFilesCleanUpWorker config options. !4401
- Update libjpeg-turbo/libjpeg-turbo from 2.0.4 to 2.0.5.
- Update Mattermost to 5.24.2.


## 13.1.9 (2020-09-02)

- No changes.

## 13.1.8 (2020-08-18)

- No changes.

## 13.1.7 (2020-08-17)

- No changes.

## 13.1.6 (2020-08-05)

- No changes.

## 13.1.5 (2020-07-23)

### Fixed (3 changes)

- Fix reconfigure failure with sidekiq_cluster config. !4337
- Centralize upgrade version check in order to include docker upgrades. !4381
- Make actioncable recipe and control files match new runit requirement. !4419


## 13.1.3 (2020-07-06)

- No changes.

## 13.1.2 (2020-07-01)

### Security (1 change)

- Update PCRE to version 8.44.


## 13.1.1 (2020-06-23)

### Fixed (1 change)

- Manually disable copy_file_range() on RedHat kernels. !4346

### Added (1 change)

- Update to Grafana 7. !4297


## 13.1.0 (2020-06-22)

### Removed (1 change)

- Praefect configuration: remove postgres_queue_enabled. !4267

### Fixed (1 change)

- Enable consul service for sidekiq-cluster. !4266

### Changed (8 changes)

- Move hook values to [hooks] and gitlab connection values to [gitlab] in gitaly.toml. !4243
- Geo - Confirm if primary can be contacted after manual preflight checks. !4260
- gitlab.rb example template should show puma default. !4268
- Praefect: Enable SQL failover by default. !4271
- Update gitlab-exporter to 7.0.4. !4272
- Enable btree_gist postgres extension. !4274
- Update parser gem version. !4275
- Make it possible to disable Workhorse -authSocket argument. !4324

### Added (6 changes)

- Add Patroni to Omnibus. !3984
- Add libtiff as a dependency. !4047
- Add command promotion-preflight-checks to run before promoting to primary node. !4246
- Allow enabling Praefect read-only mode through gitlab.rb. !4250
- Upgrade Grafana dashboards to v1.6.0. !4278
- Add capability to supply env vars to gitlab-pages. !4296

### Other (8 changes)

- Build and release packages for Raspberry Pi Buster. !3953
- Add (optional) list of manual checks to promote_to_primary script. !4231
- Update nginx to stable version 1.18.0. !4242
- Stop deleting rack attack files. !4269
- Mark 13.0 as minimum version required to upgrade to 13.x. !4270
- Upgrade to Git 2.27.0. !4294
- Use latest Ubuntu AMI as base for our AMIs. !4308
- Update Mattermost to 5.23.1.


## 13.0.14 (2020-08-18)

- No changes.

## 13.0.13 (2020-08-17)

- No changes.

## 13.0.12 (2020-08-05)

- No changes.

## 13.0.11 (2020-08-05)

This version has been skipped due to packaging problems.

## 13.0.10 (2020-07-09)

### Performance (1 change, 1 of them is from the community)

- Run vacuumdb with 2 commands simultaneously. !4373 (Ben Bodenmiller @bbodenmiller)


## 13.0.9 (2020-07-06)

- No changes.

## 13.0.8 (2020-07-01)

### Security (1 change)

- Update PCRE to version 8.44.


## 13.0.7 (2020-06-25)

### Fixed (2 changes)

- Fix geo timeout issue with pg-upgrade. !4148
- Manually disable copy_file_range() on RedHat kernels. !4346


## 13.0.6 (2020-06-10)

- No changes.

## 13.0.5 (2020-06-04)

- No changes.

## 13.0.4 (2020-06-03)

- No changes.

## 13.0.3 (2020-05-29)

- No changes.

## 13.0.2 (2020-05-28)

### Security (1 change)

- Update Ruby to 2.6.6.

### Fixed (2 changes)

- Fix nginx duplicate MIME type warning. !4251
- Do not run Grafana reset during docker startup. !4264

### Added (1 change)

- Update Praefect Grafana dashboards. !4241


## 13.0.1 (2020-05-27)

### Security (1 change)

- Block requests to the grafana avatar endpoint.


## 13.0.0 (2020-05-22)

### Security (2 changes)

- Update Ruby to 2.6.6.
- Upgrade Openssl to 1.1.1.g.

### Removed (6 changes)

- Remove old settings for gitlab-monitor, pages auth-server, and other components. !4139
- Remove support for protected paths throttling via Rack attack. !4149
- Remove support for user attributes for Repmgr and Consul. !4153
- Remove Grafana reset during upgrades. !4155
- Remove PostgreSQL 9.6 and 10. !4186
- Remove flag to set protected paths from gitlab.rb. !4207

### Fixed (10 changes, 2 of them are from the community)

- Remove crond job if Let's Encrypt autorenew is disabled. !4075
- Install `less` to fix #5257. !4112 (Yannic Haupenthal)
- Env dir content should not be displayed by chef. !4119
- Fix geo timeout issue with pg-upgrade. !4148
- Upgrade to pgbouncer_exporter v0.2.0. !4167
- Update gitlab exporter to 7.0.2. !4178
- Set gitlab_url from gitlab_rails attributes. !4225
- Fix dbvacuum on pgupgrade. !4227
- Bump version of `gitlab-exporter` gem. !4232
- Disabling vts status module should keep gitlab-workhorse upstream. !4233 (Ovv)

### Changed (4 changes, 1 of them is from the community)

- Provide and implement a custom resource for restarting a daemon when the version changes. !3958 (Mitch Nielsen)
- Enable Puma by default instead of Unicorn. !4141
- List all existing roles as options in gitlab.rb. !4192
- Bump Container Registry to v2.9.1-gitlab. !4197

### Performance (5 changes)

- Enable frame pointer in Ruby compile options. !4030
- Disable RubyGems for Gitaly gitlab-shell hooks. !4103
- upgrade redis to 5.0.9. !4126
- Enable frame pointer in Git compile options. !4134
- Update nginx gzip settings. !4200

### Added (13 changes, 3 of them are from the community)

- Add service_desk_email configuration. !3963
- Add new extra CAs configuration file to smime email signing. !4085 (Diego Louzán)
- Write gitlab shell configs to gitaly's config. !4110
- Enable sidekiq-cluster by default. !4140
- Add support for RSA private key for signing CI json web tokens. !4158
- gitlab-pages: introduce internal_gitlab_server parameter. !4174
- Add Prometheus rules for Puma. !4177
- Copy AMIs to all regions we have access to. !4185
- Add experimental support for ActionCable. !4204
- Add expunge deleted messages option to mailroom. !4211 (Diego Louzán)
- Add SSL_CERT_DIR to praefect's env. !4216
- Allow enabling of grafana alerting in omnibus-gitlab. !4229 (msschl)
- Update Praefect Grafana dashboards. !4241

### Other (8 changes, 1 of them is from the community)

- Make GitLab 12.10 the minimum version to upgrade to 13.0. !4111
- Update links to PostgreSQL docs, point to version 11. !4150
- Rename slave to replica in the omnibus-gitlab Redis configuration. !4168
- Add troubleshooting doc for SMTP settings. !4170
- Update documentation link and comments in Unleash settings. !4191
- Patch Git to fix partial clone bug. !4217
- Update CA certificate bundle. !4230
- Update Mattermost to 5.22.2. (Harrison Healey)


## 12.10.14 (2020-07-06)

- No changes.

## 12.10.13 (2020-07-01)

### Security (1 change)

- Update PCRE to version 8.44.


## 12.10.12 (2020-06-24)

### Fixed (2 changes)

- Fix geo timeout issue with pg-upgrade. !4148
- Manually disable copy_file_range() on RedHat kernels. !4346


## 12.10.11 (2020-06-10)

- No changes.

## 12.10.8 (2020-05-28)

### Fixed (1 change)

- Fix dbvacuum on pgupgrade. !4227


## 12.10.7 (2020-05-27)

### Security (2 changes)

- Block requests to the grafana avatar endpoint.
- Update Ruby to 2.6.6.


## 12.10.6 (2020-05-15)

### Fixed (4 changes)

- Fix tracking db revert from pg-upgrade. !4116
- Ignore the PG_VERSION value if database is not enabled. !4136
- Fix pg-upgrade wrong number of args error. !4189
- Only print pg upgrade message when postgres is actually enabled. !4209

### Changed (1 change)

- Do not set a default value for client side database statement timeout. !4154


## 12.10.6 (2020-05-15)

- No changes.

## 12.10.5 (2020-05-13)

- No changes.

## 12.10.4 (2020-05-05)

- No changes.

## 12.10.3 (2020-05-04)

- No changes.

## 12.10.2 (2020-04-30)

### Security (2 changes)

- Backport change for updating openssl/openssl from 1f to 1g.
- Remove sensitive info from Docker image.


## 12.10.1 (2020-04-24)

### Fixed (4 changes)

- Rhel/centos8 rpm changed the arg input to posttrans. !4093
- Ensure the pg bin files fallback for geo-postgresql. !4118
- Prevent gitlab upgrades from GitLab 11.x. !4138
- Rename Repmgr to RepmgrHandler in HA pg-upgrade scenario. !4146

### Deprecated (1 change)

- Print a deprecation notice for postgres upgrades if <11. !4054


## 12.10.0 (2020-04-22)

### Security (1 change)

- Update openssl/openssl from 1.1.1d to 1.1.1e. !4019

### Fixed (5 changes)

- Fixes sysctl error on reconfigure after reinstall. !3921
- Fix pg-upgrade error during sysctl commands. !4080
- Fix pg-upgrade error format exception. !4090
- Fixed pg upgrade for seperate geo tracking db. !4091
- Fix repmgr failure during pg-upgrade. !4117

### Deprecated (1 change)

- Deprecate user attributes of consul and repmgr in favor of username. !3489

### Changed (4 changes)

- Upgrade Prometheus to 2.16.0. !3888
- Bump Container Registry to v2.9.0-gitlab. !4071
- Default to PG 11 for fresh installs. !4099
- Set PG 11 as the default for pg-upgrade, and update automatically. !4115

### Performance (2 changes, 1 of them is from the community)

- Adjust Puma worker tuning. !4000
- Add more optimized gitconfig. !4050 (Son Luong Ngoc <sluongng@gmail.com)

### Added (12 changes)

- Allow database timeout to be configured for the Rails app. !3844
- Add storage setting for terraform state. !3983
- Allow enabling experimental sidekiq-cluster. !4006
- redis: introduce options for lazy freeing. !4008
- Introduce gitlab-redis-cli. !4020
- Include libjpeg-turbo to enable jpeg support in graphicsmagick. !4027
- Add configuration for Praefect election strategy. !4048
- Generate ActionCable configuration file. !4066
- Adds gitlab-wrapper to praefect runit service to allow setting environment variables and graceful restarts. !4068
- Update Grafana to include Praefect dashboards. !4084
- Add Praefect config for enabling PostgreSQL-backed queue. !4096
- Set server_name for smartcard NGINX server context. !4105

### Other (11 changes, 1 of them is from the community)

- Update logrotate version to 3.16.0. !3961
- Use structure.sql instead of schema.rb. !3969
- Update docutils from 0.13.1 to 0.16. !4017 (Takuya Noguchi)
- Use Go 1.13.9 to build components. !4025
- Build AMIs for all tags except RC and auto-deploy ones. !4036
- Upgrade to Git 2.26.0. !4039
- Update gitlab.rb.template with gitconfig defaults. !4049
- Update gitlab-exporter from 6.1.0 to 7.0.1. !4065
- Upgrade to Git 2.26.2. !4127
- Upgrade Mattermost to 5.21.0.
- Upgrade to Git 2.26.1.


## 12.9.10 (2020-06-10)

- No changes.

## 12.9.9 (2020-06-03)

- No changes.

## 12.9.8 (2020-05-27)

### Security (2 changes)

- Block requests to the grafana avatar endpoint.
- Update Ruby to 2.6.6.


## 12.9.6 (2020-05-05)

- No changes.

## 12.9.5 (2020-04-30)

### Security (2 changes)

- Backport change for updating openssl/openssl from 1f to 1g.
- Remove sensitive info from Docker image.

### Other (1 change)

- Upgrade to Git 2.24.3. !4128


## 12.9.4 (2020-04-16)

### Other (1 change)

- Upgrade to Git 2.24.2.


## 12.9.4 (2020-04-17)

### Other (1 change)

- Upgrade to Git 2.24.2.


## 12.9.3 (2020-04-14)

### Fixed (1 change)

- Upgrade to OpenSSL v1.1.1f. !4087


## 12.9.2 (2020-03-31)

### Fixed (1 change)

- Configures logrotate service for puma. !4024

### Added (1 change)

- Allow setting in seat_link_enabled in gitlab.rb. !4042

### Other (1 change)

- Update Mattermost to 5.20.2.


## 12.9.1 (2020-03-26)

### Security (1 change)

- Bump pcre2 version to 10.34.


## 12.9.0 (2020-03-22)

### Fixed (5 changes, 1 of them is from the community)

- Support running pg-upgrade on geo-postgres in isolation. !3924
- Don't change group ownership of registry directory. !3931 (Henrik Christian Grove <grove@one.com>)
- Fix fetch_assets script for branch names with -z. !3941
- Upgrade pgbouncer_exporter to v0.1.3. !3982
- Fixes case when Geo secondary db changes do not restart the dependent services. !4002

### Changed (5 changes, 1 of them is from the community)

- Restart GitLab Pages when new CA certs installed. !3842 (Ben Bodenmiller)
- Make PostgreSQL log settings configurable. !3949
- Move PostgreSQL runtime logging configuration to runtime.conf. !3955
- Update chef-acme to 4.1.1. !3980
- Bump Container Registry to v2.8.2-gitlab. !3996

### Added (8 changes)

- Build AMIs for GitLab Premium. !3841
- Expose ssh_user as a distinct configuration option. !3925
- Allow advertise_addr to flow to consul services. !3948
- Add logrotate support for services not under gitlab namespace. !3952
- Add the elastic bulk indexer cron worker. !3965
- Geo: Symlink gitlab-pg-ctl command for Geo failover for HA. !3976
- Add smartcard_client_certificate_required_host to gitlab.rb. !3985
- Add failover_enabled top level option in praefect. !3987

### Other (6 changes)

- Add docs about PG 11 being available. !3936
- Update gitlab-org/gitlab-exporter from 6.0.0 to 6.1.0. !3940
- Adds documentation note about updating environment variables for Puma. !3944
- Use the updated gitlab-depscan tool that allows whitelisting CVEs. !3947
- Modify mail_room to output crash logs as json. !3960
- Update Mattermost to 5.20.1.


## 12.8.10 (2020-04-30)

### Security (2 changes)

- Backport change for updating openssl/openssl from 1f to 1g.
- Remove sensitive info from Docker image.


## 12.8.9 (2020-04-14)

### Fixed (1 change)

- Upgrade to OpenSSL v1.1.1f. !4088


## 12.8.7 (2020-03-16)

- No changes.

## 12.8.6 (2020-03-11)

- No changes.

## 12.8.5

- No changes.

## 12.8.4

- No changes.

## 12.8.3

- No changes.

## 12.8.1

- No changes.

## 12.8.0

### Security (2 changes, 1 of them is from the community)

- Update GraphicsMagick to 1.3.34. !3905 (Takuya Noguchi)
- Update postgresql 10.9->10.11, 9.6.14->9.6.16. Resolves CVE-2019-10208.

### Fixed (2 changes)

- Handle worker timeouts configured as strings. !3877
- Fix prepared statements limit in database.yml. !3937

### Deprecated (1 change)

- Pass GitLab Pages secrets as environment variables. !3689

### Changed (10 changes)

- Update gitlab-exporter to 5.2.2. !3848
- Bump registry to v2.7.6-gitlab from v2.7.4-gitlab. !3862
- Bump registry to v2.7.7-gitlab from v2.7.6-gitlab. !3879
- Update gitlab-org/gitlab-exporter from 5.2.2 to 6.0.0. !3906
- Add support for PostgreSQL 11 to gitlab-ctl pg-upgrade. !3907
- Check root before gitlab-ctl reconfigure. !3913
- Don't restart and hup gitaly right after a fresh install. !3918
- Format Unicorn timestamp logs in ISO8601.3 format. !3926
- Bump Container Registry to v2.8.0-gitlab. !3929
- Bump Container Registry to v2.8.1-gitlab. !3934

### Added (9 changes)

- Provide packages for CentOS/RHEL 8. !3748
- Adding Vacuum Queue metrics to postgres-exporter.yaml. !3771
- Support min_concurrency option for sidekiq-cluster. !3867
- Add Pages -gitlab-client-http-timeout and -gitlab-client-jwt-expiry". !3886
- Make GitLab GraphQL timeout configurable. !3916
- Compile repmgr for PG 11. !3919
- Support experimental_queue_selector option for sidekiq-cluster. !3920
- Add setting for environment auto stop worker. !3927
- Add notification on install for PG11. !3935

### Other (6 changes)

- Add PostgreSQL 11 as an alpha database version. !3858
- Update monitoring components. !3874
- Patch Git to get better pack reuse. !3896
- Bump PostgreSQL versions to 9.6.17, 10.12, and 11.7. !3933
- Upgrade Mattermost to 5.19.1.
- Update Mattermost to 5.18.1.


## 12.7.9 (2020-04-14)

### Fixed (1 change)

- Upgrade to OpenSSL v1.1.1f. !4089


## 12.7.8 (2020-03-26)

### Security (1 change)

- Bump pcre2 version to 10.34.


## 12.7.7

### Security (1 change)

- Update postgresql 10.9->10.12, 9.6.14->9.6.17. Resolves CVE-2019-10208.


## 12.7.6

- No changes.

## 12.7.5

### Fixed (1 change)

- Fix promethues duplicate rule. !3891


## 12.7.4

- No changes.

## 12.7.3

- No changes.

## 12.7.2

- No changes.

## 12.7.1

### Fixed (1 change)

- Fetch external URL from EC2 only on fresh installations. !3878


## 12.7.0

### Security (1 change)

- Update Mattermost to 5.17.3 (GitLab 12.6).

### Fixed (1 change)

- Check for puma when setting Geo primary. !3855

### Changed (7 changes, 1 of them is from the community)

- Disable Grafana Reporting & Update Check. !3793 (Stefan Schlesi)
- Update exiftool to 11.70. !3801
- Update gitlab-exporter to 5.1.0. !3806
- Update jemalloc to 5.2.1. !3807
- Update logrotate from r3-8-5 to 3.15.1. !3809
- Use value provided as EXTERNAL_URL during installation/upgrade in gitlab.rb. !3828
- Add grpc_latency_bucket config to praefect. !3854

### Performance (2 changes)

- Update Redis to 5.0.7 and redis-exporter to 1.3.4. !3392
- Raise unicorn memory limits. !3853

### Added (3 changes, 1 of them is from the community)

- Add gitlab-ctl command to fetch Redis master connection details. !3811
- Configure a maximum request duration for GitLab rails. !3830
- Add Service Platform Metrics Grafana dashboard by updating grafana-dashboards to v1.3.0. !3843 (Ben Bodenmiller)

### Other (6 changes)

- Update https://git.code.sf.net/p/libpng/code from 1.6.35 to 1.6.37. !3800
- Update rubygems/rubygems from 2.7.9 to 2.7.10. !3805
- Update chef and chef-zero versions. !3810
- Patch Git to get reused pack info. !3812
- Collect NOTICE files of softwares under Apache license. !3821
- Bump Ruby version to 2.6.5. !3827


## 12.6.7

- No changes.

## 12.6.6

- No changes.

## 12.6.5

### Security (1 change)

- Update Mattermost to 5.17.3 (GitLab 12.6).


## 12.6.4

- No changes.

## 12.6.3

- No changes.

## 12.6.2

- No changes.

## 12.6.1

### Fixed (1 change)

- Revert to passing Redis password as command line argument. !3816


## 12.6.0

### Removed (1 change)

- Stop building packages for openSUSE 15.0. !3753

### Fixed (10 changes, 2 of them are from the community)

- Fix SELinux installation failures on CentOS 8. !3752
- Grafana login should not require local PostgreSQL. !3761
- Set Referrer-Policy for Mattermost to strict-origin-when-cross-origin, allow customization. !3763 (Florian Kaiser)
- write pages template, when api_secret_key is defined. !3770 (Max Wittig)
- Add rack_attack_admin_area_protected_paths_enabled setting. !3773
- Use valid sslmode setting in postgres-exporter. !3777
- Fix inability to disable Connection and Upgrade NGINX headers. !3781
- Fix admin_email_worker_cron rendering in gitlab.yml. !3790
- Use password if provided to detect running Redis version. !3796
- Revert to passing Redis password as command line argument. !3816

### Changed (1 change)

- Allow multiple virtual storages in praefect config. !3754

### Added (5 changes)

- Add personal_access_tokens_expiring_worker configuration to gitlab.rb. !3679
- Add incoming_email_log_file config. !3719
- Add Praefect sentry configs. !3759
- Show warning during reconfigure if version of running Redis instance is different than the installed one. !3787
- Praefect: render database section in config.toml. !3791

### Other (3 changes)

- Upgrade to Git 2.24. !3768
- Change Puma log format to JSON. !3785
- Update Mattermost to 5.17.1.


## 12.5.10

- No changes.

## 12.5.8

### Security (1 change)

- Update Mattermost to 5.16.5 (GitLab 12.5).


## 12.5.7

- No changes.

## 12.5.5

### Fixed (2 changes)

- Fix unwanted Grafana resets during upgrades. !3772
- Bump acme-client version to 2.0.5. !3782


## 12.5.5

- No changes.

## 12.5.4

### Security (1 change, 1 of them is from the community)

- Upgrade git to security patch 2.22.2. (Marin Jankovski)


## 12.5.3

- No changes.

## 12.5.2

### Security (1 change)

- Disable grafana metrics api by default and add option to enable it.


## 12.5.1

- No changes.

## 12.5.0

### Security (1 change)

- Update Mattermost to 5.15.2.

### Fixed (4 changes)

- Build from Docker Distribution fork and update to v2.7.4-gitlab. !3686
- Support alternative PG directories in pg-upgrade. !3701
- Geo: Fix refresh foreign tables on reconfigure. !3728
- Fix praefect prometheus configuration. !3731

### Changed (4 changes)

- Add new format for praefect storage node configuration. !3699
- Make Puma/Unicorn exclusive. !3703
- Add internal_socket_dir to gitaly config. !3711
- Allow to specify `shutdown_blackout_seconds`. !3734

### Added (6 changes)

- Add settings for feature flags unleash client. !3681
- Add gitlab-etc backup to pre-install. !3682
- Add support for GitLab Pages authentication secret. !3705
- Check for non-UTF8 locale during reconfigure. !3708
- Make systemd unit ordering configurable. !3743
- Enable registry using external_url when https is auto enabled. !3747

### Other (6 changes)

- Update Consul Version. !3400
- Add logging directory default for gitlab shell in gitaly config.toml. !3680
- Add prevent_ldap_sign_in option to gitlab.rb. !3692
- Update instructions for adding setting to gitlab.yml. !3710
- Refactor LetsEncrypt auto-enabling logic. !3712
- Update Mattermost to 5.16.2.


## 12.4.8

- No changes.

## 12.4.7

- No changes.

## 12.4.6

### Security (1 change, 1 of them is from the community)

- Upgrade git to security patch 2.22.2. (Marin Jankovski)


## 12.4.4

- No changes.

## 12.4.3

### Security (1 change)

- Update Mattermost to 5.15.2.


## 12.4.2

- No changes.

## 12.4.1

- No changes.

## 12.4.0

### Security (2 changes)

- Update openssl to 1.1.1d. !3674
- Update Grafana version to 6.3.5.

### Fixed (11 changes)

- Nginx responds to health checks with correct content types. !3594
- Fix pg-upgrade handling of secondary database nodes. !3631
- Do not cleanup old gitlab-monitor directory if explicitely using it. !3634
- Resolve "Reconfigure skips Geo DB migrations if Geo DB is not running on the same machine". !3635
- Fix database replication bootstrap with `gitlab-ctl repmgr standby setup`. !3636
- Ensure user's gitconfig contains system's core options. !3648
- Warn when LD_LIBRARY_PATH env var is set. !3652
- Add Rugged search path to Gitaly config. !3656
- Use MD5 checksums in the registry's Google storage driver. !3660
- Don't fail gitaly startup if setting ulimit fails. !3684
- Upgrade PgBouncer to v1.12.0. !3691

### Deprecated (2 changes)

- Deprecates Protected Paths setting. !3597
- Mark openSUSE 15.0 to be warned about during reconfigure. !3687

### Changed (3 changes)

- Update Geo zero downtime instructions. !3562
- Add saturation recording rules to Prometheus. !3665
- Add virtual_storage_name, auth to praefect. !3672

### Added (6 changes, 2 of them are from the community)

- Add skip-auto-backup flag to skip backup during upgrade. !3245 (Dany Jupille)
- Add Praefect as a GitLab service. !3580
- Allow setting of alertmanager global config. !3611
- Update grafana-dashboards to v1.2.0. !3627 (Takuya Noguchi)
- Add TasksMax setting to systemd unit file. !3649
- Build packages for openSUSE 15.1. !3683

### Other (5 changes)

- Consult the gitlab-elasticsearch-indexer version from GitLab. !3276
- Add core.fsyncObjectFiles as default git config. !3632
- Use postgresql_config resource for postgresql configuration files. !3647
- gitlab-shell: use make build instead of bin/compile. !3653
- Update Mattermost to 5.15.


## 12.3.9

### Security (1 change, 1 of them is from the community)

- Upgrade git to security patch 2.22.2. (Marin Jankovski)


## 12.3.8

### Security (2 changes)

- Update Mattermost to 5.14.5 (GitLab 12.3).
- Disable grafana metrics api by default and add option to enable it.


## 12.3.7

- No changes.

## 12.3.4

### Fixed (1 change)

- Update postgresql-bin.json to be generated from a template. !3643


## 12.3.3

- No changes.

## 12.3.2

### Security (1 change)

- Update Grafana version to 6.3.5.


## 12.3.1

- No changes.

## 12.3.0

### Security (2 changes)

- Make logrotate perform operations not as root user.
- Add documentation for configuring an asset proxy server.

### Fixed (5 changes, 1 of them is from the community)

- Wrap prometheus.listen_address value in quotes in the config/gitlab.yml file. !3561
- Show errors when misspelled top-level config is used. !3563
- Change download mirror for unzip software. !3602
- Invoke die method from proper scope. !3604
- Update Mattermost to 5.14.2. (Harrison Healey)

### Changed (3 changes)

- Clean up disabled services for service discovery for prometheus. !3506
- Use file resource instead of using gitlab-keys. !3558
- Removed non-gzipped files for sourcemaps to save on package size. !3592

### Performance (1 change)

- Fix slow fetches for repositories using object deduplication. !3559

### Added (6 changes, 2 of them are from the community)

- Add SMIME email notification settings. !3514 (Diego Louzán)
- Add settings to specify SSL cert and key for DB server. !3529
- Add option to allow some provider bypass two factor. !3543 (Dodocat)
- [Geo]Configuration for Docker Registry Replication. !3549
- Make gitaly open files ulimit configurable. !3560
- Add smartcard_san_extentions to gitlab.rb. !3566

### Other (8 changes, 1 of them is from the community)

- Rename gitlab-monitor to gitlab-exporter. Service name, log directory, prometheus job names and more have been updated. !3517
- Add backup of /etc/gitlab to upgrade process. !3518
- Cleanup deprecated settings list. !3527
- Update monitoring components. !3550
- Regenerate database.ini if missing. !3555
- Deprecate node['gitlab'] monitoring attributes instead of removal. !3583
- Update gitlab-elasticsearch-indexer to v1.3.0. !3587
- Update Mattermost to 5.14. (Harrison Healey)


## 12.2.12

### Security (1 change, 1 of them is from the community)

- Upgrade git to security patch 2.22.2. (Marin Jankovski)


## 12.2.11

### Security (1 change, 1 of them is from the community)

- Upgrade git to security patch 2.22.2. (Marin Jankovski)


## 12.2.10

### Security (1 change, 1 of them is from the community)

- Upgrade git to security patch 2.22.2. (Marin Jankovski)


## 12.2.8

- No changes.

## 12.2.6

### Security (1 change)

- Update Grafana version to 6.3.5.


## 12.2.5

- No changes.

## 12.2.4

### Security (1 change, 1 of them is from the community)

- Update Mattermost to 5.13.3 (GitLab 12.2). (Harrison Healey)


## 12.2.3

- No changes.

## 12.2.2

- No changes.

## 12.2.1

### Fixed (1 change)

- Fix Error 500s when loading repositories with license files. !3542


## 12.2.1

### Security (2 changes)

- Add documentation for configuring an asset proxy server.
- Make logrotate perform operations not as root user.


## 12.2.0

### Security (5 changes, 1 of them is from the community)

- Update nginx to 1.16.1. !3525
- Rename unused redis commands by default. !3436
- Update PostgreSQL to 9.6.14 and 10.9. !3492
- Update GraphicsMagick to 1.3.33. !3494 (Takuya Noguchi)
- Update nginx to 1.16.1. !3525
- Rename Grafana directory as part of upgrade to invalidate user sessions.

### Removed (1 change)

- Stop building packages for openSUSE 42.3. !3469

### Fixed (5 changes)

- Validate runit can set ownership of config files. !3332
- Use armv7 build of Grafana in RPi package. !3401
- A new wrapper for backup and restore to change ownership of registry directory automatically. !3447
- Clean up stale Redis instance config files. !3464
- Typo in initial_license in gitlab.rb. !3497

### Changed (5 changes, 1 of them is from the community)

- Update nginx to version 1.16.0. !3442
- Enable TLS v1.3 by default in NGINX. !3458
- Cleanup unnecessary gem files in gitlab package. !3471
- Support manually setting the db version for psql bin. !3485
- Add default support of ECDSA https certificates in nginx. !3511 (ptymatt)

### Performance (1 change)

- Adjust unicorn worker CPU formula. !3473

### Added (4 changes, 1 of them is from the community)

- Build packages for Debian Buster. !3426
- add option to define custom page headers. !3465 (Max Wittig)
- Add support for Content Security Type. !3499
- Bump the Git version to 2.22. !3502

### Other (6 changes, 1 of them is from the community)

- Upgrade rubocop to 0.69.0. !3473
- Upgrade gitlab-monitor to 4.2.0. !3483
- Attempt to upgrade the database in the docker image. !3515
- Bump ohai version to 14.14.0. !3523
- Update Mattermost to 5.13.2. (Harrison Healey)
- Add perl dependency to SSL troubleshooting steps.


## 12.1.17

### Security (1 change, 1 of them is from the community)

- Upgrade git to security patch 2.21.1. (Marin Jankovski)

### Other (1 change)

- Consult the gitlab-elasticsearch-indexer version from GitLab. !3663


## 12.1.16

- No changes.

## 12.1.15

### Security (1 change, 1 of them is from the community)

- Upgrade git to security patch 2.21.1. (Marin Jankovski)

### Other (1 change)

- Consult the gitlab-elasticsearch-indexer version from GitLab. !3663


## 12.1.14

- No changes.

## 12.1.13

- No changes.

## 12.1.12

- No changes.

## 12.1.11

- No changes.

## 12.1.10

- No changes.

## 12.1.10

### Security (1 change)

- Update Grafana version to 6.3.5.


## 12.1.5

### Security (1 change)

- Automatically set an admin password for Grafana and disable basic authentication.


## 12.1.4

- No changes.

## 12.1.3

### Other (1 change)

- Fix bzip2 location. !3448


## 12.1.2

- No changes.

## 12.1.2

- No changes.

## 12.1.1

- No changes.

## 12.1.0

### Security (1 change, 1 of them is from the community)

- Update Mattermost to 5.11.1 (GitLab 12.0). (Harrison Healey)

### Fixed (15 changes, 2 of them are from the community)

- Auto-enable Let's Encrypt for certificate renewal. !3342
- Use PostgreSQL username from node attribute file in gitlab-ctl command. !3352
- gitaly: prometheus not working with tls enabled. !3353 (Roger Meier)
- Support pg-upgrade on dbs with collate and ctype values that differ from each other. !3371
- Properly check whether postgres is enabled when doing pg-ugprade. !3381
- Bring back the option to use the authorized keyfile in docker. !3388
- Get prometheus home directory from node attributes. !3395
- Create the uploads_storage_path directory. !3396
- Fix upgrade time calculation metric. !3397
- Fix GitLab upgrades crashing when LetsEncrypt cert needs renewal. !3402
- Set ALTERNATIVE_SOURCES for tests. !3412
- Fix error with repmgr and PostgreSQL 9. !3417
- Make Roles respect user specified configuration. !3423
- Enable specifying --path in bundle install on Ruby docker images. !3432
- Update Mattermost to 5.12.4. (Harrison Healey)

### Deprecated (1 change)

- Remove bundled MySQL client and related docs. !3382

### Changed (5 changes)

- Ensure we only grab the last line of stdout from rails runner. !3406
- Set INSTALLATION_TYPE of Marketplace AMI to gitlab-aws-marketplace-ami. !3414
- Add support for ACME v2. !3420
- Run before_fork only once on boot for Unicorn.
- Update redis_exporter to 1.0.3.

### Added (8 changes, 1 of them is from the community)

- Add recording rules for SLIs. !3335
- Build packages for openSUSE 15.0. !3343
- Add worker configuration for pages domain ssl renewal through Let's Encrypt. !3355
- Add prometheus settings to gitlab.yml. !3383
- Add a role for monitoring. !3404
- Add smartcard_required_for_git_access to gitlab.rb. !3415
- Add ability to set 'maxsize' for logrotate configs. !3419
- add option to enable sentry and to define dsn/environment for pages. !3424 (Roger Meier)

### Other (7 changes, 2 of them are from the community)

- Upgrade to OpenSSL 1.1.1c. !3069
- Add GEO support to pg-upgrade. !3316
- Use Go module vendoring for builds. !3337
- Bump Chef related libraries to 14.x. !3344
- Use Postgresql 10.7 instead of 10.7.0. !3387 (Takuya Noguchi)
- Enable frame pointer in Redis compile options. !3421
- Update Mattermost to 5.12.2. (Harrison Healey)

## 12.0.10

### Security (2 changes, 2 of them are from the community)

- Update Mattermost to 5.11.1 (GitLab 12.0). (Harrison Healey)
- Upgrade git to security patch 2.21.1. (Marin Jankovski)

### Fixed (5 changes)

- Support pg-upgrade on dbs with collate and ctype values that differ from each other. !3371
- Properly check whether postgres is enabled when doing pg-ugprade. !3381
- Use armv7 build of Grafana in RPi package. !3401
- Fix error with repmgr and PostgreSQL 9. !3417
- Enable specifying --path in bundle install on Ruby docker images. !3432

### Performance (1 change)

- Fix slow pushes for repositories using object deduplication. !3364

### Other (1 change)

- Fix bzip2 location. !3448


## 12.0.10

### Security (2 changes, 2 of them are from the community)

- Update Mattermost to 5.11.1 (GitLab 12.0). (Harrison Healey)
- Upgrade git to security patch 2.21.1. (Marin Jankovski)

### Fixed (5 changes)

- Support pg-upgrade on dbs with collate and ctype values that differ from each other. !3371
- Properly check whether postgres is enabled when doing pg-ugprade. !3381
- Use armv7 build of Grafana in RPi package. !3401
- Fix error with repmgr and PostgreSQL 9. !3417
- Enable specifying --path in bundle install on Ruby docker images. !3432

### Performance (1 change)

- Fix slow pushes for repositories using object deduplication. !3364

### Other (1 change)

- Fix bzip2 location. !3448


## 12.0.9

### Security (2 changes, 1 of them is from the community)

- Patch nginx 1.14.2 for CVE-2019-9511, CVE-2019-9513, CVE-2019-9516.
- Update Mattermost to 5.11.1. (Marc Schwede)


## 12.0.8

### Security (2 changes)

- Add documentation for configuring an asset proxy server.
- Make logrotate perform operations not as root user.


## 12.0.7

### Security (2 changes)

- Add documentation for configuring an asset proxy server.
- Make logrotate perform operations not as root user.


## 12.0.6

### Security (1 change)

- Rename Grafana directory as part of upgrade.


## 12.0.5

### Security (1 change)

- Automatically set an admin password for Grafana and disable basic authentication.


## 12.0.3 (2019-07-01)

- No changes.

## 12.0.2 (2019-06-25)

- No changes.

## 12.0.1 (2019-06-24)

### Fixed (1 change)

- Fix upgrade version check in preinst to handle double-decimal-digit versions. !3369


## 12.0.0 (2019-06-22)

### Removed (4 changes)

- Remove old env directory cleaning. !3290
- Remove support for skip-auto-migrations file. !3306
- Remove TLSv1.1 support in nginx. !3307
- Remove Prometheus 1.x support. !3315

### Fixed (11 changes)

- Add timeout option to pg-upgrade command. !3284
- Ensure reconfigure has succeeded reading node attributes. !3302
- Set default path for git storage directories if user didn't specify one. !3304
- Get node attribute file from directory contents if hostname is empty. !3309
- Ensure sidekiq and gitlab-monitor are restarted when the ruby version changes. !3317
- Upgrade node-exporter to 0.18.1. !3326
- Update Prometheus exporters. !3328
- Handle special characters in FDW passwords. !3339
- Hup Mattermost after a version upgrade. !3340
- Fix Unicorn not cleaning up stale metrics file at startup. !3350
- Don't fail on public attribute file on missing 'normal' key. !3358

### Deprecated (1 change)

- Mark openSUSE 42.3 as deprecated. !3334

### Changed (6 changes)

- Extracted postgresql recipe logic in gitlab recipe to its own recipe. !2794
- Enable Grafana by default and configure GitLab SSO. !3272
- Make PostgreSQL 10.7 the default version. !3291
- Default to JSON logging when possible. !3292
- Allow health check endpoints to be access via plain http. !3296
- Remove old chef state before running chef commands. !3310

### Performance (2 changes)

- Upgrade Ruby to 2.6.3. !3119
- Disable AuthorizedKeysFile in Docker. !3198

### Added (6 changes, 1 of them is from the community)

- Allow configuring an HTTP proxy for GitLab Pages. !3060 (Ben Anderson)
- Add Pages `-insecure-ciphers` support. !3275
- Add Pages -tls-min-version and -tls-max-version support. !3286
- Service discovery for Prometheus via Consul. !3295
- Replace --auth-server with --gitlab-server flag for pages. !3314
- Make gitaly git.catfile_cache_size configurable. !3329

### Other (13 changes, 2 of them are from the community)

- Update python to 3.7.3 with updated libedit patches. !3274 (Takuya Noguchi)
- GitLab-Pages can output JSON format logs. !3288
- Ensure reconfigure runs with our desired version of the acme-client gem. !3294
- Update sysctl to use --system option. !3298
- Set 11.11 to be the minimum version required to upgrade to 12.0. !3300
- Document Setting Logs to Non-JSON Format. !3303
- Remove PG 9.6 to 9.6.8 directory symlink. !3305
- Publish unlicensed EE AMI to Community AMIs. !3331
- Update gitlab-elasticsearch-indexer to v1.2.0. !3331
- Skip automatic pg-upgrade on GEO. !3338
- Specify Ruby 2.6.3 for development. !3345
- Update Mattermost to 5.11.0. (Harrison Healey)
- Stop printing certificate skipped messages, instead list which certs were copied.


## 11.11.8

### Security (1 change, 1 of them is from the community)

- Update Mattermost to 5.10.2 (GitLab 11.11). (Harrison Healey)


## 11.11.7

- No changes.

## 11.11.5 (2019-06-27)

- No changes.

## 11.11.4 (2019-06-26)

### Other (1 change)

- Publish unlicensed EE AMI to Community AMIs. !3331


## 11.11.3 (2019-06-10)

### Fixed (2 changes)

- Fix bug in pg-upgrade HA detection. !3287
- Pass cron directory to crond run file. !3327


## 11.11.2 (2019-06-04)

### Fixed (1 change, 1 of them is from the community)

- Update Mattermost to 5.10.1 (GitLab 11.11). (Harrison Healey)


## 11.11.1 (2019-05-30)

- No changes.

## 11.11.0 (2019-05-22)

### Security (1 change)

- Upgrade RubyGems to 2.7.9. !3082

### Removed (1 change)

- Remove postgres auto-upgrade from Docker images for 11.11.0 release.

### Fixed (4 changes)

- Run pg_upgrade with configured postgres username. !3162
- Fix Grafana GitLab Authentication. !3195
- Run repmgr's psql commands as the specified user. !3224
- Remove timestamp prefix from JSON formatted registry logs.

### Deprecated (1 change)

- Stop building Ubuntu 14.04 packages. !3192

### Changed (4 changes)

- Patch bundle install in CentOS 6 to install sassc gem using newer GCC. !3112
- Enable additional node metrics. !3207
- geo_log_cursor is located in ee/bin/ now. !3223
- Bump Grafana Dashboards. !3241

### Performance (2 changes)

- Use AuthorizedKeysCommand in Docker builds. !3191
- Remove smaps metrics from gitlab-monitor. !3279

### Added (12 changes, 2 of them are from the community)

- Bundle PostgreSQL 10 with the package. !3142
- Docker: attempt to cleanup stale pids on restart. !3200
- Decouple Geo node identity from external_url. !3201
- Add configuration support for dependency proxy feature. !3206
- add option to define Sentry settings. !3214 (Roger Meier)
- Support gitlab-shell feature flags through gitlab.rb. !3215
- Upgrade Git to 2.21. !3220
- Add HA support for pg-upgrade command. !3240
- Add pages domain removal cron configuration. !3246
- Allow Sentry client-side DSN to be passed on gitlab.yml. !3249
- add option to define Sentry environment for gitaly. !3253 (Roger Meier)
- Add option to provide license during initial installation. !3265

### Other (7 changes, 2 of them are from the community)

- Bump Prometheus components to the latest. !3182
- Update liblzma to 5.2.4. !3197
- Update libtool to 2.4.6. !3210
- Move sidekiq-cluster to ee/bin. !3216
- Rename library methods to make their function explicit. !3222
- Update Mattermost to 5.10.0. (Harrison Healey)
- Stop raspberry pi builds during nightlies. (John T Skarbek)

## 11.10.8 (2019-07-01)

- No changes.

## 11.10.7 (2019-06-26)

- No changes.


## 11.10.6 (2019-06-04)

### Fixed (1 change)

- Pin procfs version used for building redis-exporter. !3319


## 11.10.4 (2019-05-01)

### Security (1 change, 1 of them is from the community)

- Update Mattermost to 5.9.1 (GitLab 11.10). (Harrison Healey)


## 11.10.3 (2019-04-30)

### Fixed (1 change)

- Update exclusion of gem cache to match ruby 2.5. !3243

## 11.10.2 (2019-04-25)

- No changes.

## 11.10.1 (2019-04-23)

- No changes.


## 11.10.0 (2019-04-22)

### Security (1 change)

- Bundle exiftool as a dependency.

### Fixed (3 changes)

- Use a fixed git abbrev parameter when we fetch a git revision. !3143
- Fix bug where passing -w to pg-upgrade aborted the process. !3164
- Update WorkhorseHighErrorRate alert. !3183

### Changed (3 changes)

- Remove gitlab-markup custom patches. !3115
- Add grafana-dashboards to auto-provisioning. !3141
- Set the default LANG variable in docker to support UTF-8. !3159

### Added (7 changes, 2 of them are from the community)

- Refactor Prometheus rails scrape config. !3046 (Ben Kochie <bjk@gitlab.com>)
- Support conditional external diffs. !3059
- Support for registry-garbage-collect command. !3097
- Add sub_module to bundled nginx. !3100 (Rafael Gomez)
- Add gitaly graceful restart wrapper. !3116
- Add optional db_name to "gitlab-ctl replicate-geo-database". !3124
- Add default Referrer-Policy header. !3138

### Other (9 changes, 2 of them are from the community)

- Upgrade jemalloc to 5.1.0. !2957
- Update CA Certificates to 2019-01-23. !3095
- Add gitlab_shell.authorized_keys_file to gitlab.yml. !3096
- Update to latest krb5 version 1.17. !3114
- Update to latest libxml2. !3156
- Update bundler to 1.17.3. !3157 (Takuya Noguchi)
- Share AWS AMIs with the Marketplace account. !3190
- Move software built from git to omnibus-mirror. !3228
- Update Mattermost to 5.9.0 (GitLab 11.10). (Harrison Healey)

## 11.9.12 (2019-05-30)

### Security (1 change, 1 of them is from the community)

- Update Mattermost to 5.8.2 (GitLab 11.9). (Harrison Healey)

## 11.9.11 (2019-04-30)

- No changes.

## 11.9.10 (2019-04-26)

- No changes.


## 11.9.9 (2019-04-23)

### Other (1 change)

- Move software built from git to omnibus-mirror. !3228

## 11.9.8 (2019-04-11)

- No changes.

## 11.9.7 (2019-04-09)

- No changes.

## 11.9.6 (2019-04-04)

### Fixed (1 change)

- Fix Grafana auth URLs. !3139

## 11.9.5 (2019-04-03)

### Security (1 change, 1 of them is from the community)

- Update Mattermost to 5.8.1. (Harrison Healey)

### Fixed (1 change)

- Fix typo in Prometheus v2 rules. !3145

## 11.9.3 (2019-03-27)

- No changes.

## 11.9.2 (2019-03-26)

### Security (1 change)

- Bundle exiftool as a dependency.


## 11.9.1 (2019-03-25)

- No changes.


## 11.9.0 (2019-03-22)

### Security (2 changes)

- Delete build artifacts from AMIs before publishing. !3044
- Upgrade to OpenSSL 1.0.2r. !3066

### Fixed (6 changes, 2 of them are from the community)

- Fix permissions of repositories directory in update-permissions script. !3029 (Matthias Lohr <mail@mlohr.com>)
- Fix issue with sshd failing in docker with user remap and privileged. !3047
- Allow Geo tracking DB user password to be set. !3058
- Restore docker registry compatibility with old clients using manifest v2 schema1. !3061 (Julien Pervillé)
- Automatically configure Prometheus alertmanager. !3071
- Ensure gitaly is setup before migrations are run.

### Deprecated (1 change)

- Update nginx to version 1.14.2. !3065

### Changed (1 change)

- Upgrade gitlab-monitor to 3.1.0. !3052

### Added (5 changes)

- Add Prometheus support to Docker Registry. !2884
- Add option to disable init detection. !3028
- Add Grafana service. !3057
- Support Google Cloud Memorystore by disabling Redis CLIENT. !3072
- Support Google Cloud Memorystore in gitlab-monitor. !3084

### Other (6 changes, 4 of them are from the community)

- Update mixlib-log from 1.7.1 to 3.0.1. !2951
- Stop building packages for Raspbian Jessie. !3004
- Update python to 3.4.9. !3040 (Takuya Noguchi)
- Update docutils to 0.13.1. !3042 (Takuya Noguchi)
- Replace deprecated "--no-ri --no-rdoc" in rubygems. !3050 (Takuya Noguchi)
- Update Mattermost to 5.8. !3070 (Harrison Healey)

## 11.8.10 (2019-04-30)

- No changes.

## 11.8.9 (2019-04-25)

- No changes.

## 11.8.8 (2019-04-23)

### Security (1 change, 1 of them is from the community)

- Upgrade Mattermost to 5.7.3 (GitLab 11.8). !3137 (Harrison Healey)

## 11.8.7 (2019-04-09)

- No changes.

## 11.8.6 (2019-03-28)

- No changes.

## 11.8.5 (2019-03-27)

- No changes.


## 11.8.4 (2019-03-26)

### Security (1 change)

- Bundle exiftool as a dependency.

## 11.8.3 (2019-03-19)

- No changes.

## 11.8.2 (2019-03-13)

### Fixed (2 changes, 1 of them is from the community)

- Restore docker registry compatibility with old clients using manifest v2 schema1. !3061 (Julien Pervillé)
- Ensure gitaly is setup before migrations are run.

### Other (1 change, 1 of them is from the community)

- Update Mattermost to 5.7.2. !3080 (Harrison Healey)

## 11.8.1 (2019-02-28)

### Fixed (1 change)

- Add support for restart_command in runit cookbook. !3062

### Added (1 change, 1 of them is from the community)

- Adding scripts/changelog. !3009 (Ian Baum)


## 11.8.0 (2019-02-22)

- Remove Redis config from gitlab-shell !3000
- Add AWS customer provided encryption key configuration option !2928
- Fix mattermost data directory permissions with ```update-permissions```
- Properly encode the Redis password component in the URL !2999
- Patch runit to not consider status of log service for `status` command exit
  code !2949
- Upgrade libpng to 1.6.36 !2950
- Fix invalid registry redirect url when using the default ports (jelhan) !2961
- Update runit cookbook to v4.3.0 !2902
- Turn on http to https redirection for Registry and Mattermost if LE
  integration is used !2968
- Make registry validation configurable !2992
- Upgrade Docker registry to 2.7.1 !2970
- Upgrade Nginx to 1.12.2 !2988
- Bump gitlab-elasticsearch-indexer to 1.0.0
- Include experimental Docker Distribution Pruner !2946
- Update Prometheus to v2.6.1 !2981
- Update Prometheus node_exporter to v0.17.0 !2981
- Update Prometheus redis_exporter to v0.26.0 !2981
- Support smartcard auth against LDAP server !3006
- Update Mattermost to 5.7.1
- Update Prometheus alerting rules !3011
- Allow external diffs for merge requests to be configured

## 11.7.12 (2019-04-23)

- No changes.

## 11.7.11 (2019-04-09)

- No changes.

## 11.7.10 (2019-03-28)

- No changes.

## 11.7.9 (2019-03-27)

- No changes.


## 11.7.8 (2019-03-26)

### Security (1 change)

- Bundle exiftool as a dependency.

## 11.7.7 (2019-03-19)

- No changes.

## 11.7.0

- Disable nginx proxy_request_buffering for git-receive-pack !2935
- Hide transfer of refs/remotes/* in git config !2932
- Add option to specify a registry log formatter !2911
- Ensure env values are converted to strings (Romain Tartière) !2923
- Make location of repmgr.conf dynamic in run file and gitlab-ctl commands !2924
- Enabled ENA networking and SRIOV support to AMIs !2867
- Drop support for Debian Wheezy !2943
- Restart sidekiq-cluster when relevant changes occur !2945
- Support TLS communication with gitaly

## 11.6.11 (2019-04-23)

- No changes.

## 11.6.10 (2019-02-28)

- No changes.

## 11.6.3

- Fix Docker registry not working with Windows layers !2938
- Remove deprecated OpenShift template !2936
- Update Mattermost to 5.6.2
- Fix warnings/errors when Prometheus is disabled. !2940

## 11.6.2

- Fix environment variables not being cleaned up !2934

## 11.6.0

- Switch restart_command for Unicorn service to signal HUP instead of USR2 !2905
- Upgrade Ruby to 2.5.3 !2806
- Deprecate postgresql['data_dir'] !2846
- Move env directory of all services to `/opt/gitlab/etc/<service>/env` !2825
- Move the postgres install to being located under its major version path !2818
- Add support for Git v2 protocol in docker image's `sshd_config` !2864
- Add client support for Redis over SSL !2843
- Disable sidekiq probes of gitlab-monitor by default in Redis HA mode and
  provide `probe_sidekiq` attribute to control it. !2872
- Update docker registry to include a set of patches from the upcoming 2.7.0 release !2888
- Update Mattermost to 5.5.0
- Add impersonation_enabled configuration to gitlab.rb !2880
- Update runit version to 2.1.2 !2897
- Update Prometheus components !2891
- Add smartcard configuration to gitlab.rb !2894

## 11.5.11 (2019-04-23)

- No changes.

## 11.5.8

- Hide transfer of refs/remotes/* in git config

## 11.5.2

- Make remote-syslog detect log directories of all services correctly !2871

## 11.5.1

- Update GITLAB_PAGES_VERSION to 1.3.1
- Update GITLAB_WORKHORSE_VERSION to 7.1.3
- Update postgresql to 9.6.11 !2840

## 11.5.0

- Add experimental support for Puma !2801
- Move to standardized cluster lifecycle event handlers in preparation for Puma support !2728
- Update gitlab-monitor to 2.19.1
- Add option to configure consul group !2781
- Add Prometheus alerts for GitLab components !2753
- Update required `gitlab-elasticsearch-indexer` version to 0.3.0 for Elasticsearch 6 support !2791
- Add option to configure postgresql group !2780
- Add option to configure prometheus group !2782
- Add option to configure redis group !2784
- Upgrade Bundler version to 1.16.6
- Omit Gitaly development and test gems !2808
- Support for Pages access control settings (Turo Soisenniemi)
- Pages: Support limiting connection concurrency !2815
- Geo: Fix adding a password to the FDW user mapping !2799
- Specify groups while running services and `gitlab-` prefixed commands !2785
- Update Mattermost to 5.4.0
- Warn users when postgresql needs to be restarted due to version changes !2823
- Ensure postgres doesn't automatically restart when it's run file changes !2830
- Add nginx-module-vts for Prometheus metrics collection !2795
- Ensure pgbouncer is shut down when multiple master situation is encountered
  and resumed when it is cleared !2812
- Provide SSL_CERT_DIR to embedded Go services !2813

## 11.4.8

- Update GITLAB_PAGES_VERSION to 1.1.1
- Update GITLAB_WORKHORSE_VERSION to 7.0.1

## 11.4.1

- Upgrade Ruby version to 2.4.5

## 11.4.0

- Enable omniauth by default !2728
- Update Mattermost to 5.3.1
- Fix identification of Prometheus's rule directory !2736
- Run geo_prune_event_log_worker_cron every 5min
- Fix workhorse log path in the Docker fix update-permission script !2742 (Matteo Mazza)
- Remove recursive chown for public directory !2743
- Update libpng to 1.6.35 !2746
- Update redis to 3.2.12 !2750
- Update libgcrypt to 1.8.3 !2747
- Update npth version to 1.6
- Update libgpg-error to 1.32
- Update libassuan to 2.5.1
- Update gpgme to 1.10.0
- Update gnupg to 2.2.10
- Bump git to 2.18.1
- Set only files under trusted_cert directory explicitly to user read/write and group/other read. !2755
- Use Prometheus 2.4.2 for new installs. Deprecate Prometheus 1.x and add
  prometheus-upgrade command !2733

## 11.3.11

- Update GITLAB_PAGES_VERSION to 1.1.1
- Update GITLAB_WORKHORSE_VERSION to 6.1.2

## 11.3.4

- Bump git to 2.18.1

## 11.3.2

- Update pgbouncer cookbook to not regenerate databases.ini on hosts using consul watchers

## 11.3.1

- Update Mattermost to 5.2.2

## 11.3.0

- Support max_concurrency option in sidekiq_cluster
- Support Redis hz parameter
- Support Redis tcp-backlog parameter
- Disable SSL compression by default when using gitlab-psql or gitlab-geo-psql
- Increase Sidekiq RSS memory limit from 1 GB to 2 GB
- Add /metrics endpoint to gitlab_monitor !2719 (Maxime)
- Reload sysctl if a new symlink is created in /etc/sysctl.d
- Bump omnibus-ctl to v0.6.0 !2715
- Add missing pgbouncer options
- Add plugin_directory and plugin_client_directory to supported Mattermost
  settings !2649

## 11.2.3

- Fix custom runtime_dir not working
- Geo Secondary: ensure rails enabled when Gitaly enabled !2720
- Update Mattermost to 5.2.1
- Update libiconv to 1.15
- Update libiconv zlib and makedepend build recipe to improve build cache reuse

## 11.2.1

- Fix bzip2 download source
- Allow configuration of maven package repository

## 11.2.0

- Bump git to 2.18.0 !2636
- Bump Prometheus Alertmanager to 0.15.1 !2664
- Update gitlab-monitor to 2.18.0 !2662
- Update gitlab-monitor to 2.17.0
- Enable rbtrace for unicorn if ENABLE_RBTRACE is set
- Fix database.yml group setting to point at the proper user['group']
- Fix Prometheus metrics not working out of the box in Docker
- Make gitlab-ctl repmgr standby setup honor postgresql['data_dir']
- Update Mattermost to 5.1.1
- Update repmgr-check-master to exit 1 for standby nodes
- Run GitLab service after systemd multi-user.target !2632
- Update repmgr-check-master to exit 1 for standby nodes
- Geo: Fix replicate-geo-database not working with a custom port

## 11.1.1

- Update Mattermost to 5.0.2
- Omit SLAVEOF if Redis is in an HA environment !2651
- Export PYTHONPATH and ICU_DATA to gitaly !2650
- Restore gitaly default log level to 'info' !2661

## 11.1.0

- Include OSS driver for object storage support in the registry
- Support setting of PostgreSQL SSL mode and compression in repmgr conninfo
- Disable PostgreSQL SSL compression by default
- Tighten permission on Mattermost's config.json file !2587
- Tighten permission on Gitaly's config.toml file !2589
- Tighten permission on gitlab-shell's config.yml file !2585
- Add an option to activate verbose logging for GitLab Pages (maxmeyer)
- Don't attempt to modify PostgreSQL users if database is in read-only mode
- Remove NGINX custom page for 422 errors
- Tighten permission on gitlab-monitor's gitlab-monitor.yml file !2584
- Tighten permission on gitlab.yml file !2591
- Tighten permission on database.yml file !2592
- Add support for Prometheus remote read/write services.
- Add support for database service discovery
- Tighten permission on geo's database_geo.yml file !2590
- Set TZ environment variable for gitlab-rails to ':/etc/localtime' to decrease
  number of system callse - !2600
- Don't add timestamp to gitaly logs if logging format is json !2615
- Remove hardcoded path for pages secrets (julien MILLAU)
- Tighten permission on gitlab-workhorse's config.toml file !2586
- Add pseudonymizer data collection worker
- Update node_exporter to 0.16.0, metric names have been changed !2639
- Update alertmanager to 0.15.0 !2639
- Update redis_exporter to 0.20.2 !2639
- Update postgres_exporter to 0.4.6 !2641
- Update pgbouncer_exporter to 0.0.3-gitlab !2617
- Update Mattermost to 5.0.0

## 11.0.3

- Revert change to default unicorn/sidekiq listen address.
- Add Prometheus relabel configs to change display from 127.0.0.1 to localhost
- Tighten permission on pgbouncer and consul related config files !2588

## 11.0.2

- Set the default for geo_prune_event_log_worker_cron to once/2hours
- Restart geo-logcursor when unicorn or sidekiq are updated
- Fix Prometheus Unicorn metrics not coming back after a HUP
- Set the default for geo_prune_event_log_worker_cron to once/2hours

## 11.0.1

- No changes

## 11.0.0

- Disable PgBouncer PID file by default
- Add pgbouncer_exporter
- Bump minimum version required for upgrade to 10.8 2df263267
- Geo: Only create database_geo.yml and run migrations if Rails is enabled
- Render gitlab-pages admin settings
- Fix old unicorn master not quitting after a new process is running
- Mattermost: Fix reconfiguration of GitLab OAuth configuration settings
- Bump PgBouncer to 1.8.1
- Automatically add registry hostname to the to alt_name of the
  LetsEncrypt certificate #3343
- Use localhost hostname for unicorn and sidekiq listeners
- Add ipv6 loopback to monitoring whitelist
- Remove deprecated Mattermost settings and use environment variables to set
  supported ones. !2522
- Bump git to 2.17.1 !2552
- Updated Mattermost to 4.10.1
- Render gitaly-ruby num_workers config
- Set installation type information to be used by usage ping - !2561
- Add graphicsmagick dependency
- Add cron job for archiving-trace worker
- Add attribute to control automatic registration of a database node as master
  on initialization !2571
- Add PostgreSQL support for default_statistics_target

## 10.8.5
- Geo: Make sure gitlab_secondary schema has the correct owner

## 10.8.2

- Automatically restart Gitaly when its VERSION file changes
- Update gitlab-monitor to 2.16.0
- No need to patch `lib/gitlab.rb` anymore since it now reads the REVISION file if present
- Upgrade git to 2.16.4

## 10.8.1

- Add git_data_dir to the deprecation list 7d04ed06b
- Geo: Set recovery_target_timeline to latest by default
- Remove deprecated git_data_dir configuration and old hash format of
  git_data_dirs configuration !2520
- Upgrade Ruby version to 2.4.4
- Upgrade Bundler version to 1.16.2
- Upgrade Rubygems version to 2.7.6
- Add support for Prometheus rules files

## 10.8.0

- Force kill unicorn process if it is still running after a TERM or INT signal
- Upgrade Ruby version to 2.3.7
- Update gitlab-monitor to 2.13.0
- Add Prometheus Alertmanager
- Bump git to 2.16.3
- Bump curl to 7.59.0 aab088263
- Bump pcre to 8.42 07c83a5ab
- Bump rubygems to 2.6.14 84b2510fd
- Bump openssl to 1.0.2o 1fe9f4ef2
- Do not ship cached gem archives. #3235
- Excludes source assets from gitlab-rails component.  #3238
- Keep gitaly service running during package upgrades 034992fbc
- Geo: Error when primary promotion fails
- Geo: Disable SSL compression by default in generating recovery.conf
- Add option to disable healthcheck for storagedriver in registry
- Enable gzip by default
- Restart runsv when log directory is changed 0a784647b
- Bump rsync to 3.1.3 f539aa946
- Patch bzip2 against CVE-2016-3189 552730bfa
- Fix pgbouncer recipe to use the correct user for standalone instances
- Commands `gitlab-psql` and `gitlab-geo-psql` will use respective GitLab databases by default. #3485
- Make pg-upgrade start the bundled postgresql server if it isn't already running
- Enforce upgrade paths for package upgrades 56a250b1a
- Patch unzip to fix multiple CVEs cefd5b1b6
- Geo: Success message for `gitlab-ctl promote-to-primary-node` command

## 10.7.5

- Upgrade Git to 2.14.4

## 10.7.4

- Geo: promoting secondary node into primary doesnt remove `database_geo.yml` #3463
- Only create gitlab-consul database user after repmgr database has been created
- Make migrations during upgrade only stop unecessary services

## 10.7.3

- Add support for the `-daemon-inplace-chroot` command-line flag to GitLab Pages

## 10.7.2

- No changes

## 10.7.1

- No changes
- Bump libxslt to 1.1.32 f584de1d7
- Bump libxml2 to 2.9.8 e3a117275
- Update Mattermost to 4.9.1

## 10.7.0

- Geo: Increase default WAL standby settings from 30s to 60s
- Geo: Add support for creating a user for the  pgbouncer on the Geo DB
- Geo: Add cron job for migrated local files worker
- Disable 3DES ssl_ciphers of nginx for gitlab-rails, mattermost, pages, and
  registry (Takuya Noguchi)
- Add option to configure log_statement config in PostgreSQL
- Internal: Speed up rubocop job (Takuya Noguchi)
- Bump redis_exporter to 0.17.1
- Excludes static libraries, header files, and `*-config` binaries from package.
- Support Sidekiq log_format option
- Render gitlab-shell log_format option
- Support `direct_upload` for Artifacts and Uploads
- Set proxy_http_version to ensure request buffering is disabled for GitLab Container Registry
- Auto-enable Let's Encrypt certificate management when `external_url`
  is of the https protocol, we are terminating ssl with the embedded
  nginx, and certficate files are absent.
- Fix bug where changing log directory of gitlab-monitor had no effect 1e451dc2
- Updated Mattermost to 4.8.1
- Create shared/{tmp,cache} directories when manage-storage-directories is enabled
- Render Gitaly logging_ruby_sentry_dsn config option
- Fix bug in error reporting of `gitlab-ctl renew-le-certs` #3389
- Adds go-crond to the package #3251
- Auto-renew LetsEncrypt with go-crond #3251

## 10.6.6

- Update Git to 2.14.4

## 10.6.5

- Update Mattermost to 4.7.4

## 10.6.4

- Fixes an issue where unicorn and sidekiq services weren't being restarted after their configuration changed.
- Added missing Mattermost settings to gitlab.rb

## 10.6.2

- Geo: many fixes in FDW support, making it enabled by default in Secondary node.
- Fixed omnibus deprecations in PostgreSQL resources DSL

## 10.6.1

- Pages: if logformat set to json, do not append timestamps with svlogd.
- Downgrade jemalloc to 4.2.1 to avoid segfaults in Ruby

## 10.6.0

- Geo: When upgrading we keep geo-postgresql up to run database migrations
- Geo: Add cron configuration for repository verification workers
- Warn users of stale sprockets manifest file after install 8d4cd46c (David Haltinner)
- Geo: Don't attempt to refresh FDW tables if FDW is not enabled
- Deprecate `/etc/gitlab/skip-auto-migrations` for `/etc/gitlab/skip-auto-reconfigure`
- Update python to 3.4.8 (Takuya Noguchi)
- Update jemalloc to 5.0.1
- Update chef to 13.6.4
- Unsets `RUBYLIB` in `gitlab-rails`, `gitlab-rake`, and `gitlab-ctl` to avoid
  interactions with system ruby libraries.
- Update rainbow to 2.2.2, package_cloud to 0.3.04 and rest-client to 2.0.2 (Takuya Noguchi)
- Use awesome_print gem to print Ruby objects to the user 761a1e6a
- Update postgresql to 9.6.8
- Remove possible remains of relative_url.rb file that was used in earlier versions 88de20f18
- Add `announce-ip` and `announce-port` options for Redis and Sentinel (Borja Aparicio)
- Support the `-logFormat` option in Workhorse
- Update rubocop to 0.52.1 (Takuya Noguchi)
- Restart geo-logcursor when database_geo.yml is updated
- Change the default location of pgbouncer socket to /var/opt/gitlab/pgbouncer
- Excludes unused `/opt/gitlab/embedded/service/gitlab-shell/{go,go_build}`
  directories.
- Updated Mattermost to 4.7.3
- Add `proxy_download` options to object storage
- Add `lfs_object_store_direct_upload` option
- Render the gitlab-pages '-log-format' option
- Workhorse: if logformat set to json, do not update timestamps with svlogd.
## 10.5.8

- Update Mattermost to 4.6.3

## 10.5.7

- No changes

## 10.5.6

- No changes

## 10.5.5

- Resolve "consul service postgresql_service failing on db host - no access to /opt/gitlab/embedded/node

## 10.5.8

- Update Mattermost to 4.6.3

## 10.5.7

- No changes

## 10.5.6

- No changes

## 10.5.5

- Resolve "consul service postgresql_service failing on db host - no access to /opt/gitlab/embedded/node

## 10.5.4

- Update Let's Encrypt to use fullchain instead of certificate

## 10.5.2

- Fix regression where `redirect_http_to_https` was always on for hosts using https
- Geo: Add support to configure a custom PostgreSQL FDW external user on the tracking database

## 10.5.1

- Fix regression where using new Hash format for git_data_dirs broke reconfigure 542aea4aa

## 10.5.0

- Add support to configure the `fdw` parameter in database_geo.yml
- Extends rspec to `gitlab-ctl consul`'s helper class, and refactors to avoid
  namespace conflicts.
- Geo: Use a background WAL receiver and replication slot to improve initial sync
- Support Redis as an LRU cache
- Remove usage of gitlab_shell['git_data_directories'] configuration 2003bc5d
- Set PostgreSQL archive_timeout to 0 by default
- Added LDAP configuration option for lowercase_usernames
- Support authorized_keys database lookups with SELinux on CentOS 7.4
- Add support for generating Let's Encrypt certificates as part of reconfigure
- Support configuration of Redis Sentinels by persistence class
- Add support for setting environment variables for Registry (Anthony Dong)
- Don't attempt to backup non-existent PostgreSQL data file in gitlab-ctl replicate-geo-database
- Add object storage support for uploads
- Do not attempt to load postgresql_extension if database in question doesn't
  exist.
- Honor the `unicorn['worker_processes']` setting for a Geo secondary node
- Upgrades Chef to 12.21.31

## 10.4.1

- Update gitlab-monitor to 2.5.0
- Add GitLab pages status page configuration

## 10.4.0

- Upgrade Ruby version to 2.3.6
- Add support for enabling FDW for GitLab Geo
- Request confirmation of Geo replication user password
- Make sure db/geo/schema.rb is writable when node is a Geo secondary
- Add warning to LoggingHelper
- Update gitlab-monitor to 2.4.0 92312d6
- Update CA certificates bundle to one from 2017.09.20 a8f56b7f

## 10.3.6

- Specify initial tag of QA image for pushing to dockerhub
- Use dash instead of spaces in cache keys and build jobs

## 10.3.1

- Make it possible to configure an external Geo tracking database
- Process reconfigure failures and print out a message
- Remove unused redis bin gitlab-shell configuration
- Bump bundled git version to 2.14.3 a2b4bedf
- Update pgbouncer recipe to better handle initial configuration
- Render gitaly-ruby memory settings
- Add a runit service to probe repository storages

## 10.3.0

- Add workhorse metrics to Prometheus
- Add sidekiq metrics to Prometheus
- Include gpgme, gnupg and their dependencies
- Add gitaly metrics to Prometheus
- Upgrade node-exporter to 0.15.2
- Upgrade postgres-exporter to 0.4.1
- Upgrade prometheus to 1.8.2
- Remove duplicated shared object files from grpc gem (Takuya Noguchi)
- Update default gitlab-shell git timeout to 3 hours ec9ed900
- Enable support for git push options in the git config (Romain Maffina) 08edd3e4
- Update Redis to 3.2.11 (Takuya Noguchi)
- Turn on postgresql SSL by default b18597e3
- Update pgbouncer and repmgr recipes to prevent errors on reconfigure
- Add a command to promote secondary node to primary for GitLab Geo
- Fixed behaviour of postgres_user provider with unspecified passwords/options 8bd2e615
- Added roles to ease HA Postgres configuration d7d0f32a

## 10.2.6

- Update Mattermost to 4.3.4

## 10.2.3

- Adjust number of unicorn workers if running a Geo secondary node

## 10.2.0

- Enable pgbouncer application_name_add_host config by default 29dab6af1
- Move configuration for failing storages to the admin panel 83ad75c0
- Upgrade curl to 7.56.1
- Update backup directory management with better support for non-root NFS
- Disable prepared statements by default
- Remove deprecated settings from gitlab.yml template: geo_primary_role, geo_secondary_role
- Add options to enable SSL with PostgreSQL
- Change the default pgbouncer settings to be suitable for larger environments
- Bump openssl to 1.0.2m (Takuya Noguchi)
- Upgrade Mattermost to 4.3.2
- Stop creating SSH keys for Geo secondaries f7147d8b
- Make postgresql replication client sslmode configurable 1e2be156
- Disable TLSv1 and SSLv3 ciphers for postgresql 7ab9004f
- Add support for multiple Redis instances f6af9a81

## 10.1.6

- Update Mattermost to 4.2.2

## 10.1.3

- No changes

## 10.1.2

- Bump embedded Git version to 2.13.6 921ba935
- Update Mattermost to 4.2.1 640c88

## 10.1.1

- No changes

## 10.1.0

- Add a gitlab-ctl command to remove master nodes from cluster b50d50478
- Restart Unicorn and Sidekiq on the Geo secondary if the tracking database is migrated 1aaed2
- Remove unused Grit configuration settings 90f403a26193fb
- Add concurrency configuration for Gitaly 402f23b28
- Enable profiler for jemalloc c40b82c4037
- Update Postgres exporter to 0.2.3 1f847e9e96
- Update Prometheus to 1.7.2 1f847e9e96
- Update Redis exporter to 0.12.2 1f847e9e96
- Increase wal_keep_segments setting from 10 to 50 for Geo primary 9b1304fe
- Disable NGINX buffering with container registry 2413adb
- Add -artifacts-server and -artifacts-server-timeout support to Omnibus 188def96b3
- Introduce `roles` configuration to allow enabling of multiple sets of services 8535073e64
- Added PostgreSQL support for effective_io_concurrency 37799aea3
- Added PostgreSQL support for max_worker_processes and max_parallel_workers_per_gather 37799aea3
- Added PostgreSQL support for log_lock_waits and deadlock_timeout 37799aea3
- Added PostgreSQL support for track_io_timing 37799aea3
- Rename Rails secret jws_private_key to openid_connect_signing_key (Markus Koller) 24d56df29b
- Render gitaly.client_path in gitlab.yml 80a9c492e
- Correct Registry permissions in Docker update-permissions script 0b624f8ed
- Upgrade PostgreSQL to 9.6.5 (Takuya Noguchi) 84a3f5c09

## 10.0.7

- Fix an issue causing symlinking against system binaries if old PostgreSQL data was present on the filesystem a712c

## 10.0.6

- Upgrade curl to 7.56.1 17ea571
- Update Mattermost to 4.2.1 640c88

## 10.0.5

- No changes

## 10.0.4

- Ensure pgbouncer doesn't fail reconfigure if database isn't ready yet b50d50478

## 10.0.3

- No changes

## 10.0.4

- Ensure pgbouncer doesn't fail reconfigure if database isn't ready yet

## 10.0.3

- No changes

## 10.0.2

- Fix an issue where enabling a GitLab Geo role would also disable all default services 11e6dbf
- Reload consul on config change instead of restarting 097cf5
- Update pg-upgrade output to be more clear when a bundled PostgreSQL is not in use 7b80458b
- Add option to configure redis snapshot frequency 400f3a54

## 10.0.1

- No changes

## 10.0.0

- Use semanage instead of chcon for setting SELinux security contexts (Elliot Wright) 45abda5f4
- Add option to override the hostname for remote syslog
- Add backup_timeout argument to geo db replication command
- Remove sensitive params from the NGINX access logs 6983fe59
- Upgrade rubygems to 2.6.13 4650cd70a
- Add option to pass EXTERNAL_URL during installation d0f30ef2
  * Saves users from manually editing gitlab.rb just to set the URL and hence
    makes installation process easier
- Remove TLSv1 from the list of accepted ssl protocols
- Moved the settings handling into the package cookbook and reduced code duplication in settings
- Move the GitLab HA roles into their own files, and switch default services to be enabled by a Default role
- Remove geo_bulk_notify_worker_cron 44def4b5
- Rework `single_quote` helper as `quote` that can handle escaping
  strings with embedded quotes fdc6a93
- Add gitlab-ctl pgb-console command
- Increase warning visibility of the deprecated git_data_dir setting
- Add omniauth sync_profile_from_provider and sync_profile_attributes configuration
- Only generate a private SSH key on Geo secondaries c2f2dcba
- Support LFS object storage options for GitLab EEP
- Upgrade ruby version to 2.3.5
- Upgrade libyaml version to 0.1.7
- Add NGINX RealIP module configuration templating for Pages and Registry
- Fix gitlab-ctl wrapper to allow '*' in arguments
- Update failover_pgbouncer script to use the pgbouncer user for the database configuration
- Update Mattermost to 4.2.0

## 9.5.5

- Add more options to repmgr.conf template
- Update pgbouncer to use one style of logging
- Set bootstrap_expect to default to 3 for consul servers
- Fix bug where pgb-notify would fail when databases.json was empty
- Restart repmgrd after nodes are registered with a cluster
- Add --node option to gitlab-ctl repmgr standby unregister
- Upgrade ruby version to 2.3.5
- Upgrade libyaml version to 0.1.7

## 9.5.4

- Changing pg_hba configuration should only reload PG c99ef6

## 9.5.3

- Fix Mattermost log location 2126c7b3

## 9.5.2

- No changes

## 9.5.1

- No changes

## 9.5.0

- Fix the NGINX configuration for GitLab Pages with Cache-Control headers 2242884e
- Bump openssl to 1.0.2l 04ae64d7
- Allow deeply nested configuration settings in gitlab.rb
- Build and configure gitaly-ruby
- Added support for PostgreSQL's "idle_in_transaction_session_timeout" setting
- UDP log shipping as part of CE
- Bump Git verison to 2.13.5
- Added Consul service in EE
- Update gitlab-elasticsearch-indexr to v0.2.1 11a2e7fd
- Add configuration options for handling repository storage failures
- Add support for `--negate` in sidekiq-cluster
- Update Mattermost to 4.1.0

## 9.4.3

- Fix LDAP SSL config: Use ca_file, not ca_cert.
- Fix Mattermost setting teammate_name_display not working.
  * Renamed mattermost['service_teammate_name_display'] to mattermost['team_teammate_name_display'] ad3a4f58

## 9.4.3

- Add Prometheus client after_fork hook to reset file backed metrics

## 9.4.2

- Update LDAP SSL config: Rename method to encryption. Add ca_cert, ssl_version and verify_certificates

## 9.4.1

- Expose new Mattermost config options that went into 4.0.1

## 9.4.0

- Add configuration options of monitoring ip whitelist and Unicorn sampler interval
- Bump NGINX version to 1.12.1 f8c349bf
- Add support in Geo replicate-geo-database command for replication slots 9fa27e9a0
- Fix gitlab-shell not able to import projects from trusted SSL certificates
- Remove software definition of expat 59c39870
- Add unicorn metrics to Prometheus
- Bump gitlab-elasticsearch-indexer version to 0.2.0 bba8edd3
- Disable RubyGems in gitlab-shell scripts for performance
- Adjust various default values for PostgreSQL based on GitLab.com
- Gitaly can no longer be disabled
- Bump omnibus-ctl version to 0.5.0
- Add GeoLogCursor EE service
- Set max_replication_slots to 1 by default for primary Geo instances
- Set TZ environment variable for Gitaly
- Automate repmgr configuration
- Render Gitaly token authentication settings
- Update Mattermost to 4.0.1
- Drop GitProbe settings from gitlab-monitor
- Move registry internal key population to gitlab-rails recipe 683bdcfb

## 9.3.8

- Upgrade Mattermost to 3.10.2 6ebf54

## 9.3.7

- No Changes

## 9.3.6

- No Changes

## 9.3.5

- Update gitlab-monitor to 1.9.0 c18672
- Fix port not being passed to pg_basebackup in replicate-geo-database script ca92eb

## 9.3.4

- No Changes

## 9.3.3

- Allow sidekiq-cluster to run without having sidekiq enabled
- Remove outdated Mattermost v2 DB upgrade code
- Fix port not being passed to pg_basebackup in replicate-geo-database script
- Switch postgresql['custom_pg_hba_entries'] from Array to Hash

## 9.3.2

- Update gitlab-monitor to 1.8.0

## 9.3.1

- Use the new "gettext:compile" task during build  59dbbd8b
- Create the postgresql user for postgresql-exporter  3fedab4f

## 9.3.0

- Ensure PostgreSQL user is created for Geo installations 4bedc5f1
- Add a --skip-backup option in Geo replicate-geo-database command 22a01a23
- Rename geo_download_dispatch worker configuration
- Rename geo_backfill worker configuration
- Upgrade Prometheus to 1.6.3
- Bump Git version to 2.13.0 b8a4bc4f
- Upgrade PostgreSQL to 9.6.3 8f144d
- Upgrade ES indexer to 0.1.0
- Changing relative URL requires a hard reset ccd76ae2
- Add omniauth sync_email_from_provider configuration
- Add libre2 to support the 're2' gem
- Add a runtime directory for unicorn metrics
- Support object storage for artifacts for GitLab EEP
- Add repmgr as an EE dependency
- Upgrade Mattermost to 3.10.0

## 9.2.8

- Update Mattermost to 3.9.2 f55f9f

## 9.2.7

- No changes

## 9.2.6

- Backport: Upgrade ES indexer to 0.1.0

## 9.2.5

- Add default values to GitLab Geo roles 77e7bdfa

## 9.2.5

- Fix gitlab-ctl replicate-geo-database when run in a Docker container

## 9.2.2

- Fix bug where cron values are not set to nil and default to a set value

## 9.2.1

- Use ln -sf to prevent sshd startup errors upon a full Docker restart ecf4fd62b

## 9.2.0

- Add a missing symlink for /opt/gitlab/init/sshd to make `gitlab-ctl stop` work in Docker 4a098168
- Allow setting `usage_ping_enabled` in `gitlab.rb`
- Update mysql client to 5.5.55
- Add a build env variable ALTERNATIVE_SOURCES f0cab0c6
- Create reconfigure log dir explicitly (Anastas Dancha) 9654cfe3
- Upgrade docker/distribution to 2.6.1 5fe36ffe
- Upgrade Prometheus to 1.6.1 d4bdd143
- Upgrade gitlab-monitor to 1.6 b245f2c1
- Add ldap_group_sync worker configuration f21c3886
- Add gitlab_shell_timeout configuration 0289f50b
- Generate license .csv file 5478b1aa
- Postgresql configuration changle will now reload Postgresql instead of restart
- Generate PO translation files 6b6c936a
- Change service running detection 18b51873
- Rename trigger schedules to pipeline schedules
- Compile new binaries for gitlab-shell
- Compile python with libedit
- Disable Nginx proxy_request_buffering for Git LFS endpoints

## 9.1.7

-  Update Mattermost to 3.7.6 ce50d5f

## 9.1.6

- No changes

## 9.1.5

- No changes

## 9.1.4

- Fix gitlab.yml template to quote sidekiq-cron 285fbb

## 9.1.3

- Update mysql client to 5.5.56. 5e673

## 9.1.2

- Add support for the following PostgreSQL settings: random_page_cost, max_locks_per_transaction, log_temp_files, log_checkpoints

## 9.1.1

- No changes

## 9.1.0

- Remove deprecated satellites configuration f88ba40b
- Add configuration file for Gitaly 7c7c728
- Add support for Gitaly address per shard 2096928
- Build Container Registry with include_gcs flags (Lars Larsson) deb707fd
- Update Prometheus flags, tweak resource usage b2dcb8da
- EE: Create and migrate GitLab Geo database and configure Geo replication b71f72
- EE: Add set-geo-primary-node command ecbcf2
- EE: Add hot-standby configuration for Geo DB 82158
- EE: Change the order of configuration loading for EE recipes ba19b7c0
- Add support storages in Gitaly config f3205fa
- Update Node exporter to 0.14.0 84f71c0
- Update Redis exporter to 0.10.9.1 84f71c0

## 9.0.6

- No changes

## 9.0.5

- Build SLES 12 EE package at the same time as others.
- Fix AWS build errors
- Updating documentation for external PostgreSQL usage
- Added quotes to GITLAB_SKIP_PG_UPGRADE

## 9.0.4

- Update Mattermost version to 3.7.3 b8abd225

## 9.0.3

- Added support for managing PostgreSQL's hot_standby_feedback option 8971a5e0
- Add configuration support for new Mattermost 3.7 settings (Robin Naundorf) 3c9d6936
- Fix 'template1 being accessed by other users' error c8633b8b
- Fix ability to disable postgres and redis exporters 04eaf7f6
- Start new services after they are enabled  42c9af27

## 9.0.2

- No changes

## 9.0.1

- Allow configuration of prepared statement caching in Rails 169891c2
- Default redis promethues exporter to off if redis is not managed locally 63056441
- Default postgres promethues exporter to off if postgres is not managed locally 63056441
- Default pages http to https redirect to off 1ece2480
- Make HSTS easier to configure, and the docs on it accurate 4ba90ff8
- Move the automatic PG Upgrade to happen after migrations have run 8cf38d43

## 9.0

- Remove Bitbucket from templates as it does not require special settings anymore b87ae1f
- Fix the issue that prevents registry from starting when user and group
are not the same (O Schwede) c4e83c5
- Add configuration options for GitLab container registry to support notification endpoints to template (Alexandre Gomes) ef9b0f255
- Update curl to 7.53.0 38aea7179
- Update directory configuration structure to allow multiple settings per data directory
- Remove mailroom configuration template, reuse the default from GitLab 5511b246
- Remove deprecated standalone GitLab CI configuration ad126ba
- Expose configuration for HSTS which was removed from GitLab Rails f5919f
- Expose KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT to Prometheus for k8s 8a4e7d
- Disable Nginx caching except for assets 6c1cdd8
- Update Prometheus to 1.5.2 0edcf58
- Update GitLab Monitor to 1.2.0 0edcf58
- Update Postgres-exporter to 0.1.2 0edcf58
- Update Redis-exporter to 0.10.7 0edcf58
- Expose apiCiLongPollingDuration for GitLab Workhorse f88ae849
- Add storage class configuration option for S3 backups (Jon Keys) 1e4a6ac4
- Generate RSA private key for doorkeeper-openid_connect (Markus Koller) a447c41
- Change default syntax for git_data_dirs ee831d9
- Remove deprecated git-annex configuration 527b942
- Expose GitLab Workhorse configuration file 835144e
- Add option to verify clients with an SSL certificate to Mattermost, Registry and GitLab Pages
- Rename stuck_ci_builds_worker to stuck_ci_jobs_worker in the gitlab_rails config
- EE: Add a tracking database for GitLab Geo f1077d10
- Provide default Host header for requests that do not have one 14f77c
- Gitaly service on by default 350dea
- Update Nginx to 1.10.3 211a89fb6

## 8.17.5

- Update Mattermost version to 3.6.5 bb826eeb

## 8.17.4

- No changes

## 8.17.3

- Changing call to create tmp dir as the database user 7b54cd76

## 8.17.0

- Add support for setting PostgreSQL's synchronous_commit and
  synchronous_standby_names settings
- Remove deprecated Elasticsearch configuration options ab660c56
- Include GitLab Pages in the Community Edition
- Add HealthCheck support to our Docker image 845b52b2
- Remove Nodejs dependency 7d22e0a8
- Add an option to skip cache:clear task (Adam Hamsik) e4ba9913
- Update Mattermost OAuth2 endpoints when GitLab's url changes
- Include Redis exporter, off by default 3bd03d2d
- Include Postgres exporter, off by default e8755757
- Fixed trusted certificates being lost during Docker image restarts
- Make pam_loginuid.so optional for SSH in our Docker image (Martin von Gagern) eb73ecea
- Introduce gitlab-ctl diff-config command to compare existing and new configuration bb0bd
- Remove update_all_mirrors_worker_cron and update_all_remote_mirrors_worker_cron settings 49706b
- Expose max_standby_archive_delay and max_standby_streaming_delay Postgresql settings
- Disconnect and reconnect database connections when forking in Unicorn a7b35aaf
- Add support for the PostgreSQL max_replication_slots setting
- Allow exposing prometheus metrics on gitlab-pages

## 8.16.9

- Update Mattermost version to 3.6.5 e5f65b8

## 8.16.8

- No changes

## 8.16.7

- No changes

## 8.16.6

- EE: Make sure `ssh_keygen` creates the directory first e5483177

## 8.16.5

- Upgrade Mattermost to 3.6.2 2c7dab9f
- EE: Make sure `ssh_keygen` creates the directory first e5483177

## 8.16.4

- Make pam_loginuid.so optional for SSH in our Docker image (Martin von Gagern) eb73ecea

## 8.16.3

- Pin bundler to version 1.13.7 0ec1b67f
- Upgrade zlib to 1.2.11 cfa4e3c0

## 8.16.2

- No changes

## 8.16.1

- No changes

## 8.16.0

- Update git to 2.10.2 27cde301
- Allow users to specify an initial shared runner registration token 11de915b
- Update Mattermost to version 3.6  4fcdc632
- Include Prometheus and Node Exporter, off by default  bef79732
- Let users expose Mattermost host if installed on other server  2aec8f66
- Make gitlab.rb template file scraping friendly 92e5eedf

## 8.15.7
- Update Mattermost to 3.5.3 to patch a security vulnerability

## 8.15.6
- Pin bundler version to 1.13.7 to avoid breaking changes
- Update Mattermost to 3.5.2 to patch a XSS vulnerability

## 8.15.5

- No changes

## 8.15.4

- No changes

## 8.15.3

- No changes

## 8.15.2

- No changes

## 8.15.1

- No changes

## 8.15.0

- Update git to 2.8.4 381c0b9d
- Clean up apt lists to reduce the Docker image size (Tao Wang) 7e796c5f
- Enable Mattermost slash commands by default 2b3406
- Enable overriding of username and profile picture for webhook on Mattermost by default 8528864
- Fix Mattermost authorization with Gitlab (Tyranron) d704d3
- Expose Mattermost url in gitlab.yml 4d90c7fa
- Add prometheusListenAddr config setting for gitlab-workhorse 12bb9df2
- Fix Mattermost service file not respecting `mattermost['home']` option ca96b4e
- Bump ruby version to 2.3.3 9f5fe2c2
- Add configuration that allows overriding proxy headers for GitLab Pages NGINX (BruXy) c2722f1e
- Make hideRefs option of git default in omnibus installations e7484a9b
- Use internal GitLab mirrors of rb-readline and registry as cache 2d137543
- Adding attribute for gitlab-shell custom hooks f753e1f0
- Pass websockets through to workhorse for terminal support 849ffc
- Add notification for new PostgreSQL version 05dbb3ec
- Update libcurl to 7.52.0 ea11a83
- Add EE sidekiq_cluster configurable for setting up extra Sidekiq processes

## 8.14.10
- Update Mattermost to 3.5.3 to patch a security vulnerability

## 8.14.9
- Pin bundler version to 1.13.7 to avoid breaking changes

## 8.14.8
- Update Mattermost to 3.5.2 to patch a XSS vulnerability

## 8.14.7

- No changes

## 8.14.6

- No changes

## 8.14.5

- Expose client_output_buffer_limit redis settings 5f1503

## 8.14.4

- Fix gitlab-ctl pg-upgrade to properly handle database encodings 46e71561
- Update symlinks of postgres on both upgrade and reconfigure 484a3d8a

## 8.14.3

- Patch Git 2.7.4 for security vulnerabilities 568753c3

## 8.14.2

- Revert 34e28112 so we don't listen on IPv6 by default

## 8.14.1

- No changes

## 8.14.0

- Switch the redis user's shell to /bin/false 9d60ee4
- NGINX listen on IPv6 by default (George Gooden) 34e28112
- Upgrade Nginx to 1.10.2 085bf610
- Update Redis to 3.2.5 (Takuya Noguchi) edf0575c1
- Updarted cacerts.pem to 2016-11-02 version aca2f5e88
- Stopped using PCRE in the storage directory helper 0e06490
- Add git-trace logging for gitlab-shell 1dab1c
- Update mattermost to 3.5 7ecf31
- Add support for OpenSUSE 13.2 and 42.1 82b7345 6ea9e2
- Support Redis Sentinel daemon (EE only) 457c4764
- Separate package repositories for OL and SL e37eaae
- Add mailroom idle timeout configuration 0488f3de

## 8.13.12

- No changes

## 8.13.11

- No changes

## 8.13.10

- No changes

## 8.13.9

- No changes

## 8.13.8

- Patch Git 2.7.4 for security vulnerabilities 2d7cf04a

## 8.13.7

- No changes

## 8.13.6

- No changes

## 8.13.5

- No changes

## 8.13.4

- Update curl to 7.51.0 to get the latest security patches fc32c83
- Fix executable file mode for the Docker image update-permissions command 6c80205

## 8.13.2

- Move mail_room queue from incoming_email to email_receiver 373609c

## 8.13.1

- Update docs for nginx status, fix the default server for status config b49fb1

## 8.13.0

- Add support for registry debug addr configuration 87b7a780
- Add support for configuring workhorse's api limiting 1b6c85d4
- Fix unsetting the sticky bit for storage directory permissions and improved error messages 7467b51
- Fixed a bug with disabling registry storage deletion be305d40
- Support specifying a post reconfigure script to run in the docker container aa8bec5
- Add support for nginx status (Luis Sagastume) 3cd7b36
- Enable jemalloc by default 0a7799d2
- Move database migration log to a persisted location b368c46c

## 8.12.13

- No changes

## 8.12.12

- No changes

## 8.12.11

- Patch Git 2.7.4 for security vulnerabilities 564cfddf

## 8.12.10

- No changes

## 8.12.9

- No changes

## 8.12.8

- No changes

## 8.12.7

- Use forked gitlab-markup gem (forked from github-markup) 422d9bf20

## 8.12.6

- No changes

## 8.12.5

- Update the storage directory helper to check permissions for symlink targets

## 8.12.4

- No changes

## 8.12.3

- Updated cacerts.pem to 2016-09-14 version 9bc1fec

## 8.12.2

- Update openssl to 1.0.2j 527d02

## 8.12.1

- Fix gitlab-workhorse Runit template bug e20e5ff

## ## 8.12.0

- Add support for using NFS root_squash for storage directories d5cf0d1d
- Update mattermost to 3.4 6857c902
- Add `gitlab-ctl deploy-page status` command b8ffd251
- Set read permissions on the trusted certificates in case they are restricted
- Fix permissions for nginx proxy_cache directory (Charles Blaxland) 4eb85976
- Render gitlab-workhorse token c50c85
- Enable git packfile bitmap creation 2a07f08
- Localise all custom sources in .custom_sources.yml 5bcbd4f
- Update the mode of the certificate files when using trusted certificates b00cd4
- Allow configuring Rack Attack endpoints (Dmitry Ivanov) 7aee63
- Bundle jemalloc and allow optional enable 1381ba
- Use single db_host when multi postgresql::listen_adresses (Julien Garcia Gonzalez) 717dc269
- Add gitlab-ctl registry-garbage-collect command  5f5526d3
- Update curl to version 7.50.3 7848b550
- Add default HOME variable to workhorse fcfa3672
- Show GitLab ascii art after installation (Luis Sagastume) 17ed6cb

## 8.11.11

- No changes

## 8.11.10

- No changes

## 8.11.9

- No changes

## 8.11.8

- No changes

## 8.11.7

- No changes

## 8.11.6

- Fix registry build by enabling vendor feature

## 8.11.5

- No changes

## 8.11.4

- Fix missing Logrotate directory 453ea
- Expose shared_preload_libraries Postresql settings f0557
- Expose log_line_prefix Postresql settings cae662

## 8.11.3

- Patch docutils to work with Python3 to restore .RST rendering 70ee88c2

## 8.11.2

- Fixed a regression where the default container registry and mattermost nginx proxy headers were not being set

## 8.11.1

- Unreleased

## 8.11.0

- Add configuration that allows overriding proxy headers for Mattermost NGINX config (Cody Mize) 4985ca
- Upgrade krb5 lib to 1.14.2 3670e5
- Set ICU_DATA to the right path to make Charlock Holmes and libicu work properly 60e8061d
- Upgrade chef-zero to 4.8.0 e390cd
- Create logrotate folders and configs even when the service is disabled (Gennady Trafimenkov) eae7c9
- Added nginx options to enable 2-way SSL client authentication (Oliver Hernandez) c51085
- Upgrade libicu to 57.1 f58a4b15
- Upgrade Nginx to 1.10.1 67a0bd0
- Allow configuration of the authorized_keys file location used by gitlab-shell
- Upgrade omnibus to 5.4.0 7bac2
- Add configuration that allows disabling of db migrations (Jason Plum) a50d09
- Initial support for Redis Sentinel 267ace
- Do not manage authorized keys anymore 7dc1d6
- Upgrade to Chef 12.12.15 c930fbd4
- Tidy up key names for secrets to match GitLab Rails app
- Update rsync to 3.1.2 8cc078
- Upgrade ruby to 2.3.1 58a13
- Change config_guess to a private mirror 1b197
- Remove Redis dump.rdb on downgrades for furuture packages (Gustavo Lopez) 824530
- Update postgresql to 9.2.18 (Takuya Noguchi)
- Update expat to 2.2.0 (Takuya Noguchi)
- Ignore and don't write `gitlab_ci:gitlab_server` key in gitlab-secrets file 10bcb

## 8.10.10

- No changes

## 8.10.9

- Fix registry build by enabling vendor feature

## 8.10.8

- No changes

## 8.10.7

- No changes

## 8.10.6

- No changes

## 8.10.5

- Pin mixlib-log to version 1.6.0 in order to keep the log open for writes during reconfigure 7345d

## 8.10.4

- Revert Host and X-Forwarded-Host headers in NGINX 9ac08
- Better handle the ssl certs whitelisted files when the directory has been symlinked 97493919d
- Fix issue where mattermost log file is created by the root user 581fa

## 8.10.3

- No changes

## 8.10.2

- Exclude standard ports from Host header

## 8.10.1

- Fix custom HTTP/HTTPS external ports ddcf302f

## 8.10.0

- Fix RangeError bignum too big errors on armhf platforms 4ba24bfe
- Update redis to 3.2.1 (Takuya Noguchi) 144bf
- Updated Chef version to 12.10.24 6e0c66
- Disable nodejs Snapshot feature on ARM platforms f9a7b4bf
- Update the trusted certs recipe to copy in certs that were linked in from external folders
- Use gitlab:db:configure to seed and migrate the database 047cfd
- Update Mattermost to 3.2 28cf3
- Lower expiry date of registry internal certificate b269b4
- Add personal access token to rack attack whitelist 21abc

## 8.9.10

- No changes

## 8.9.9

- Fix registry build by enabling vendor feature

## 8.9.8

- No changes

## 8.9.7

- No changes

## 8.9.6

- Bump chef-zero to 4.7.1 to squelch debug messages 9eefa12f

## 8.9.5

- No changes

## 8.9.4

- Bump chef-zero to 4.7.0 to retain Ruby 2.1 compatibility 8495179

## 8.9.3

- IMPORTANT: Location of the trusted certificate directory has changed e2e7b

## 8.9.2

- Restart unicorn for the adjusted trusted certs if unicorn is running 3748d9
- Change the default imap timeout to 60 03684d

## 8.9.1

- Prevent running CREATE EXTENSION in a slave server 7821bbaa
- Skip choosing an init system recipe when running in a container e229a968

## 8.9.0

- Make default IMAP incoming mailbox "inbox" in case user omits this setting d3c187
- Make NGINX server_names_hash_bucket_size configurable and default it to 64 bytes 7cb488
- Use gitlab:db:configure to seed and migrate the database
- Add log prefix for pages and registry services 48e29b
- Add configuration option for the Container Registry storage driver
- Change the autovacuum configuration defaults f5ac85
- Update redis to 3.2.0 (Takuya Noguchi) 357263
- Add configuration that allows overriding proxy headers for Registry NGINX config (Alexander Zigelski) 046c84c
- Update version of pcre ac72670
- Update version of expat ac72670
- Update postgresql to 9.2.17 (Takuya Noguchi) 6e0c0f
- Make one unicorn new default 0ddd2
- Trim Docker image size 2aedc2
- Expose track_activity_query_size setting for Postgresql 5ebd7c
- Expose maxclients setting for Redis 535540c
- Add expire_build_artifacts_worker cron config 3603b
- Upgrade Mattermost to 3.1 d446f0
- Add expire_build_artifacts_worker cron config 3603b7
- Allow adding custom trusted certificates (Robert Habermann) 48e891
- Increase the Unicorn memory limits to 400-650MB 8f688
- Add configuration for Registry storage config 545856

## 8.8.9

- No changes

## 8.8.8

- No changes

## 8.8.7

- No changes

## 8.8.6

- Update version of pcre
- Update version of expat

## 8.8.5

- No changes

## 8.8.4

- No changes

## 8.8.3

- Add gitlab_default_projects_features_container_registry variable

## 8.8.2

- Update docker/distribution to 2.4.1 1c01c9c
- Update libxml2 to 2.9.4 a3f7d6
- Add Postgresql autovacuuming configuration 289c25

## 8.8.1

- No changes

## 8.8.0

- Disable Rack Attack throttling if specified in config 631511f8
- Update postgresql to 9.2.16 (CVE-2016-2193/CVE-2016-3065) (Takuya Noguchi) d02125
- Check mountpoint before starting up pages daemon a53e7a0
- Add support for Container Registry f74472d
- Add maintenance_work_mem and wal_buffers Postgresql settings 5675dc

## 8.7.9

- No changes

## 8.7.8

- Update version of pcre
- Update version of expat

## 8.7.7

- No changes

## 8.7.3

- Update openssl to 1.0.2h

## 8.7.2

- No changes

## 8.7.1

- Package supports Ubuntu 16.04 8a4ce1f5
- Pin versions of ohai and chef-zero to prevent reconfigure outputting too much info f9b2307c

## 8.7.0

- Added db_sslca to the configuration options for connecting to an external database 2b4033cb
- Compile NGINX with the real_ip module and add configuration options b4830b90
- Added trusted_proxies configuration option for non-bundled web-server 3f137f1c
- Support the ability to change mattermost UID and GID c5a588da
- Updated libicu to 56.1 4de944d9
- Updated liblzma to 5.2.2 4de944d9
- Change the way db:migrate is triggered 3b42520a
- Allow Omniauth providers to be marked as external 7dd68edf
- Enable Git LFS by default (Ben Bodenmiller) 22345799
- Updated how we detect when to update the :latest and :rc docker build tags cb3af445
- Disable automatic git gc 8ed13f4b
- Restart GitLab pages daemon on version change 922f7655
- Add git-annex to the docker image c1fdc4ff
- Update Nginx to 1.9.12 96ca0916
- Update Mattermost to v2.2.0 fd740e17
- Update cacerts to 2016.04.20  edefbe2e
- Add configuration for geo_bulk_notify_worker_cron 219125bf
- Add configuration repository_archive_cache_worker_cron 8240ab3a
- Update the docker update-permissions script 13343b4f
- Add SMTP ssl configuration option (wu0407) 4a377fc2
- Build curl dependency without libssh2 17e41f8

## 8.6.9

- Build curl dependency without libssh2 17e41f8

## 8.6.8

- Update Mattermost download URL from GitHub to releases.mattermost.com

## 8.6.7

- No changes

## 8.6.6

- No changes

## 8.6.5

- No changes

## 8.6.4

- No changes

## 8.6.3

- No changes

## 8.6.2

- Updated chef version to 12.6.0 37bf798
- Use `:before` from Chef 12.6 to enable extension before migration or database seed fd6c88e0

## 8.6.1

- Fix artifacts path key in gitlab.yml.erb c29c1a5d

## 8.6.0

- Update redis version to 2.8.24 2773274
- Pass listen_network of gitlab_workhorse to gitlab nginx template 51b20e2
- Enable NGINX proxy caching 8b91c071
- Restart unicorn when bundled ruby is updated aca3cb2
- Add ability to use dateformat for logrotate configuration (Steve Norman) 6667865d
- Added configuration option that allows disabling http2 protocol bcaa9e9
- Enable pg_trgm extension for packaged Postgres f88fe25
- Update postgresql to 9.2.15 to address CVE-2016-0773 (Takuya Noguchi) 16bf321
- If gitlab rails is disabled, reconfigure needs to run without errors 5e695aac
- Update mattermost to v2.1.0 f555c232
- No static content delivery via nginx anymore as we have workhorse (Artem Sidorenko) 89b72505
- Add configuration option to disable management of storage directories 81a370d3

## 8.5.13

- Build curl dependency without libssh2 17e41f8

## 8.5.12

- No changes

## 8.5.11

- Update Mattermost download URL from GitHub to releases.mattermost.com

## 8.5.10

- No changes

## 8.5.9

- No changes

## 8.5.8

- Bump Git version to 2.7.4

## 8.5.7

- Bump Git version to 2.7.3

## 8.5.6

- No changes

## 8.5.5

- Add ldap_sync_time global configuration as the EE is still supporting it 3a58bfd

## 8.5.4

- No changes

## 8.5.3

- No changes

## 8.5.2

- Fix regression where NGINX config for standalone ci was not created d3352a78b4c3653d922e415de5c9dece1d8e10f8
- Update openssl to 1.0.2g 0e44b8e91033f3e1662c8ea92641f1a653b5b871

## 8.5.1

- Push Raspbian repository for RPI2 to packagecloud 57acdde0465ed9213726d84e2b92545344449002
- Update GitLab pages daemon to v0.2.0 326add9babb605d4116da22dcfa30ed1aa12271f
- Unset env variables that could interfere with gitlab-rake and gitlab-rails commands e72a6f0e256dc6cc415248ce6bc63a5580bb22f6

## 8.5.0

- Add experimental support for relative url installations (Artem Sidorenko) c3639dc311f2f70ec09dcd579a09443189266864
- Restart mailroom service when a config changes f77dcfe9949ba6a425c448aff34fdb9cbe289164
- Remove gitlab-ci standalone from the build, not all gitlab-ci code de6419c850d0302a230b172c06d9e542845bc5b7
- Switch openssl to 1.0.2f a53d77674f32de055e7f6b4128e25ff7c801a284
- Update nginx to 1.9.10 8201623411c028202392d7f90056e1494812ced0
- Use http2 module 8201623411c028202392d7f90056e1494812ced0
- Update omnibus to include -O2 compiler flag e9acc03ca296f9146fd5824e8818861c7b584a63
- Add configuration options to override default proxy headers 3807ed87ec887ca60343a5dc09fc99af746e1535
- Change permissions of public/uploads directory to be more restrictive 7e4aa2f5e60cbb8a5f6c6475514a73be813b74fe
- Update mattermost to v2.0.0 8caacf73e23c930bab286b0affbf1a3c0bd93361
- Add support for gitlab-pages daemon 0bbaba4d698306f5a2640cdf915129f5e6dd6d80
- Added configuration options for new allow_single_sign_on behavior and auto_link_saml_user 96ba41274864857f494e220a684e9e34954c85d1

## 8.4.11

- Build curl dependency without libssh2 17e41f8

## 8.4.10

- No changes

## 8.4.9

- Update Mattermost download URL from GitHub to releases.mattermost.com

## 8.4.8

- No changes

## 8.4.7

- No changes

## 8.4.6

- No changes

## 8.4.5

- No changes

## 8.4.4

- Allow webserver user to access the gitlab pages e0cbafafad88d2478514c1485f69fc41cc076a85

## 8.4.3

- Update openssl to 1.0.1r 541a0ed432bfa6a5eac58be7aeb70b15b1b6ea43

## 8.4.2

- Update gitlab-workhorse to 0.6.2 32b3a74179e28c1572608cc62c1484caf907cb9c

## 8.4.1

- No changes

## 8.4.0

- Add support for ecdsa and ed25519 keys to Docker image (Matthew Monaco) 3bfcb2617d240937fdb77d38900ee00f1ffbce02
- Pull the latest base image before building the GitLab Docker image (Ben Sjoberg) c9926773d708b7e94cd70b190e213ae322dbee17
- Remove runit files when service is disabled 8c4c446c2ba42cf8a76d9a61882ac0605f678532
- Add GITLAB_OMNIBUS_CONFIG to Docker image bfe5cb8187b0c05778fe401c2a6bbbd31b1efe2e
- Compile all .py files during packaging b131e0fc0562c416fd62d84f43a6b3e3a03baa23
- Correctly update md5sums for deb packager b131e0fc0562c416fd62d84f43a6b3e3a03baa23
- Fix syntax for md5sums file b131e0fc0562c416fd62d84f43a6b3e3a03baa23
- Update git to use symlinks for alias commands 65df6a4dcfc89557ec8413e8e967242f4db96dba
- Remove libgit definition and rely on it being built by rugged fe38fa17db9e855f2a844a1b68a4aaf2ac169184
- Update ruby to 2.1.8 6f1d4204ca24f67bbf453c7d751ba7977c23f55e
- Update git to 2.6.2 6f1d4204ca24f67bbf453c7d751ba7977c23f55e
- Ensure that cache clear is run after db:migrate b4dfb1f7b493ae5ef5fabda5c04e2dee6f4b849e
- Add support for Elasticsearch config (EE only) 04961dd0667c7eb5946836ffae6a5d6f6c3d66e0
- Update cacerts to 2016.01.20 8ddedf2effd8944bd79b46682ce48a1c8f635c76
- Change the way version is specified for gitlab-rails, gitlab-shell and gitlab-workhorse a8676c647aca93c428335d35350f00bf757ee42a
- Update Mattermost to v1.4.0 82149cf5fa9d556be558b69867c0859ea15e1a64
- Add config for specifying environmental variables for gitlab-workhorse 79b807649d54384ddf93b214b2a23d7a2180b48e
- Increase default Unicorn memory limits to 300-350 814ee578bbfe1f9eb2a83a9c728cd56565e89cb8
- Forward git-annex config to gitlab.yml 796a0d9875b2c7d889878a2db29bb4689cd64b64
- Prevent mailroom from going into restart loop 378f2355c5e9728c43baf14595bf9362c03b8b4c
- Add gitlab-workhorse config for proxy_headers_timeout d3de62c54b5efe1d5f60c2dccef65e786b631c3b
- Bundle unzip which is required for EE features 56e1fc0b11cd2fb5458fa8a9585d3a1f4faa8d6f

## 8.3.10

- Build curl dependency without libssh2 17e41f8

## 8.3.9

- No changes

## 8.3.8

- Update Mattermost download URL from GitHub to releases.mattermost.com

## 8.3.7

- No changes

## 8.3.6

- No changes

## 8.3.5

- No changes

## 8.3.4

- Update gitlab-workhorse to 0.5.4 7968c80843ac7deaaebe313c6976615a2268ac03

## 8.3.3

- Update gitlab-workhorse to 0.5.3 6fbe783cfd677ea16fcfe1e1090887e5ee0a0028

## 8.3.2

- No changes

## 8.3.1

- Increase default worker memory from 250MB to 300MB.
- Update GitLab workhorse to 0.5.1 cd01ed859e6ace690a4f57a8c16d56a8fd1b7b47
- Update rubygemst to 2.5.1 58fcbbdb31a3e6ea478e223c659634e60d82e191
- Update libgit2 to 0.23.4 and let rugged be compiled during bundle install fb54c1f0f2dc4f122d814de408f4d751f7cc8ed5

## 8.3.0

- Add sidekiq concurrency setting 787aa2ffc3b50783ae17e32d69e4b8efae8ca9ac
- Explicitly create directory that holds the logs 50caed92198aef685c8e7815a67bcb13d9ebf911
- Updated omnibus to v5.0.0 18835f14453fd4fb834d228caf1bc1b37f1fe910
- Change mailer to mailers sidekiq queue d4d52734072382159b0c4249fe76c104c1c3f9cd
- Update openssl to 1.0.1q f99fd257a6aa541662095fb72ce8af802c59c3a0
- Added support for GitLab Pages aef69fe5fccbd14c9c0112bae58d5ecaa6e680bd
- Updated Mattermost to v1.3.0 53d8606cf3642949ced4d6e8432d4b45b0541c88

## 8.2.6

- Build curl dependency without libssh2 17e41f8

## 8.2.5

- cacerts to 2016.04.20
- Change URL for Mattermost to releases.mattermost.com

## 8.2.4

- Cacerts 20.01.2016.
- Upgrade rubygems to 2.5.1.

## 8.2.3

- Add gitlab_default_projects_features_builds variable (Patrice Bouillet) e13556d33772c2d6b084d358ff67ea7da2c78a91

## 8.2.2

- Set client_max_body_size back to all required blocks 40047e09192686a739e2b7e52133885d192dab7c
- Specific replication entry in pg_hba.conf for Postgresql replication 7e32b1f96aaebe810d320ade965244fc2352314e

## 8.2.1

- Expose artifacs configuration options 4aca77a5ae78a836cc9f3be060afacc3c4e72a28
- Display deploy page on all pages b362ee7d70851c291ff0d090fd75ef550c5c5baa

## 8.2.0

- Skip builds directory backup in preinstall 1bfbf440866e0834f133e305f7659df1ee1c9e8a
- GitLab Mattermost version 1.2.1, few default settings changed 34a3a366eb9b6e5deb8117bcf4430659c0fb7ecc
- Refactor mailroom into a separate service 959c1b3f437d49eb1a173dea5d6d5ca3d79cd098
- Update nginx config for artifacts and lfs 4e365f159e3c70aa1aa3a578bb7440e27fcdc179
- Added lfs config settings 4e365f159e3c70aa1aa3a578bb7440e27fcdc179
- Rename gitlab-git-http-server to gitlab-workhorse 47afb19142fcb68d5c35645a1efa637f367e6f84
- Updated chef version to 12.5.1 (Jayesh Mistry) 814263c9ecdd3e6a95148dfdb15867468ef43c7e
- gitlab-workhorse version 0.4.2 3b66c9be19e5718d3e92df3a32df4edaea0d85c2
- Fix docker image pushing when package is RC 99bad0cf400460ade2b2360a1e4e19605539a6c9

## 8.1.3

- Update cacerts to 2015.10.28 e349060c81b75f9543ececec14f5c9c721c91d50

## 8.1.2

- Load the sysctl config as soon as it is set a9f5ece8e7f08a23ceb792e919c941d01d3e14b7
- Added postgresql replication settings f1949604de8017355c26710205156a0147ffa793

## 8.1.1

- Fix missing email feedback address for Mattermost (Pete Deffendol) 4121e5853a00ed882a6eb97a40fc274f05d3b68c
- Fix reply by email support in the package 49cc150360028d62d8d64c6416fad78d474a5933
- Add mailroom to the log 01e26d3412a4e2fac7411874bc81a20a27123921
- Fix sysctl param loading da0c487ff8518f0989052a53d397a7cb669acb35

## 8.1.0

- Restart gitlab-git-http-server on version change
- Moved docker build to omnibus-gitlab repository 9757575747c9d78e355ecd76b11dd7b9dc4d94b5
- Using sv to check for service status e7b00e4a5d8f0195d9a3f59a6d398a6d0dba3773
- Set kernel.sem for postgres connections dff749b36a929f9a7dfc128b60f3d53cf2464ed8
- Use ruby 2.1.7 6fb46c4db9e5daf8a724f5c389b56ea8d918b36e
- Add backup encription option for AWS backups 8562644f3dfe44b6faed35f8e0769a0b7c202569
- Update git to 2.6.1 b379c1060a6af314209b86161ea44c8467c5a49f
- Update gitlab-git-http-server to 0.3.0 737815fd22a71f1b94379a1a11d8b82367cc7b3a
- Move incoming email settings to gitlab.yml 9d8673e221ad869199d633c7feccab167a64df6d
- Add config to enable slow query logging e3c4013d4c01ec372962b1310f17af5ded963ea4
- GitLab Mattermost to 1.1.1 38ef5d7b609c190502d48374cc2b88cbe0caa307
- Do not try to stop ci services if they are already disabled 635d7952fad2d501a8f1a38a9e977c4297ce2e52

## 8.0.4

- Fix accidental removal of creating backup directory cb7afb0dff528b8e7f3e8c54801e3635576e33a7
- Create secrets and database templates for gitlab-ci for users upgrading from versions prior to 7.14 b9df5e8ce58b818c3b0650ab4d99c883bead3991
- Change the ownership of gitlab-shell/hooks directory a6fe61e7e1f54c1eadce78072ba902388db5453f

## 8.0.3

- Update gitlab-git-http-server to 0.2.10 76ea52321be798329e5ece9f4b935bb1f2b579ad
- Switch to chef-gem 6b15effce70a41c0041e0bca8b80d72c02be1fcf

## 8.0.2

- If using external mysql for mattermost don't run postgres code d847479b8bcb523110aae9230bcf480def3eab15
- Add incoming_email_start_tls config ec02a9076f1c59dbd9a85cbfd8b164f56a8c4da7

## 8.0.1

- Revert "Do not buffer with nginx git http requests"

## 8.0.0

- gitlab-git-http-server 0.2.9 is enabled by default e6fa1b77c9501da6b6ef44c92e2705b1e94166ea
- Added reply by email configuration 3181425e05bd7be76832957367a24df771bdc84c
- Add to host to ssh config for git user for bitbucket importer 3b0f7ebefcb9221b4ed97f234f9e728e3faf0b7d
- Add ability to configure the format of nginx logs 03511afa1d3440459b327bd873550c3cc6a6a44e
- Add option to configure db driver for Mattermost f8f00ff20304753b3eeef5d004930c4a8c404e1c
- Remove local_mode_cache_warning warnings durning reconfigure run 6cd30475cde59803f2d6f9ff8e00bde520512113
- Update chef server version to 12.4.1 435183d75f4d2c8333923e95fc6254c52901295f
- Enable spdy support when using ssl (Manuel Gutierrez) caafd1d9cf86ccecfc1f7ecddd3fd005727beddd
- Explicitly set scheme for X-Forwarded-Proto (Stan Hu) 19d71ac3cbd086f25a2e4ce284ea341d96b7ec46
- Add option to set ssl_client_certificate path (Brayden Lopez) fc0f7e9344a80ff882f4247049668ac1636e4229
- Add new Kerberos configuration settings for EE 40fc4a8687e649b0b662014dfa61442aaf4bd437
- Add proxy_read_timeout and proxy_connect_timeout config (Alexey Zalesnyi) 286695fd91bef6d784e21e80bf20d406440176b4
- Add option to disable accounts management through omnibus-gitlab b7f5f2bea422f190dd260eb555cbf4c6c7e1b351
- Change the way sysctl configuration is being invoked 5481024558c4881d7c30942419358e12a0340673
- Fix redirect ports in nginx templates 54e342cd8dc6315bcabafc4efb81be108c78b5ee
- Do not buffer with nginx git http requests 99ea9025a48427f1cbfeafe3a577c88d7dd7817d

## 7.14.3

- Add redis password option when using TCP auth d847479b8bcb523110aae9230bcf480def3eab15

## 7.14.2

- Update gitlab-git-http-server to version 0.2.9 82a3bec2eb3f006bb9327a59608f99cae81d5c92
- Ignore unknown values from gitlab-secrets.json (Stan Hu) ef76c81d7b71f72d6438e3458d61ecaef8965e17
- Update cacerts to 2015.09.02 6bb15558b681035e0db75e41f5a14cc878344c9d

## 7.14.1

- Update gitlab-git-http-server to version 0.2.8 505de5318f8e464f88e7a57e65d76387ef86cfe5
- Fix automatic SSO authorization between GitLab and Mattermost (Hiroyuki Sato) 1e7453bb71b92ba0fb095fc9ebab25015451b6bc

## 7.14.0

- Add gitlab-git-http-server (disabled by default) 009aa7d2e68bc84717fd363c88e655ee510aa8e5
- Resolved intermittent issues in gitlab-ctl reconfigure 83ce5ac3fe50acf3da1da572cd8b88016039f1a0
- Added backup_archive_permissions configuration option fdf9a793d533c0b3ca19295746ba6cba33b1af7a
- Refactor gitlab-ctl stop for unicorn and logrotate b692b824454681c6a204f627b9be72d6fcf7838d
- Include GitLab Mattermost in the package 7a6f6012b8c3a8e187bd6213278e5b37d533d228

## 7.13.2

- Move config.ru out of etc directory to prevent passenger problems 5ee0ac221485ce0e385f4999838f319ba65755ed
- Fix merge gone wrong to include upgrade to redis 2.8.21 528400090ed82ff212f08c4402c0b4681f91dc2e

## 7.13.1

- No changes

## 7.13.0

- IMPORTANT: Default number of unicorn workers is at minimum 2, maximum number is calculated to leave 1GB of RAM free 2f623a5e9b6d8c64b9ac30cd656a4e852895fcf0
- IMPORTANT: Postgresql unix socket is now moved from Postgresql default to prevent clashes between packaged and (possibly) existing Postgresql installation 9ca63f517d1bc6876abe90738e1fd99ea6f17ef6
- Packages will be built with new tags b81165d93422a8cb7ed80b0f33107bba636b094f
- Unicorn worker restart memory range is now configurable 69e0f8f2412509bead62944c6cd891a57926303a
- Updated redis to 2.8.21 d1f2f38da7381507624e18fcb77e489dff1d988b
- Updated omnibus-ctl to 0.3.6 d1f2f38da7381507624e18fcb77e489dff1d988b
- Updated chef to 12.4.0.rc.2 d1f2f38da7381507624e18fcb77e489dff1d988b
- Updated nginx to 1.7.12 d1f2f38da7381507624e18fcb77e489dff1d988b
- Updated libxml2 to 2.9.2 d1f2f38da7381507624e18fcb77e489dff1d988b
- Updated postgresql to 9.2.10 d1f2f38da7381507624e18fcb77e489dff1d988b
- Updated omnibus to commit 0abab93bb67377d20c94bc4322018e2248b4a610 d1f2f38da7381507624e18fcb77e489dff1d988b
- Postinstall message will check if instance is on EC2. Improved message output. dba7d1ed2ad06c6830b2f51d0d2090e2fc1d1490
- Change systemd service so GitLab starts up only after all FS are mounted and services started 2fc8482dafed474cb508b67ef17e982e3a30bdd1
- Use posttrans scriplet for RHEL systems to run upgrade or symlink omnibus-gitlab commands f9169ba540ae82017680d3bb313ecc1f5dc3567d
- Set net.core.somaxconn parameter for unicorn f147911fd0f9ddb4b55c26010bcedca1705c1b0b
- Add configuration option for builds directory for GitLab CI a9bb2580db4f9aabf086d25122d30aeb78e2f756
- Skip running selinux module load if selinux is disabled 5707ef1d25ff3ea202ce88d444154b5c5a6a9158

## 7.12.2

- Fix gitlab_shell_secret symlink which was removed by previous package on Redhat platform systems b34d4bcf4fae9581d94bdc5ed104a4655b72f4ad
- Upgrade openssl to 1.0.1p 0ebb908e130d191c3fa7e98b0a16f1e303d50890

## 7.12.1

- Added configuration options for auto_link_ldap_user and auto_sign_in_with_provider fdb185c14fa8fd7e57fddb41b62ce15ae4544380
- Update remote_syslog to 1.6.15 a1b3772ad32a3989b172aea175e7850609deb6e2
- Fixed callback url for CI autoauthorization dbb46b073d70aec5385efd056cfa45e39fbce764

## 7.12.0

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
- Rewrite runit default recipe which will now decide differently on which init is used  d3156878eadd643f136ee49d233e6c0b4ccebb28
- Do not depend on Ohai platform helper for running selinux recipe cee73a23488f61fd5a0c2b090a8e86ca5209cd3c

## 7.11.0

- Set the default certificate authority bundle to the embedded copy (Stan Hu) 673ac210216b9c01d58196e826b98db780a4ccd5
- Use a different mirror for libossp-uuid (DJ Mountney) 7f46d70855a4d97eb2b833fc2d120ddfc514dfd4
- Update omnibus-software 42839a91c297b9c637a13fbe4beb05058672abe2
- Add option to disable gitlab-rails when using only CI a784851e268ca1f23ce817c13a8d421c3211f96a
- Point to different state file for gitlab logrotate 42591805f64c48cb845538012b2a43fe765637d2
- Allow setting ssl_dhparam in nginx config 7b0c80ed9c1d85bebeedfc211a9b9e395593278c

## 7.10.0

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

## 7.9.0

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

## 7.8.0

- Add gitlab-ci to logrotate (François Conil) 397ce5bab202d9d86e30a62538dca1323b7f6f4c
- New LDAP defaults, port and method 7a65245c59fd094e88784f924ecd968d134716fa
- Disable GCE plugin 35b7b89c78fe7e1c35bb7063c2a03e70d6915c1d

## 7.7.0

- Update ruby to 2.1.5 79e6833045e70a43ac66f65252d40773c20438df
- Change the root_password setting to initial_root_password 577a4b7b895e17cbe159bf317169d173c6d3567a
- Include CI Oauth settings option 2e5ae7414ecd9f73cbfe284af5d38ee65ac892e4
- Include option to set global git config options 8eae0942ec27ffeec534ba02e4171a3b6cd6d193

## 7.6.0
- Update git to 2.0.5 0749ffc43b4583fae6fc8ac1b91111340a225f92
- Update libgit2 and rugged to version 0.21.2 66ac2e805a166ecb10bdf8ba001b106acd7e49f3
- Generate SMTP settings using one template for both applications (Michael Ruoss) a6d6ff11f102c6fa9da6209f80162c5e137feeb9
- Add gitlab-shell configuration settings for http_settings, audit_usernames, log_level 5e4310442a608c5c420ffe670a9ab6f111489151
- Enable Sidekiq MemoryKiller by default with a 1,000,000 kB limit 99bbe20b8f0968c4e3c4a42281014db3d3635a7f
- Change runit recipe for Fedora to systemd (Nathan) fbb7687f3cc2f38faaf6609d1396b76d2f6f7507
- Added kerberos lib to support gitlab dependency 66fd3a85cce74754e850034894a87d554fdb04b7
- gitlab.rb now lists all available configuration options 6080f125697f9fe7113af1dc80e0a7bc9ddb284e
- Add option to insert configuration settings in nginx template (Sander Boom) 5ba0485a489549a0bb33531e027a206b1775b3c0

## 7.5.0
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

## 7.4.0
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

## 7.3.1
- Fix web-server recipe order
- Make /var/opt/gitlab/nginx gitlab-www's home dir
- Remove unneeded write privileges from gitlab-www

## 7.3.0
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

## 7.2.0
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

## 7.1.0
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

## 7.0.0-ee.omnibus.1
- Fix MySQL build for Ubuntu 14.04

## 7.0.0
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

## 6.9.4-ee.omnibus.1
- Security: Use sockets and peer authentication for Postgres

## 6.9.2.omnibus.2
- Security: Use sockets and peer authentication for Postgres

## 6.9.2
- Create the authorized-keys.lock file for gitlab-shell 1.9.4

## 6.9.1
- Fix Nginx HTTP-to-HTTPS log configuration error (Konstantinos Paliouras)

## 6.9.0
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

## 6.8.1
- Use gitlab-rails 6.8.1

## 6.8.0
- MySQL client support (EE only)
- Update to omnibus-ruby 3.0
- Update omnibus-software (e.g. Postgres to 9.2.8)
- Email notifications in release.sh
- Rewrite parts of release.sh as a Makefile
- HTTPS support (Chuck Schweizer)
- Specify the Nginx bind address (Marco Wessel)
- Debian 7 build instructions (Kay Strobach)

## 6.7.3-ee.omnibus.1
- Update gitlab-rails to v6.7.3-ee

## 6.7.3-ee.omnibus

## 6.7.4.omnibus
- Update gitlab-rails to v6.7.4

## 6.7.2-ee.omnibus.2
- Update OpenSSL to 1.0.1g to address CVE-2014-0160

## 6.7.3.omnibus.3
- Update OpenSSL to 1.0.1g to address CVE-2014-0160
