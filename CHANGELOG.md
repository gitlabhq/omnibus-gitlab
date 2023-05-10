# Omnibus-gitlab changelog

The latest version of this file can be found at the master branch of the
omnibus-gitlab repository.

## 15.9.8 (2023-05-10)

No changes.

## 15.9.7 (2023-05-03)

No changes.

## 15.9.6 (2023-05-01)

### Security (3 changes)

- [Mattermost Security Updates April 2023](gitlab-org/security/omnibus-gitlab@3f09c8954f2ad3713c5402cbb9d7896b73531ddc) ([merge request](gitlab-org/security/omnibus-gitlab!336))
- [Patch Openssl for CVE-2023-0464](gitlab-org/security/omnibus-gitlab@00788e0d530c5f8cf77ee9e4d9a7b04a1652d24b) ([merge request](gitlab-org/security/omnibus-gitlab!333))
- [Patch Grafana against session cookie vulnerability and CVE-2023-1410](gitlab-org/security/omnibus-gitlab@f6a987b1f4e81193b7d356467bb8d1f456553d18) ([merge request](gitlab-org/security/omnibus-gitlab!328))

## 15.9.5 (2023-04-21)

### Fixed (1 change)

- [Fix suggested_reviewers run when rails is disabled](gitlab-org/omnibus-gitlab@b1aff71954786f883a1cc76b515c6b805037bcbd) ([merge request](gitlab-org/omnibus-gitlab!6795))

## 15.9.4 (2023-03-30)

### Security (4 changes)

- [Update openssl/openssl from 1s to 1t](gitlab-org/security/omnibus-gitlab@3ce5c0890a76b3c643ec1627553edfcd455a8e97) ([merge request](gitlab-org/security/omnibus-gitlab!309))
- [Mattermost March 2023 security updates](gitlab-org/security/omnibus-gitlab@bf3f3377afe386dc0a1a8bec938826e3ee09df15) ([merge request](gitlab-org/security/omnibus-gitlab!310))
- [Update redis to 6.2.11](gitlab-org/security/omnibus-gitlab@efe261861f4aad23f61ab31fd637b3d073faf658) ([merge request](gitlab-org/security/omnibus-gitlab!313))
- [Update curl to 8.0.1 to resolve February CVEs](gitlab-org/security/omnibus-gitlab@f51881d8f9dc9c4331a581f710449ac34193708b) ([merge request](gitlab-org/security/omnibus-gitlab!320))

## 15.9.3 (2023-03-09)

No changes.

## 15.9.2 (2023-03-02)

### Security (1 change)

- [Update libksba/gnupg to 1.6.3/2.2.41](gitlab-org/security/omnibus-gitlab@269c9e5c87b41c68909ee0ea2fe4f25cd07cbe5e) ([merge request](gitlab-org/security/omnibus-gitlab!305))

## 15.9.1 (2023-02-23)

No changes.

## 15.9.0 (2023-02-21)

### Added (5 changes)

- [Provide packages for Amazon Linux 2022](gitlab-org/omnibus-gitlab@243ab3b3d9b122a4c996e7850e1c4942980278d9) ([merge request](gitlab-org/omnibus-gitlab!6477))
- [Add gitlab-sshd configuration support](gitlab-org/omnibus-gitlab@833c4489ace2a24ccdf21e53026f862877b60709) ([merge request](gitlab-org/omnibus-gitlab!6446))
- [Add redis_yml_override setting](gitlab-org/omnibus-gitlab@7f3d67ce21c00dd6427a885adc10f751d3e53585) ([merge request](gitlab-org/omnibus-gitlab!6609))
- [Add ci_runners_stale_machines_cleanup_worker setting](gitlab-org/omnibus-gitlab@fdd9fac5b46524182bdc1dd434fb930faa3bb0b7) ([merge request](gitlab-org/omnibus-gitlab!6623))
- [Allow configuring repository cache redis instance](gitlab-org/omnibus-gitlab@8f4717e1ac2662aed5d738267541db915b99c75c) ([merge request](gitlab-org/omnibus-gitlab!6582))

### Changed (20 changes)

- [Match Praefect's configuration format in Omnibus](gitlab-org/omnibus-gitlab@4dff04a602afde189c8521c22703b3cb83e5a0b0) ([merge request](gitlab-org/omnibus-gitlab!6658))
- [Use first entry in allowed_hosts, if set, for healthcheck](gitlab-org/omnibus-gitlab@293e8314aeb4ac4950d6ad6a30255b1567a88bac) ([merge request](gitlab-org/omnibus-gitlab!6666))
- [Mark praefect configuration as sensitive](gitlab-org/omnibus-gitlab@aa8048d8aa248d0b486d462264ff537bb8f63489) ([merge request](gitlab-org/omnibus-gitlab!6679))
- [Mark gitaly configuration as sensitive](gitlab-org/omnibus-gitlab@289a980977bd89c0db4495eb45f4d9752f79aafe) ([merge request](gitlab-org/omnibus-gitlab!6678))
- [Update acme-client to 2.0.13](gitlab-org/omnibus-gitlab@ac2a0a1188c162dfdc9777b3cee45788308391fc) ([merge request](gitlab-org/omnibus-gitlab!6655))
- [Update redis_exporter to version 1.45.0](gitlab-org/omnibus-gitlab@6b1c64403e03e442a5fa0566a5a5868bae8ad31c) ([merge request](gitlab-org/omnibus-gitlab!6483))
- [Update Mattermost to 7.7.1](gitlab-org/omnibus-gitlab@2ec912a331ab3213b24a1f356e92c583f28dcb4e) by @antonis.stamatiou ([merge request](gitlab-org/omnibus-gitlab!6643))
- [Bump Omnibus builder image to 4.5.0](gitlab-org/omnibus-gitlab@ffb142f5b501be44485a15353b3c3f9239894dc0) ([merge request](gitlab-org/omnibus-gitlab!6665))
- [Update gitlab-org/gitlab-exporter from 12.1.0 to 12.1.1](gitlab-org/omnibus-gitlab@1db2e56924194dd1dc112e83449a704a9963ba8f) ([merge request](gitlab-org/omnibus-gitlab!6664))
- [Update alertmanager to version 0.25.0](gitlab-org/omnibus-gitlab@c38166553e68923b0135650b60edb6c51b31b544) ([merge request](gitlab-org/omnibus-gitlab!6584))
- [Update gitlab-exporter to version 12.1.0](gitlab-org/omnibus-gitlab@9831e53a36315d203740be71d9369cc2f3be712e) ([merge request](gitlab-org/omnibus-gitlab!6602))
- [Update logrotate to version 3.21.0](gitlab-org/omnibus-gitlab@7d43d4746039072f8925773f2cd1f6705ff28b39) ([merge request](gitlab-org/omnibus-gitlab!6613))
- [Update gitlab-org/container-registry to v3.66.0-gitlab](gitlab-org/omnibus-gitlab@4503ed5de15b884bc28e81198f98465efe443ff0) ([merge request](gitlab-org/omnibus-gitlab!6651))
- [Update libpng version to 1.6.39](gitlab-org/omnibus-gitlab@27d88f95bc3efd1410d1c32d4ce2937aa4464626) ([merge request](gitlab-org/omnibus-gitlab!6571))
- [Update libtiff to 4.5.0](gitlab-org/omnibus-gitlab@7fe15f368e3edc25aeffa4540e68dd84bd4d37d3) ([merge request](gitlab-org/omnibus-gitlab!6579))
- [Match Praefect's configuration format in Omnibus](gitlab-org/omnibus-gitlab@a82c788d46c6fd0a234999a2fe8d9556bf95cdd5) ([merge request](gitlab-org/omnibus-gitlab!6373))
- [Use shellwords to escape special characters](gitlab-org/omnibus-gitlab@7c76d30036b62eed3ea7b98c87c575c6bd3d5dda) ([merge request](gitlab-org/omnibus-gitlab!6572))
- [Use config file for Pages Headers parameter instead of command line](gitlab-org/omnibus-gitlab@cc022abb999fb9c967e369e70440bd2bd0556ad1) ([merge request](gitlab-org/omnibus-gitlab!6624))
- [Update gitlab-org/container-registry from v3.63.0 to v3.65.0](gitlab-org/omnibus-gitlab@c8380837bdb5e8c3a8011297728d99adf6b13426) ([merge request](gitlab-org/omnibus-gitlab!6618))
- [Change ci_runner_versions_reconciliation_worker job to run daily](gitlab-org/omnibus-gitlab@a962f5a15722e86c16fd599d7fa2bfb5d3a3c2ee) ([merge request](gitlab-org/omnibus-gitlab!6622))

### Deprecated (2 changes)

- [Deprecate legacy Praefect configuration options](gitlab-org/omnibus-gitlab@96c147cf28cc774c410816cd42fa51c8ce3143d4) ([merge request](gitlab-org/omnibus-gitlab!6669))
- [Deprecate queue_selector and negate options](gitlab-org/omnibus-gitlab@16c80e4fb09ed0f1a785e2718318df1e7006c567) ([merge request](gitlab-org/omnibus-gitlab!6676))

### Security (1 change)

- [Update Python3 version to 3.9.16](gitlab-org/omnibus-gitlab@39c2dc9969b798dc1c9a44b25aaba99b7b66fc9a)

### Other (3 changes)

- [Add docs for troubleshooting connection problems due to two connections](gitlab-org/omnibus-gitlab@3e3d216c7680edc37a2cacd2d170f565b243dfc7) ([merge request](gitlab-org/omnibus-gitlab!6663))
- [Corrects the example for KAS K8S proxy URL](gitlab-org/omnibus-gitlab@c064071105007d8219e674c07d2f67812d330875) by @zeeZ ([merge request](gitlab-org/omnibus-gitlab!6648))
- [Use templatesymlink :delete to cleanup redis config](gitlab-org/omnibus-gitlab@5dfefc907e683771cb543ecd49c549da651f0c8b) ([merge request](gitlab-org/omnibus-gitlab!6594))

## 15.8.3 (2023-02-15)

No changes.

## 15.8.2 (2023-02-10)

### Security (1 change)

- [Update Python3 version to 3.9.16](gitlab-org/security/omnibus-gitlab@cfe38a683798149d401602c8466f83d2774eac64) ([merge request](gitlab-org/security/omnibus-gitlab!299))

## 15.8.1 (2023-01-30)

No changes.

## 15.8.0 (2023-01-20)

### Added (1 change)

- [Add secret and config for Suggested Reviewers](gitlab-org/omnibus-gitlab@ed1346d55709616e3a900348a83f9495be017aef) ([merge request](gitlab-org/omnibus-gitlab!6560))

### Fixed (2 changes)

- [Revert dropping of Ominbus gitconfig default values](gitlab-org/omnibus-gitlab@d89442331ab3c008e83fbf7ef3ab89e4c611bfdb) ([merge request](gitlab-org/omnibus-gitlab!6608))
- [Update curl to 7.87.0](gitlab-org/omnibus-gitlab@c8af56ff986b149daf106341996dba220b7138ec) ([merge request](gitlab-org/omnibus-gitlab!6589))

### Changed (4 changes)

- [Bump PostgreSQL max connections to 500](gitlab-org/omnibus-gitlab@030d58564fe9355413eb45fcdb68a3a4b7a5050c) ([merge request](gitlab-org/omnibus-gitlab!6574))
- [Raise an error when initial root password is too short](gitlab-org/omnibus-gitlab@edb92cba83b5aac2ec16b59e44d51109b0b4c8e7) ([merge request](gitlab-org/omnibus-gitlab!6565))
- [Update container registry to v3.63.0-gitlab](gitlab-org/omnibus-gitlab@76400ce9c452361dbe231773accbf7d9148163c6) ([merge request](gitlab-org/omnibus-gitlab!6590))
- [Update gitlab-org/container-registry from v3.61.0-gitlab to v3.62.0-gitlab](gitlab-org/omnibus-gitlab@a36a73c008006f28a26623f12c8151f2a80de015) ([merge request](gitlab-org/omnibus-gitlab!6570))

### Deprecated (1 change)

- [Deprecate openSUSE 15.3](gitlab-org/omnibus-gitlab@53e62ec7ed3caec2d12cb107e3d59990b7adf9b5) ([merge request](gitlab-org/omnibus-gitlab!6626))

### Removed (2 changes)

- [Drop default values for `omnibus-gitconfig`](gitlab-org/omnibus-gitlab@631d7a30000b77cb83133099d7442ac567f2e5c0) ([merge request](gitlab-org/omnibus-gitlab!6610))
- [Drop default values for `omnibus-gitconfig`](gitlab-org/omnibus-gitlab@be451c5b7993e06c31189ab144ac1ecec9cf4746) ([merge request](gitlab-org/omnibus-gitlab!6598))

### Security (2 changes)

- [Bump Redis version to 6.2.8](gitlab-org/omnibus-gitlab@63bbe2646c2202292f6ff78f161ce663c91cc36c)
- [Update logrotate to 3.20.1](gitlab-org/omnibus-gitlab@c0d6410b174d6b2aa194b4afee143c2da1c9a35e)

### Other (2 changes)

- [Update gpgme dependencies to match ruby-gpgme dependencies](gitlab-org/omnibus-gitlab@31e0eaf442e41608b04e022425b844d594b80ff9) ([merge request](gitlab-org/omnibus-gitlab!6557))
- [Update Mattermost to 7.5.2](gitlab-org/omnibus-gitlab@7362352ebc6e6d274fcce076385e13395346a53f) by @akis.maziotis ([merge request](gitlab-org/omnibus-gitlab!6583))

## 15.7.7 (2023-02-10)

### Security (1 change)

- [Update Python3 version to 3.9.16](gitlab-org/security/omnibus-gitlab@5ffb6f66629c1fe7f0b0325eca21e65544468b01) ([merge request](gitlab-org/security/omnibus-gitlab!298))

## 15.7.6 (2023-01-30)

### Security (1 change)

- [Update Mattermost to December 2022 release](gitlab-org/security/omnibus-gitlab@0847cefdce1883a7e7ef0c4796778e0307466852) ([merge request](gitlab-org/security/omnibus-gitlab!301))

## 15.7.5 (2023-01-12)

No changes.

## 15.7.4 (2023-01-12)

No changes.

## 15.7.3 (2023-01-11)

No changes.

## 15.7.2 (2023-01-09)

### Security (2 changes)

- [Bump Redis version to 6.2.8](gitlab-org/security/omnibus-gitlab@e648c5ae4d486990b14f07bdbff01cae45e4f144) ([merge request](gitlab-org/security/omnibus-gitlab!288))
- [Update logrotate to 3.20.1](gitlab-org/security/omnibus-gitlab@2679b92ae2c935635d1980f7b1c263f76a875a1b) ([merge request](gitlab-org/security/omnibus-gitlab!286))

## 15.7.1 (2023-01-05)

No changes.

## 15.7.0 (2022-12-21)

### Added (3 changes)

- [praefect: Add configuration for graceful_stop_timeout](gitlab-org/omnibus-gitlab@637f27795d09d35f34ec797fc5e95f3e3ded4015) ([merge request](gitlab-org/omnibus-gitlab!6549))
- [Provide packages for openSUSE Leap 15.4](gitlab-org/omnibus-gitlab@29305a26825423fe5fcad15b42d74a01feb9b0d8) ([merge request](gitlab-org/omnibus-gitlab!6499))
- [Expose missing gitlab.yml settings in gitlab.rb](gitlab-org/omnibus-gitlab@36459542f60633a047362be26cebc7b766c77958) by @pm9551 ([merge request](gitlab-org/omnibus-gitlab!6529))

### Fixed (2 changes)

- [Ensure Workhorse is built in FIPS mode](gitlab-org/omnibus-gitlab@a1415708f485968f0e41e0ba9fd48285de259b2c) ([merge request](gitlab-org/omnibus-gitlab!6575))
- [gitaly: Allow passing gitconfig as separate section, subsection and key](gitlab-org/omnibus-gitlab@d5d04066f6e41b6a3d5ee624617e6ed93441cc0d) ([merge request](gitlab-org/omnibus-gitlab!6512))

### Changed (5 changes)

- [Update Ruby to 2.7.7 and 3.0.5](gitlab-org/omnibus-gitlab@19bea74af288b046e15643c8de73c066a8fac70b) ([merge request](gitlab-org/omnibus-gitlab!6554))
- [Set Sidekiq default max concurrency to 20](gitlab-org/omnibus-gitlab@b6ac13b198e31f3f60cc2f51cb1fbd223960780e) ([merge request](gitlab-org/omnibus-gitlab!6536))
- [Update to libpng 1.6.38](gitlab-org/omnibus-gitlab@e623427be34d79efec59c5da47a59645b509f740) ([merge request](gitlab-org/omnibus-gitlab!6353))
- [Update container-registry from to v3.61.0-gitlab](gitlab-org/omnibus-gitlab@27607ff397f95f07429dc87dd6e98f9b66b134a4) ([merge request](gitlab-org/omnibus-gitlab!6522))
- [Update openssl from 1q to 1s](gitlab-org/omnibus-gitlab@a89c5c715b3f3d43d7cba5968eb41c1a2e65f273) ([merge request](gitlab-org/omnibus-gitlab!6520))

### Security (5 changes)

- [Update zlib to 1.2.13](gitlab-org/omnibus-gitlab@a1d1231d20de5d50934a5bded68c561e304af140)
- [Bump Ruby version to 2.7.6](gitlab-org/omnibus-gitlab@76cf0c240a09459b6862a9d8f907730741b966fe)
- [Bump ncurses to 6.3-20220416 to patch against CVE-2022-2945](gitlab-org/omnibus-gitlab@d1f697ebdc676a3482e607f303515221533e4dc1)
- [Update xmlsoft/libxml2 to version 2.10.3](gitlab-org/omnibus-gitlab@ab5244050e92f0c88b794447af9a372f9abb4d79)
- [Upgrade haxx/curl to 7.86.0](gitlab-org/omnibus-gitlab@c6714986da0fa50d7fa24b66bba3fa1c71f85075)

### Other (1 change)

- [Update Mattermost to 7.5.1](gitlab-org/omnibus-gitlab@477c3f4be4fd4933f35accf422ce5528aae20fec) by @akis.maziotis ([merge request](gitlab-org/omnibus-gitlab!6526))

## 15.6.8 (2023-02-10)

### Security (1 change)

- [Update Python3 version to 3.9.16](gitlab-org/security/omnibus-gitlab@0e34e07ef8bcad35e6efaeb82deed22dbb07a6df) ([merge request](gitlab-org/security/omnibus-gitlab!297))

## 15.6.7 (2023-01-30)

### Fixed (1 change)

- [Ensure Workhorse is built in FIPS mode](gitlab-org/security/omnibus-gitlab@22eabafc5c4650ab5f64174ed233abf9fc33f1f0)

### Security (1 change)

- [Update Mattermost to December 2022 release](gitlab-org/security/omnibus-gitlab@3eeb9089cedfb6e9609749a803e45cf5050e6ea0) ([merge request](gitlab-org/security/omnibus-gitlab!300))

## 15.6.6 (2023-01-12)

### Security (1 change)

- [Allow GIT_REPO_URL to be overridden for self managed releases [15.6]](gitlab-org/security/omnibus-gitlab@5c76abf360fa5aec6985a0e7c040fa9c3e4a30fd) ([merge request](gitlab-org/security/omnibus-gitlab!296))

## 15.6.5 (2023-01-12)

No changes.

## 15.6.4 (2023-01-09)

### Security (3 changes)

- [Bump Redis version to 6.2.8](gitlab-org/security/omnibus-gitlab@458f9cc16a707d7503b400150685bd366aa4ba23) ([merge request](gitlab-org/security/omnibus-gitlab!289))
- [Update logrotate to 3.20.1](gitlab-org/security/omnibus-gitlab@0010b7e1957fe373ca4b0c0d5726cd2459928ae6) ([merge request](gitlab-org/security/omnibus-gitlab!285))
- [Update curl to 7.87.0](gitlab-org/security/omnibus-gitlab@1538649d714ba3e85fdf3e21c7f13277100e8201) ([merge request](gitlab-org/security/omnibus-gitlab!293))

## 15.6.3 (2022-12-21)

No changes.

## 15.6.2 (2022-12-05)

### Fixed (1 change)

- [gitaly: Fix migration of gitconfig with subsections](gitlab-org/omnibus-gitlab@befed8189e5148860a7b29b798c010fa73ccf535) ([merge request](gitlab-org/omnibus-gitlab!6551))

## 15.6.1 (2022-11-30)

### Security (5 changes)

- [Update zlib to 1.2.13](gitlab-org/security/omnibus-gitlab@5389c40717adfc74e83651b967b8388a29ff0e72) ([merge request](gitlab-org/security/omnibus-gitlab!271))
- [Bump ncurses to 6.3-20220416 to patch against CVE-2022-2945](gitlab-org/security/omnibus-gitlab@4ccefeee22f07b4d92220ea48b0fe7adb2f7e830) ([merge request](gitlab-org/security/omnibus-gitlab!272))
- [Bump Ruby version to 2.7.6](gitlab-org/security/omnibus-gitlab@834510a82c292fd4dd366c237081a8cbdee49073) ([merge request](gitlab-org/security/omnibus-gitlab!275))
- [Upgrade haxx/curl to 7.86.0](gitlab-org/security/omnibus-gitlab@f058f488b76609fe6fdbe973153bc5579b5cdf3e) ([merge request](gitlab-org/security/omnibus-gitlab!261))
- [Update xmlsoft/libxml2 to version 2.10.3](gitlab-org/security/omnibus-gitlab@507c425e7f3a6c209c391fff86fabfd673a653f5) ([merge request](gitlab-org/security/omnibus-gitlab!281))

## 15.6.0 (2022-11-21)

### Fixed (3 changes)

- [Apply proxy_custom_buffer_size option to API location as well](gitlab-org/omnibus-gitlab@70756a8328537f203fe8223d6b02be13e95ce140) ([merge request](gitlab-org/omnibus-gitlab!6481))
- [Fixed error logging for geo-replication-(pause|resume)](gitlab-org/omnibus-gitlab@6b49363b7ed43de19c26153cc9a9fb39d8fbdd3d) by @m.baur ([merge request](gitlab-org/omnibus-gitlab!6478))
- [Conditionally enable FIPS auto-detection](gitlab-org/omnibus-gitlab@0136f38ff4237b4bf04855fc054b4e781f5c3d05) ([merge request](gitlab-org/omnibus-gitlab!6473))

### Changed (4 changes)

- [Update gitlab-exporter from 11.19.0 to 12.0.0](gitlab-org/omnibus-gitlab@1a9d1c5dbb7af52c181896ec75c8c99a6f7012c7) ([merge request](gitlab-org/omnibus-gitlab!6500))
- [Update gitlab-org/container-registry from v3.60.1-gitlab to v3.60.2-gitlab](gitlab-org/omnibus-gitlab@2246b68c18d58e110fc7e63cc3f40ecc36b5a16d) ([merge request](gitlab-org/omnibus-gitlab!6506))
- [Bump Container Registry to v3.60.1-gitlab](gitlab-org/omnibus-gitlab@b48b492d2effeccd03fea52a752a59a64e5261ae) ([merge request](gitlab-org/omnibus-gitlab!6489))
- [Bump rspec and friends to 3.11 in omnibus](gitlab-org/omnibus-gitlab@6785e0a132e40e126a9c9028784a9dd11bfe9da5) ([merge request](gitlab-org/omnibus-gitlab!6498))

### Security (2 changes)

- [Upgrade curl to 7.85.0](gitlab-org/omnibus-gitlab@1f15b3922d6770061b40b5436a7990af7506e0bf)
- [Upgrade pcre2 to 10.40](gitlab-org/omnibus-gitlab@88a5fda9018a184e407fb18e5ef3d0e29d8f3019)

### Other (2 changes)

- [Add Puma on_worker_shutdown hook](gitlab-org/omnibus-gitlab@856617e16df2003fdb82768c17165998adbd8ddb) ([merge request](gitlab-org/omnibus-gitlab!6508))
- [Update Mattermost to 7.4.0](gitlab-org/omnibus-gitlab@a76ed1ffac36f6ab677c2c800460284a7dc9dc97) by @akis.maziotis ([merge request](gitlab-org/omnibus-gitlab!6462))

## 15.5.9 (2023-01-12)

### Security (1 change)

- [Allow GIT_REPO_URL to be overridden for self managed releases [15.5]](gitlab-org/security/omnibus-gitlab@04fe0d5863f2e40709c1940fe8b714150ffa1510) ([merge request](gitlab-org/security/omnibus-gitlab!295))

## 15.5.8 (2023-01-12)

No changes.

## 15.5.7 (2023-01-09)

### Security (4 changes)

- [Mattermost October 2022 Security Updates](gitlab-org/security/omnibus-gitlab@b1cbcc4bc3e969c769761194bb499fd05a196917) ([merge request](gitlab-org/security/omnibus-gitlab!267))
- [Bump Redis version to 6.2.8](gitlab-org/security/omnibus-gitlab@f0a27f685cec3aa7e46440024571cf24f22e3f5d) ([merge request](gitlab-org/security/omnibus-gitlab!290))
- [Update logrotate to 3.20.1](gitlab-org/security/omnibus-gitlab@fee4773dda91151e5ae7203c18a1aecd53d208f0) ([merge request](gitlab-org/security/omnibus-gitlab!284))
- [Update curl to 7.87.0](gitlab-org/security/omnibus-gitlab@440f9e88bed7dce1728fe85f6406219f69db465b) ([merge request](gitlab-org/security/omnibus-gitlab!292))

## 15.5.6 (2022-12-07)

### Fixed (1 change)

- [gitaly: Fix migration of gitconfig with subsections](gitlab-org/omnibus-gitlab@c9683e3d91f863993ec0abbda96a5f984ec5821c) ([merge request](gitlab-org/omnibus-gitlab!6561))

## 15.5.5 (2022-11-30)

### Security (7 changes)

- [Bump PostgreSQL versions to 12.12 and 13.8](gitlab-org/security/omnibus-gitlab@9c8b3f88ebbbea3a3a9920141e7fa0f588cb5cf5) ([merge request](gitlab-org/security/omnibus-gitlab!278))
- [Bump rsync to 3.2.7](gitlab-org/security/omnibus-gitlab@ba1291196ba1925e797a58e382ab2bb6781f0b4d) ([merge request](gitlab-org/security/omnibus-gitlab!255))
- [Update zlib to 1.2.13](gitlab-org/security/omnibus-gitlab@a8dc7bb99475bf1a8ad3cf21e9b6c6ade367f00b) ([merge request](gitlab-org/security/omnibus-gitlab!270))
- [Bump ncurses to 6.3-20220416 to patch against CVE-2022-2945](gitlab-org/security/omnibus-gitlab@bc212f47fa64361452b5ddf1465c20d051584068) ([merge request](gitlab-org/security/omnibus-gitlab!273))
- [Bump Ruby version to 2.7.6](gitlab-org/security/omnibus-gitlab@e2a0966fb350efb0c790564fb0e83a9a8073e630) ([merge request](gitlab-org/security/omnibus-gitlab!276))
- [Upgrade haxx/curl to 7.86.0](gitlab-org/security/omnibus-gitlab@2c0d26d49ff33ef458dbbccd208a806633e1be8a) ([merge request](gitlab-org/security/omnibus-gitlab!260))
- [Update xmlsoft/libxml2 to version 2.10.3](gitlab-org/security/omnibus-gitlab@1381b7e8bd5b7015952ca87a97f76f5e7a190473) ([merge request](gitlab-org/security/omnibus-gitlab!263))

## 15.5.4 (2022-11-11)

No changes.

## 15.5.3 (2022-11-07)

### Changed (1 change)

- [Bump Container Registry to v3.60.1-gitlab](gitlab-org/omnibus-gitlab@ecf2ce33ac249ac251b7cbea44a1dd54c5ae6ed3) ([merge request](gitlab-org/omnibus-gitlab!6490))

## 15.5.2 (2022-11-02)

### Security (2 changes)

- [Upgrade pcre2 to 10.40](gitlab-org/security/omnibus-gitlab@849947f198888e89a4a9fe2498e16b0544272bfd) ([merge request](gitlab-org/security/omnibus-gitlab!250))
- [Upgrade curl to 7.85.0](gitlab-org/security/omnibus-gitlab@f2d8212264ef716dc2de606807a5cc15320578f1) ([merge request](gitlab-org/security/omnibus-gitlab!247))

## 15.5.1 (2022-10-24)

No changes.

## 15.5.0 (2022-10-21)

### Added (7 changes)

- [Add Raspberry Pi Bullseye to check-packages](gitlab-org/omnibus-gitlab@f25af09c5ded74f3c72bd9f13b08eedf10d328dc) ([merge request](gitlab-org/omnibus-gitlab!6456))
- [Add microsoft_graph_mailer settings](gitlab-org/omnibus-gitlab@3103922e4150b18f8453bde337af980e5683384e) ([merge request](gitlab-org/omnibus-gitlab!6369))
- [Provide packages for RaspberryPi OS 11 Bullseye](gitlab-org/omnibus-gitlab@b853d6732a1b1b5b2e0e7c77152168d2eef01141) ([merge request](gitlab-org/omnibus-gitlab!6439))
- [Support for 'track-repositories' Praefect command](gitlab-org/omnibus-gitlab@d1d4609e559045115420f0554a1f3b42a73886bc) ([merge request](gitlab-org/omnibus-gitlab!6319))
- [Provide packages for Ubuntu 22.04](gitlab-org/omnibus-gitlab@d6895741f17e284a3e762720acbe563291a10c2e) ([merge request](gitlab-org/omnibus-gitlab!6337))
- [Provide FIPS packages for Amazon Linux 2](gitlab-org/omnibus-gitlab@2222e5d7b99a419259e6410f911cb976e6a591c6) ([merge request](gitlab-org/omnibus-gitlab!6314))
- [Support specifying ssl_password_file in nginx conf](gitlab-org/omnibus-gitlab@47996b10a47f0d5725dcf4a1098862ca3f350c67) ([merge request](gitlab-org/omnibus-gitlab!6367))

### Fixed (5 changes)

- [Extend and enhance SELinux distro support](gitlab-org/omnibus-gitlab@f28a20e668a4d32142618e7b0961680b47b362f9) ([merge request](gitlab-org/omnibus-gitlab!6419))
- [Update custom cop rule as per updating RuboCop to v1](gitlab-org/omnibus-gitlab@318a4a8a007efc6e31455f50b69e5579ab3366f6) ([merge request](gitlab-org/omnibus-gitlab!6402))
- [Patch nginx-module-vts to compile with gcc 11](gitlab-org/omnibus-gitlab@f7c083ef12b8a64dbd51860c32392859853be826) ([merge request](gitlab-org/omnibus-gitlab!6333))
- [Fix Ruby MD5 not always being available in FIPS mode](gitlab-org/omnibus-gitlab@695f08da2428edf3e9a790b91a9d7f1b25bb9df0) ([merge request](gitlab-org/omnibus-gitlab!6357))
- [Update gitlab-styles from 7.1.0 to 9.0.0](gitlab-org/omnibus-gitlab@ee1c18913065abad5b03420fa4e107f3ca3722b2) ([merge request](gitlab-org/omnibus-gitlab!6355))

### Changed (16 changes)

- [Update webdevops/go-crond from to 22.9.1](gitlab-org/omnibus-gitlab@6a0cc42d47d40d7929fd8f6b6df600938f4511f2) ([merge request](gitlab-org/omnibus-gitlab!6438))
- [Drop exclusion of mysql group from gitlab-rails building](gitlab-org/omnibus-gitlab@0bee93924ddc7cfeb317f7077e4d78a299130787) ([merge request](gitlab-org/omnibus-gitlab!6452))
- [Add exporters to deps.yml](gitlab-org/omnibus-gitlab@e653d77e7895cbfd65c951967521e6fd50d51f78) ([merge request](gitlab-org/omnibus-gitlab!6415))
- [Update prometheus to v2.38.0](gitlab-org/omnibus-gitlab@94b0c0056b82731e6b51832e26f69a0c85babe0d) ([merge request](gitlab-org/omnibus-gitlab!6426))
- [Update postgres-exporter to v0.11.1](gitlab-org/omnibus-gitlab@08b1519c626dbe73ac9ef8246420a8f58f521606) ([merge request](gitlab-org/omnibus-gitlab!6418))
- [Allow output of Rails migrations in reconfigure step](gitlab-org/omnibus-gitlab@da9f42a9fb755a312913a49c9ba50dc962bc26e6) ([merge request](gitlab-org/omnibus-gitlab!6404))
- [Update libtensorflow_lite to version 2.6.0](gitlab-org/omnibus-gitlab@f8f3454031dde9f1110b4cb2e275752817b79e6a) ([merge request](gitlab-org/omnibus-gitlab!6428))
- [Update alertmanager to v0.24.0](gitlab-org/omnibus-gitlab@46223601eaec79a44fe35b6b504c41ca37b63607) ([merge request](gitlab-org/omnibus-gitlab!6427))
- [Update pgbouncer-exporter to v0.5.1](gitlab-org/omnibus-gitlab@4bd6f38c3803d0d4160db4b51e0fa3b36da8f497) ([merge request](gitlab-org/omnibus-gitlab!6417))
- [Update redis-exporter to v1.44.0](gitlab-org/omnibus-gitlab@5bf77e9d07e14caf1c54265e7d01768d887e3a93) ([merge request](gitlab-org/omnibus-gitlab!6416))
- [Update node-exporter to v1.4.0](gitlab-org/omnibus-gitlab@5858a9d5929faa2505657381b22145bc2022ae13) ([merge request](gitlab-org/omnibus-gitlab!6420))
- [Exclude Spamcheck libraries from build](gitlab-org/omnibus-gitlab@05ddcc2a53a8d15f0ea6a08360aa771ed614f553) ([merge request](gitlab-org/omnibus-gitlab!6392))
- [Add timeout options for reconfigure run as part of pg-upgrade](gitlab-org/omnibus-gitlab@6575d9fe57f1d9a17bb33788b119cc31aa9e21dd) by @zhzhang93 ([merge request](gitlab-org/omnibus-gitlab!6321))
- [Compile jemalloc with Ruby by default](gitlab-org/omnibus-gitlab@6fb7f2d0e0ecf358acd4702a45346017fb906495) ([merge request](gitlab-org/omnibus-gitlab!6363))
- [Remove python library whl files from package](gitlab-org/omnibus-gitlab@e48e47c7d38b9ad72835df0c0a79230a073f8102) ([merge request](gitlab-org/omnibus-gitlab!6358))
- [Allow Chef FIPS auto-detection](gitlab-org/omnibus-gitlab@c2e843d1480415a10d20e3c164fc5eb3eb22d9c7) ([merge request](gitlab-org/omnibus-gitlab!6338))

### Deprecated (2 changes)

- [Deprecate `gitlab_rails['gitlab_default_can_create_group']` setting](gitlab-org/omnibus-gitlab@0ebc71056e566af02fccbeb37d80e086e28bfdb1) ([merge request](gitlab-org/omnibus-gitlab!6316))
- [Praefect: Deprecate DB metrics configuration](gitlab-org/omnibus-gitlab@1494fa7aea6f1ff3446b4441c4909a531d2cedbe) ([merge request](gitlab-org/omnibus-gitlab!6317))

### Security (2 changes)

- [Pass necessary headers on accessing healthcheck endpoints](gitlab-org/omnibus-gitlab@3a68dfd593b98935643d0c1f4c5dc69efc28d288)
- [Apply Grafana CVE-2022-3110 patch](gitlab-org/omnibus-gitlab@01e83fca75011af8ea5b9e284614837f6453185b)

### Other (3 changes)

- [Update python3 from 3.9.6 to 3.10.7](gitlab-org/omnibus-gitlab@1dd2956c0a2411b2b9287a0d5ddf1174b6ce81ea) ([merge request](gitlab-org/omnibus-gitlab!6401))
- [Enable Style/GlobalVars cop through all files in RuboCop](gitlab-org/omnibus-gitlab@db7ad34d52fe0844be1cf7e02e7fc04a465c7271) ([merge request](gitlab-org/omnibus-gitlab!6371))
- [Remove license patch for removed awesome_print gem](gitlab-org/omnibus-gitlab@3e3fcf4a50c89f7f008dce7c16fafd1b922cfd1a) ([merge request](gitlab-org/omnibus-gitlab!6370))

## 15.4.6 (2022-11-30)

### Security (7 changes)

- [Bump PostgreSQL versions to 12.12 and 13.8](gitlab-org/security/omnibus-gitlab@ccdf562dfc14dcb9b81a68bb3adfbd9f7dedf0e8) ([merge request](gitlab-org/security/omnibus-gitlab!279))
- [Bump rsync to 3.2.7](gitlab-org/security/omnibus-gitlab@d848e1890b81341dce7efb71afb8b57dd7fe3ab3) ([merge request](gitlab-org/security/omnibus-gitlab!254))
- [Update zlib to 1.2.13](gitlab-org/security/omnibus-gitlab@897aebdd97adcf589a33cc8c7da64dcda6619385) ([merge request](gitlab-org/security/omnibus-gitlab!269))
- [Bump ncurses to 6.3-20220416 to patch against CVE-2022-2945](gitlab-org/security/omnibus-gitlab@e971a0449829f49b0aea2a37c8c5bdb2e91e2eb7) ([merge request](gitlab-org/security/omnibus-gitlab!274))
- [Bump Ruby version to 2.7.6](gitlab-org/security/omnibus-gitlab@c29547b207afb58375080a1b9457f010cb4f6b9a) ([merge request](gitlab-org/security/omnibus-gitlab!277))
- [Upgrade haxx/curl to 7.86.0](gitlab-org/security/omnibus-gitlab@dab4c292e4e54d21c40ccdd329adb15b986364d0) ([merge request](gitlab-org/security/omnibus-gitlab!259))
- [Update xmlsoft/libxml2 to version 2.10.3](gitlab-org/security/omnibus-gitlab@68c2da6d17f0b3ab7e36ce0b1474dfd7ce5a8cf3) ([merge request](gitlab-org/security/omnibus-gitlab!264))

## 15.4.5 (2022-11-15)

No changes.

## 15.4.4 (2022-11-02)

### Security (2 changes)

- [Upgrade pcre2 to 10.40](gitlab-org/security/omnibus-gitlab@c751b4b9569350a109876544400b29fc6c8ce7e4) ([merge request](gitlab-org/security/omnibus-gitlab!249))
- [Upgrade curl to 7.85.0](gitlab-org/security/omnibus-gitlab@8cfcfb3747d46c43f7e5c2fb1fec107609a32515) ([merge request](gitlab-org/security/omnibus-gitlab!246))

## 15.4.3 (2022-10-19)

No changes.

## 15.4.2 (2022-10-04)

No changes.

## 15.4.1 (2022-09-29)

### Security (2 changes)

- [Apply Grafana CVE-2022-3110 patch](gitlab-org/security/omnibus-gitlab@3febf0771ca0924f8db3392c99b03ab852ca4950) ([merge request](gitlab-org/security/omnibus-gitlab!239))
- [Pass necessary headers on accessing healthcheck endpoints](gitlab-org/security/omnibus-gitlab@48b29f3972d2137be4153ad9e7d5c2bd45a397aa) ([merge request](gitlab-org/security/omnibus-gitlab!240))

## 15.4.0 (2022-09-21)

### Added (1 change)

- [Add support for Gitaly GPG signing](gitlab-org/omnibus-gitlab@6f401b63547891efec40799ae8178cdf7342fb88) ([merge request](gitlab-org/omnibus-gitlab!6294))

### Fixed (2 changes)

- [Fix an issue were the incoming email secret file was not being created](gitlab-org/omnibus-gitlab@4ce9a961eec600bfb8812562e9ff05cf92381200) ([merge request](gitlab-org/omnibus-gitlab!6324))
- [API should return JSON on errors even if custom error pages are used](gitlab-org/omnibus-gitlab@e2e2176d07cb2a14c9a49ca548c3467edd81f009) by @ercan.ucan ([merge request](gitlab-org/omnibus-gitlab!6276))

### Changed (7 changes)

- [Bump packer version to 1.8.2](gitlab-org/omnibus-gitlab@9095dd5198ffc3020001deaf25c96c68d92600d9) ([merge request](gitlab-org/omnibus-gitlab!6322))
- [Use sha256 instead of md5 when downloading component source](gitlab-org/omnibus-gitlab@20602725482d70f75a41a6649cf0aa6989753754) ([merge request](gitlab-org/omnibus-gitlab!6330))
- [Update gpgme to version 1.17.0](gitlab-org/omnibus-gitlab@e59a65c7ec6e3b729f2b03a370ac126e9c4fa128) ([merge request](gitlab-org/omnibus-gitlab!6332))
- [Compatibility for hashed oauth secrets](gitlab-org/omnibus-gitlab@643a089acd17d4d5d14298db0e6f7eaff4844fe8) ([merge request](gitlab-org/omnibus-gitlab!6310))
- [Raise default Geo base backup timeout to 12 hours](gitlab-org/omnibus-gitlab@596373120354bf9aa819732aeb8a9ad6f8c0b1d4) ([merge request](gitlab-org/omnibus-gitlab!6308))
- [Improve error message when omnibus_gitconfig is not set properly](gitlab-org/omnibus-gitlab@0bf606a23d39570189c5a53650e9f35b351759c5) ([merge request](gitlab-org/omnibus-gitlab!6298))
- [Update container registry to v3.53.0-gitlab](gitlab-org/omnibus-gitlab@f9b56f675ad12c55d781392c9ad318ee6e1c6dde) ([merge request](gitlab-org/omnibus-gitlab!6227))

### Security (4 changes)

- [Bump gitlab-exporter version to 11.18.2 to mitigate VULNDB-255039](gitlab-org/omnibus-gitlab@f14d07f73f54e407edd3ed6ecf76e17ddda0664b)
- [Update unzip to 6.0.27](gitlab-org/omnibus-gitlab@76bc3e9c3dbfe8a57aedbb9b73631f5f3cd3dcf0)
- [Bump nginx version to 1.20.2](gitlab-org/omnibus-gitlab@7ee8bc82dd644a38e5516c9cadd07e77a4dd84c3)
- [Update libxml2 from 2.9.10 to 2.9.14](gitlab-org/omnibus-gitlab@b4ce083cfb478ce04daeaa375fd6ae5d98f26a32) ([merge request](gitlab-org/omnibus-gitlab!6248))

### Other (5 changes)

- [Update chef-classroom to 1.0.5](gitlab-org/omnibus-gitlab@dca6529508cd299f6557acceb379f2d5f73fac5d) ([merge request](gitlab-org/omnibus-gitlab!6274))
- [Update libyaml to 0.2.5](gitlab-org/omnibus-gitlab@69b88f4fc29ae255820ec19a38098e3a9f23d418) ([merge request](gitlab-org/omnibus-gitlab!6253))
- [Update aws-sdk-ec2 and aws-sdk-marketplacecatalog](gitlab-org/omnibus-gitlab@cb7b423577f890de04502214272a6c5cba1f4aec) ([merge request](gitlab-org/omnibus-gitlab!6257))
- [Replace byebug and pry](gitlab-org/omnibus-gitlab@6764d7ab3c4925a157fe09ff1ba1d92d4f23c742) ([merge request](gitlab-org/omnibus-gitlab!6240))
- [Use HTTPS instead of HTTP for pkg-config-lite](gitlab-org/omnibus-gitlab@525cd1994d06d7f6304715338553a870085a15ca) ([merge request](gitlab-org/omnibus-gitlab!6252))

## 15.3.5 (2022-11-02)

### Security (2 changes)

- [Upgrade pcre2 to 10.40](gitlab-org/security/omnibus-gitlab@9ad83001cbc8927c6a8f6af941f8985714482951) ([merge request](gitlab-org/security/omnibus-gitlab!248))
- [Upgrade curl to 7.85.0](gitlab-org/security/omnibus-gitlab@c3af4488a448b32ac4abbbb273437af4476348c9) ([merge request](gitlab-org/security/omnibus-gitlab!245))

## 15.3.4 (2022-09-29)

### Security (3 changes)

- [Mattermost security release for 2022-08](gitlab-org/security/omnibus-gitlab@e8f1ac2a668c5dd6141ef30be03c65a608e6af57) ([merge request](gitlab-org/security/omnibus-gitlab!241))
- [Apply Grafana CVE-2022-3110 patch](gitlab-org/security/omnibus-gitlab@1722a2cbaf66b019ac8cd9ccf2b1bef868f7e353) ([merge request](gitlab-org/security/omnibus-gitlab!237))
- [Pass necessary headers on accessing healthcheck endpoints](gitlab-org/security/omnibus-gitlab@5601e4db7f660dd17f5c11bc31dad44baba5f293) ([merge request](gitlab-org/security/omnibus-gitlab!235))

## 15.3.3 (2022-09-01)

### Changed (1 change)

- [Improve error message when omnibus_gitconfig is not set properly](gitlab-org/omnibus-gitlab@1a77c08ef096d64482d7d08ce716d085765ae225) ([merge request](gitlab-org/omnibus-gitlab!6304))

## 15.3.2 (2022-08-30)

### Security (4 changes)

- [Update libxml2 from 2.9.10 to 2.9.14](gitlab-org/security/omnibus-gitlab@96138c7c299ef038554e809462f98229bf902451) ([merge request](gitlab-org/security/omnibus-gitlab!218))
- [Bump gitlab-exporter version to 11.18.2 to mitigate VULNDB-255039](gitlab-org/security/omnibus-gitlab@ccd42069e018253b751228e66ffffc35dc6c5b79) ([merge request](gitlab-org/security/omnibus-gitlab!232))
- [Update unzip to 6.0.27](gitlab-org/security/omnibus-gitlab@c82fcd26e4fda6a734b32036381a4cb2915569f5) ([merge request](gitlab-org/security/omnibus-gitlab!228))
- [Bump nginx version to 1.20.2](gitlab-org/security/omnibus-gitlab@8917dbf9f158bc010918e9e757bff29fe339acce) ([merge request](gitlab-org/security/omnibus-gitlab!222))

## 15.3.1 (2022-08-22)

No changes.

## 15.3.0 (2022-08-19)

### Added (2 changes)

- [Add perl as runtime dependency](gitlab-org/omnibus-gitlab@89e6dc81c0745a30450cdf45fd849dbced1f2fc4) ([merge request](gitlab-org/omnibus-gitlab!6237))
- [Add ci_runner_versions_reconciliation_worker setting](gitlab-org/omnibus-gitlab@22d70d6862e415e6d746bd4a97feccccee2851e3) ([merge request](gitlab-org/omnibus-gitlab!6198))

### Fixed (3 changes)

- [Ensure Omnibus Docker image has exiftool deps](gitlab-org/omnibus-gitlab@30de86b06e7cf55d9a07963720b20c854e293d39) ([merge request](gitlab-org/omnibus-gitlab!6236))
- [Gracefully handle blank CPU information](gitlab-org/omnibus-gitlab@fa684b35d8fbb5bec34cf3aa80bb0b182ad3f6ad) ([merge request](gitlab-org/omnibus-gitlab!6230))
- [Reload Consul only if the service is enabled](gitlab-org/omnibus-gitlab@6ae828d4176e5be37653ef2d4d185a56819240a2) ([merge request](gitlab-org/omnibus-gitlab!6218))

### Changed (4 changes)

- [gitaly: Unconditionally ignore the gitconfig](gitlab-org/omnibus-gitlab@8508277a72b2d5e81c28e9956b5d541e2ebf55a1) ([merge request](gitlab-org/omnibus-gitlab!6245))
- [Remove svlogd filter from consul configuration](gitlab-org/omnibus-gitlab@b6ae0f59fb18037e92ecf5efc4973431ccb80706) ([merge request](gitlab-org/omnibus-gitlab!6154))
- [Update cacerts to 2022.07.19](gitlab-org/omnibus-gitlab@7d0650d92758e83d8f4b06164152d3b6bf7c29ae) ([merge request](gitlab-org/omnibus-gitlab!6232))
- [Set webhook as MailRoomm's default delivery strategy](gitlab-org/omnibus-gitlab@785f20c486c36ec4ba7205337a6145f94af08cd6) ([merge request](gitlab-org/omnibus-gitlab!6149))

### Removed (1 change)

- [Stop enabling Grafana for new installs](gitlab-org/omnibus-gitlab@0ae2fb20e78c769e59e78229b2b09ebc1f0f9cbf) ([merge request](gitlab-org/omnibus-gitlab!6271))

### Security (3 changes)

- [Update libxslt from 1.1.32 to 1.1.35](gitlab-org/omnibus-gitlab@13db4d38c377c5e7be6bdee249cab5a1989b5028) ([merge request](gitlab-org/omnibus-gitlab!6249))
- [Upgrade bzip2 to use version 1.0.8](gitlab-org/omnibus-gitlab@013b8b94479a9c8baa33fec5835fec2fca4a71a5)
- [Bump exiftool version to 12.42](gitlab-org/omnibus-gitlab@9fb6f2f8297f975fa2413ccf1ecd48b1b5990b06)

### Other (6 changes)

- [Update erubi from 1.10.0 to 1.11.0](gitlab-org/omnibus-gitlab@e1f2b452c877ff5a8d7693f27e12206514ee5e7a) ([merge request](gitlab-org/omnibus-gitlab!6256))
- [Update rack from 2.2.3 to 2.2.4](gitlab-org/omnibus-gitlab@081dcfbc1d78d992e21a07c7c51b993574b1dbd9) ([merge request](gitlab-org/omnibus-gitlab!6255))
- [Use updated syntax in OpenSSL::Digest](gitlab-org/omnibus-gitlab@434514b2192b9511d3d9d2deb1f22abf500eb3a7) ([merge request](gitlab-org/omnibus-gitlab!6254))
- [Use rubygems bundled with ruby language](gitlab-org/omnibus-gitlab@c16b20b5c433a8605075bacb2903a07fd5bf5f2d) ([merge request](gitlab-org/omnibus-gitlab!6242))
- [Use official sha256 as checksum for cacerts](gitlab-org/omnibus-gitlab@576a8c296da6b2b89ac684d014c1192c4b13c50b) ([merge request](gitlab-org/omnibus-gitlab!6251))
- [Add GITLAB_METRICS_EXPORTER_VERSION for releases](gitlab-org/omnibus-gitlab@25b3c469015ae487fa390cf5cae567f06f1df288) ([merge request](gitlab-org/omnibus-gitlab!6222))

## 15.2.5 (2022-09-29)

### Security (3 changes)

- [Mattermost security release for 2022-08](gitlab-org/security/omnibus-gitlab@3d5112f1e3f9bbcf3a495cf0cd81245ef4edf6de) ([merge request](gitlab-org/security/omnibus-gitlab!242))
- [Apply Grafana CVE-2022-3110 patch](gitlab-org/security/omnibus-gitlab@63099fde11ae26ff9d74d6f28f8ff7e83596a414) ([merge request](gitlab-org/security/omnibus-gitlab!238))
- [Pass necessary headers on accessing healthcheck endpoints](gitlab-org/security/omnibus-gitlab@0b1f054956091d6fe9ea6fc4f613db863ac5e4a2) ([merge request](gitlab-org/security/omnibus-gitlab!236))

## 15.2.4 (2022-08-30)

### Security (4 changes)

- [Update libxslt and libxml](gitlab-org/security/omnibus-gitlab@47ff9e8beb445fa7f14f9f7854c810c3fcabb217) ([merge request](gitlab-org/security/omnibus-gitlab!221))
- [Bump gitlab-exporter version to 11.18.2 to mitigate VULNDB-255039](gitlab-org/security/omnibus-gitlab@d77281ac01120901f40743427c8a18fc3cea7e4c) ([merge request](gitlab-org/security/omnibus-gitlab!231))
- [Update unzip to 6.0.27](gitlab-org/security/omnibus-gitlab@146bcbebe071444cdc46f3ab9566cc86c24454f0) ([merge request](gitlab-org/security/omnibus-gitlab!227))
- [Bump nginx version to 1.20.2](gitlab-org/security/omnibus-gitlab@6327df5fba9e4e26b2bbf48f025169e0cc367b87) ([merge request](gitlab-org/security/omnibus-gitlab!223))

## 15.2.3 (2022-08-22)

No changes.

## 15.2.2 (2022-08-01)

### Fixed (1 change)

- [Gracefully handle blank CPU information](gitlab-org/omnibus-gitlab@d95763e7c02ad78300ba41a8f2526dee86b8e5cd) ([merge request](gitlab-org/omnibus-gitlab!6234))

## 15.2.1 (2022-07-28)

### Security (2 changes)

- [Bump exiftool version to 12.42](gitlab-org/security/omnibus-gitlab@53294ab72ff4ce07edbb1028e5311ff49196c378) ([merge request](gitlab-org/security/omnibus-gitlab!211))
- [Upgrade bzip2 to use version 1.0.8](gitlab-org/security/omnibus-gitlab@ff77949fc27633df0b9a8c5ad478133c650e5a94) ([merge request](gitlab-org/security/omnibus-gitlab!210))

## 15.2.0 (2022-07-21)

### Added (6 changes)

- [gitaly: Reintroduce migration to `[[git.config]]` stanzas](gitlab-org/omnibus-gitlab@4bf3bf85045cd94373184761e6f9a3b7fb6cd7cd) ([merge request](gitlab-org/omnibus-gitlab!6186))
- [Add praefect list-storages subcommand](gitlab-org/omnibus-gitlab@e0e0b0ebf8db5893cb543a2bfa9c57ffa564c560) ([merge request](gitlab-org/omnibus-gitlab!6147))
- [Add [gitlab] section to praefect config toml](gitlab-org/omnibus-gitlab@e9b444b63e690b1dc4d573ae37a40c7408b76a85) ([merge request](gitlab-org/omnibus-gitlab!6146))
- [Make gitlab-pages redirects limits configurable](gitlab-org/omnibus-gitlab@e5cfe22be99037081aedb4d45b1f63c718329050) by @nejc ([merge request](gitlab-org/omnibus-gitlab!6144))
- [Add TLS support for dedicated metrics servers](gitlab-org/omnibus-gitlab@d8558c80fe9c234b0fa7e1769a8403922e1706c4) ([merge request](gitlab-org/omnibus-gitlab!6155))
- [Add failover timeout to Praefect config](gitlab-org/omnibus-gitlab@ebddd96305ab24b46a630f16d85ac269c4e43087) ([merge request](gitlab-org/omnibus-gitlab!6150))

### Fixed (8 changes)

- [Ensure FIPS builds are EE](gitlab-org/omnibus-gitlab@0efee70f93086181fdc652be3f6d5b72686ff9c0) ([merge request](gitlab-org/omnibus-gitlab!6217))
- [Adjust worker processes to use real CPUs instead of cores](gitlab-org/omnibus-gitlab@182bc46016c73f5a9a2d39d676e7ed8eff811322) ([merge request](gitlab-org/omnibus-gitlab!6210))
- [Ensure Ruby platform is set globally on ARM64 OSes](gitlab-org/omnibus-gitlab@ad98bf31735ba0242d8c3376eaca335c143b3c09) ([merge request](gitlab-org/omnibus-gitlab!6208))
- [Fix worker processes not starting up due to 0 processes](gitlab-org/omnibus-gitlab@fb8549a22789347424ef6ba0454573c532ea2aa9) ([merge request](gitlab-org/omnibus-gitlab!6192))
- [Properly escape S3 credentials in Workhorse config TOML](gitlab-org/omnibus-gitlab@cafff1b049296de9c2822f45be02f86c473dac48) ([merge request](gitlab-org/omnibus-gitlab!6187))
- [Fix KAS address when running GitLab on a relative URL](gitlab-org/omnibus-gitlab@059115935b3cd6a2ab309452401f000af9811081) by @paddy-hack ([merge request](gitlab-org/omnibus-gitlab!6185))
- [Force nginx proxy to use IPv4](gitlab-org/omnibus-gitlab@11e43467114a1aabe42e21d3936328909a6e0140) ([merge request](gitlab-org/omnibus-gitlab!6143))
- [Fix DISABLE_PUMA_WORKER_KILLER env var check](gitlab-org/omnibus-gitlab@05c1e99593b8f3b2e3b44298d4fe34ae84ad5947) ([merge request](gitlab-org/omnibus-gitlab!6173))

### Changed (13 changes)

- [Configure local Gemfile before force_ruby_platform](gitlab-org/omnibus-gitlab@8415a921304f68f4a75e28e8130e7f52199c78e1) by @vincent_stchu ([merge request](gitlab-org/omnibus-gitlab!6207))
- [Update to openssl 1.1.1q](gitlab-org/omnibus-gitlab@52727ac1bbf405da7d5a1ca3a49e4bfe8aa638eb) ([merge request](gitlab-org/omnibus-gitlab!6215))
- [Update gitlab-org/container-registry from v3.51.0-gitlab to v3.51.1-gitlab](gitlab-org/omnibus-gitlab@093e518deffad656af8b8c9832dd83f6f4282586) ([merge request](gitlab-org/omnibus-gitlab!6214))
- [Update acme-client to 2.0.11](gitlab-org/omnibus-gitlab@e3b88da7fa0899ac29274140b24c0288741047a5) ([merge request](gitlab-org/omnibus-gitlab!6131))
- [Update to openssl 1.1.1p](gitlab-org/omnibus-gitlab@54bedc1dac06571c5fbb1d9417fd2afdd7e1da6a) ([merge request](gitlab-org/omnibus-gitlab!6176))
- [Update container registry to 3.51.0](gitlab-org/omnibus-gitlab@a362b10c0cb9c1d78d752654147daa4bd956ab6e) ([merge request](gitlab-org/omnibus-gitlab!6194))
- [Set force_ruby_platform to true locally for Gitaly and GitLab Rails](gitlab-org/omnibus-gitlab@628f5581dd6802296ae75b564a999a56977656fa) ([merge request](gitlab-org/omnibus-gitlab!6212))
- [Update jemalloc from 5.2.1 to 5.3.0](gitlab-org/omnibus-gitlab@7a82726701f97f68218523ebc2f2d12835a8195e) ([merge request](gitlab-org/omnibus-gitlab!6085))
- [Bump Container Registry to v3.49.0-gitlab](gitlab-org/omnibus-gitlab@519dfca3677913699d1914c65ef08cfea4517083) ([merge request](gitlab-org/omnibus-gitlab!6181))
- [Disable KAS by default in FIPS environments](gitlab-org/omnibus-gitlab@96406491400f7d975cf6772050c09b3c6c07b817) ([merge request](gitlab-org/omnibus-gitlab!6184))
- [Disable doc generation in grpc gem compilation for FIPS builds](gitlab-org/omnibus-gitlab@640ef48f3be8dfbf38667e8d0a728b0ba27bd92d) ([merge request](gitlab-org/omnibus-gitlab!6177))
- [gitaly: Migrate to inject Git configuration via `config.toml`](gitlab-org/omnibus-gitlab@2727686d248cffa6c3883f9daa8e0d02c479b11b) ([merge request](gitlab-org/omnibus-gitlab!6128))
- [Add dry run option to registry-garbage-collect command.](gitlab-org/omnibus-gitlab@44bf128b02deff84e89611bdc90e0f66748c6537) ([merge request](gitlab-org/omnibus-gitlab!6145))

### Deprecated (1 change)

- [global: Remove deprecated `self_signed_cert` setting](gitlab-org/omnibus-gitlab@0021a2c1e28ded37c428b4f3ee4d10abf6099840) ([merge request](gitlab-org/omnibus-gitlab!6196))

## 15.1.6 (2022-08-30)

### Security (5 changes)

- [Update libxslt and libxml](gitlab-org/security/omnibus-gitlab@829e0c7c007d0fe9120c06609e6569f42433405a) ([merge request](gitlab-org/security/omnibus-gitlab!220))
- [Upgrade mattermost to use version 6.7.1](gitlab-org/security/omnibus-gitlab@6dad6fd8d5123dca58290b63f4eaf3f68a992fb8) ([merge request](gitlab-org/security/omnibus-gitlab!213))
- [Bump gitlab-exporter version to 11.18.2 to mitigate VULNDB-255039](gitlab-org/security/omnibus-gitlab@4374bc384c8626e1a635435efc8804ebfce284cb) ([merge request](gitlab-org/security/omnibus-gitlab!230))
- [Update unzip to 6.0.27](gitlab-org/security/omnibus-gitlab@7b0997e0350cee1b8cefc8106c566e1be9c25721) ([merge request](gitlab-org/security/omnibus-gitlab!226))
- [Bump nginx version to 1.20.2](gitlab-org/security/omnibus-gitlab@20647e2748f1f7b5f4b029a0d122ac8ce4ed4428) ([merge request](gitlab-org/security/omnibus-gitlab!224))

## 15.1.5 (2022-08-22)

No changes.

## 15.1.4 (2022-07-28)

### Security (2 changes)

- [Bump exiftool version to 12.42](gitlab-org/security/omnibus-gitlab@85a6446d5aea2c353231abed1c2ff411c7d5e66d) ([merge request](gitlab-org/security/omnibus-gitlab!206))
- [Upgrade bzip2 to use version 1.0.8](gitlab-org/security/omnibus-gitlab@1e84e9ed015def9f34e5c107f91a275ac9042917) ([merge request](gitlab-org/security/omnibus-gitlab!209))

## 15.1.3 (2022-07-19)

### Fixed (3 changes)

- [Adjust worker processes to use real CPUs instead of cores](gitlab-org/omnibus-gitlab@056ba003d899862c5d251b83e050a33d59e6b1eb) ([merge request](gitlab-org/omnibus-gitlab!6216))
- [Ensure Ruby platform is set globally for arm64 based operating systems](gitlab-org/omnibus-gitlab@b65a681a3c123969e18b6c311c38e9c8cb64c791) ([merge request](gitlab-org/omnibus-gitlab!6216))
- [Fix worker processes not starting up due to 0 processes](gitlab-org/omnibus-gitlab@143e340f82bc34439b88a835c2597d28537cac25) ([merge request](gitlab-org/omnibus-gitlab!6216))

### Changed (1 change)

- [Set force_ruby_platform to true locally for Gitaly and GitLab Rails](gitlab-org/omnibus-gitlab@4bc3f6259284c298ecac94f9d27516dc7bec7681) ([merge request](gitlab-org/omnibus-gitlab!6216))

## 15.1.2 (2022-07-05)

No changes.

## 15.1.1 (2022-06-30)

No changes.

## 15.1.0 (2022-06-21)

### Added (1 change)

- [Add gitlab_rails['cdn_host'] setting](gitlab-org/omnibus-gitlab@456dda0db813e0d3baae01642497a33c61cf714c) ([merge request](gitlab-org/omnibus-gitlab!6096))

### Fixed (4 changes)

- [Handle standby leader nodes properly in pg-upgrade](gitlab-org/omnibus-gitlab@41383d3c89a82b067891114ac44996348ed7779c) ([merge request](gitlab-org/omnibus-gitlab!6036))
- [pgbouncer reload failure should provide insight](gitlab-org/omnibus-gitlab@0a09f57484a0053765cd729bea834c06a7096ded) ([merge request](gitlab-org/omnibus-gitlab!6127))
- [Skip auto-restart of PG during reconfigure as part of pg-upgrade](gitlab-org/omnibus-gitlab@817c0fea370a1aceeffd9f5ef539bfed96cb00e1) ([merge request](gitlab-org/omnibus-gitlab!6122))
- [redis: Add announce_ip_from_hostname support to sentinel](gitlab-org/omnibus-gitlab@eca430a9af3daf04379ca43d4b851c3a72f57caf) ([merge request](gitlab-org/omnibus-gitlab!6101))

### Changed (6 changes)

- [Update GitLab Omnibus Builder to v3.5.0](gitlab-org/omnibus-gitlab@9b0c9d8d7f189f69dcd9de9c312bdc170692ba35) ([merge request](gitlab-org/omnibus-gitlab!6142))
- [nginx: Disable request buffering by default for gitlab project imports](gitlab-org/omnibus-gitlab@4b0e528ea58766d6a4faaeeada4523b765e3edb0) by @mirsal ([merge request](gitlab-org/omnibus-gitlab!6117))
- [Turn off proxy_buffering for KAS](gitlab-org/omnibus-gitlab@8ebacd1fa1fd09c9e351959e296ec379572ce45e) ([merge request](gitlab-org/omnibus-gitlab!6136))
- [Update libtiff/libtiff from 4.3.0 to 4.4.0](gitlab-org/omnibus-gitlab@df4acda97c4dd8407d31f40ebbef26b06cd61508) ([merge request](gitlab-org/omnibus-gitlab!6125))
- [Update chef-acme to 4.1.5](gitlab-org/omnibus-gitlab@fa354561697820b58c2fa146995a43d628e05fb7) ([merge request](gitlab-org/omnibus-gitlab!6095))
- [Add frame-pointer support to zlib](gitlab-org/omnibus-gitlab@48a3d020e3053cdff44d0c16b19ff5d722796cb4) ([merge request](gitlab-org/omnibus-gitlab!6104))

### Deprecated (1 change)

- [Gitaly: update cgroups configuration](gitlab-org/omnibus-gitlab@05fc776f1173b0d35d677a5017c69daffc6d4d75) ([merge request](gitlab-org/omnibus-gitlab!6076))

### Removed (2 changes)

- [gitaly: Remove configuration for Rugged's gitconfig search path](gitlab-org/omnibus-gitlab@279eb2fe4866817f2621611d9b42af83ea7c8484) ([merge request](gitlab-org/omnibus-gitlab!6105))
- [Remove geo_file_download_dispatch_worker_cron settings](gitlab-org/omnibus-gitlab@e90dbef21f156021bed3d18f2c7a139e6948df46) ([merge request](gitlab-org/omnibus-gitlab!6106))

### Security (1 change)

- [Update to Redis v6.2.7](gitlab-org/omnibus-gitlab@0409a6a11d8a1585fe38895125bb22edf9170105) ([merge request](gitlab-org/omnibus-gitlab!6069))

### Performance (1 change)

- [Upgrade to bundler v2.3.15](gitlab-org/omnibus-gitlab@28c48c44d5c14511086aab54da3cf751d03810e4) ([merge request](gitlab-org/omnibus-gitlab!6139))

### Other (1 change)

- [Disallow bundle to any changes to Gemfile.lock](gitlab-org/omnibus-gitlab@cd4f464c27058bebc0033ed2e013c56e86ff38f1) ([merge request](gitlab-org/omnibus-gitlab!6090))

## 15.0.5 (2022-07-28)

### Security (2 changes)

- [Bump exiftool version to 12.42](gitlab-org/security/omnibus-gitlab@0564b3878692dc21c8eea0785ce3d95cccb05e0f) ([merge request](gitlab-org/security/omnibus-gitlab!207))
- [Upgrade bzip2 to use version 1.0.8](gitlab-org/security/omnibus-gitlab@5b9c29a2db9b49df87e1bdcf861cc4005e56cd78) ([merge request](gitlab-org/security/omnibus-gitlab!208))

## 15.0.4 (2022-06-30)

No changes.

## 15.0.3 (2022-06-16)

### Performance (1 change)

- [Upgrade to bundler v2.3.15](gitlab-org/omnibus-gitlab@f722fa80e725a028e54f7b800f0df832dab210fb) ([merge request](gitlab-org/omnibus-gitlab!6157))

## 15.0.2 (2022-06-06)

### Fixed (1 change)

- [Skip auto-restart of PG during reconfigure as part of pg-upgrade](gitlab-org/omnibus-gitlab@d4eb21d6a9406be4812c0ab5539f522cf7eeaefb) ([merge request](gitlab-org/omnibus-gitlab!6135))

## 15.0.1 (2022-06-01)

No changes.

## 15.0.0 (2022-05-20)

### Added (7 changes)

- [Add ci_runners_stale_group_runners_prune_worker_cron setting](gitlab-org/omnibus-gitlab@4fe5c08204b54052fc0b9953873291ce82ff8e4b) ([merge request](gitlab-org/omnibus-gitlab!6094))
- [Add Praefect verifier deletion logic config option](gitlab-org/omnibus-gitlab@daa5197b5ea4a21b0bb38c877a3132eb81ef9d26) ([merge request](gitlab-org/omnibus-gitlab!6081))
- [Add option to configure Elasticsearch probe for gitlab-exporter](gitlab-org/omnibus-gitlab@9d6c7f4ad45e76f4c71bfad63212a6350ae38df8) ([merge request](gitlab-org/omnibus-gitlab!5960))
- [Add Puma config support for SSL](gitlab-org/omnibus-gitlab@4b4e52105948b2f2c22baae61872227702f91840) ([merge request](gitlab-org/omnibus-gitlab!6004))
- [Introduce redis.announce_ip_from_hostname option, to enable setting the hostname at runtime](gitlab-org/omnibus-gitlab@2c2aca3e2ecc2aa9ed3742ce7ee0f095cda55113) ([merge request](gitlab-org/omnibus-gitlab!6027))
- [Add observability listener configuration for KAS](gitlab-org/omnibus-gitlab@747fde2e41398f85a5ad36cdff6788dcd0c4fffe) ([merge request](gitlab-org/omnibus-gitlab!6066))
- [Expose Praefect's background verification config via gitlab.rb](gitlab-org/omnibus-gitlab@580a9007ac865785abd43ab54c0fea124c50c52f) ([merge request](gitlab-org/omnibus-gitlab!6044))

### Fixed (4 changes)

- [Only check listen address and port if both exporter and health checks are enabled](gitlab-org/omnibus-gitlab@b8c45ee89a40158cb3ad8d65975f06bc40c13448) ([merge request](gitlab-org/omnibus-gitlab!6086))
- [Remove Geo database settings only if some services are enabled](gitlab-org/omnibus-gitlab@10681dd601b9ab05ffd19ce1296918ac20063eb2) ([merge request](gitlab-org/omnibus-gitlab!6072))
- [Nginx: implement HSTS support in the mattermost configuration template](gitlab-org/omnibus-gitlab@217fa57d2822a434e8cbc57be7acf340552a8e0b) by @hcartiaux ([merge request](gitlab-org/omnibus-gitlab!6033))
- [Fix permissions on Grafana folder in Docker container](gitlab-org/omnibus-gitlab@0bdef8a586a56c78a2a2ef1301c21f9e1c807d81) by @cHiv0rz ([merge request](gitlab-org/omnibus-gitlab!6055))

### Changed (7 changes)

- [Update to PostgreSQL to v12.10 and v13.6](gitlab-org/omnibus-gitlab@b99198ae364b33c0a55543c226693b609bb0f0c6) ([merge request](gitlab-org/omnibus-gitlab!5728))
- [Update to OpenSSL 1.1.1o](gitlab-org/omnibus-gitlab@4b2b99524b5df302a4b125a56440ffafcbcd9b7c) ([merge request](gitlab-org/omnibus-gitlab!6080))
- [Change the sidekiq warning on using same address for healthcheck to raise an error instead](gitlab-org/omnibus-gitlab@d0b622e2c9e208a1bcb1dec76f350c49ba1d445d) ([merge request](gitlab-org/omnibus-gitlab!6065))
- [Delete code for deprecated geo commands](gitlab-org/omnibus-gitlab@4d61a7be8e9ede7082a0336a083cf450479c9b93) ([merge request](gitlab-org/omnibus-gitlab!6059))
- [Bump Container Registry to v3.39.2-gitlab](gitlab-org/omnibus-gitlab@1350edfdbc5af0851a9c88b3ca376af45b2f4619) ([merge request](gitlab-org/omnibus-gitlab!6064))
- [Bump BUILDER_IMAGE_REVISION to v3.3.1](gitlab-org/omnibus-gitlab@6b73a7ad96d88dd741abf8a631b952fa871f9598) ([merge request](gitlab-org/omnibus-gitlab!6056))
- [Remove AES256-GCM-SHA384 from default list of allowed NGINX SSL ciphers](gitlab-org/omnibus-gitlab@77238e0e6478308e6be709d557a63f404dd92efe) by @m.baur ([merge request](gitlab-org/omnibus-gitlab!5913))

### Removed (3 changes)

- [Remove background_upload and direct_upload configs](gitlab-org/omnibus-gitlab@6d841dc2d6d38c089fbe7fee025309c960f4ac94) ([merge request](gitlab-org/omnibus-gitlab!6091))
- [Remove cveignore file and references](gitlab-org/omnibus-gitlab@99e659f5c66b3356ba6fcdbaca5a874e2187a335) ([merge request](gitlab-org/omnibus-gitlab!6061))
- [gitaly: Remove support for configuring the internal socket directory](gitlab-org/omnibus-gitlab@0d5aaf031c3f03640cbdd8774ac9ce7b8b8650b4) ([merge request](gitlab-org/omnibus-gitlab!6068))

### Other (1 change)

- [Update deprecated settings list](gitlab-org/omnibus-gitlab@842cb755e72429663439b592c431b5d8cb7ffbc8) ([merge request](gitlab-org/omnibus-gitlab!6040))

## 14.10.5 (2022-06-30)

No changes.

## 14.10.4 (2022-06-01)

### Security (1 change)

- [Mattermost Security Updates May 2022](gitlab-org/security/omnibus-gitlab@0c61238d916a545b89f8d2d52a8996ce36b58bc5) ([merge request](gitlab-org/security/omnibus-gitlab!202))

## 14.10.3 (2022-05-20)

### Fixed (1 change)

- [Remove Geo database settings only if some services are enabled](gitlab-org/omnibus-gitlab@13366f11d2430307f13ad874305540c0f01c8782) ([merge request](gitlab-org/omnibus-gitlab!6103))

## 14.10.2 (2022-05-04)

### Other (1 change)

- [Update deprecations for 15.0](gitlab-org/omnibus-gitlab@a16dc47312d81f47875cbbf960291234f77b0737) ([merge request](gitlab-org/omnibus-gitlab!6075))

## 14.10.1 (2022-04-29)

No changes.

## 14.10.0 (2022-04-21)

### Added (3 changes)

- [Gitaly: Add rate_limiting section to config toml](gitlab-org/omnibus-gitlab@89d8f26a49063b1ec55b613d139e6de4f081e3ab) ([merge request](gitlab-org/omnibus-gitlab!6023))
- [Add pages http server timeout options](gitlab-org/omnibus-gitlab@50ba3875f12a5c7e754e1c9d13162cfe3d3e588d) ([merge request](gitlab-org/omnibus-gitlab!6029))
- [Expose `db_database_tasks` attribute](gitlab-org/omnibus-gitlab@c17057d17fbefeccef1f93768b4d90414e10e8ed) ([merge request](gitlab-org/omnibus-gitlab!5982))

### Fixed (3 changes)

- [consul: Disable logging of timestamps if JSON log enabled](gitlab-org/omnibus-gitlab@d376b30f25472a4c09e317135495b8a41af4c040) ([merge request](gitlab-org/omnibus-gitlab!6034))
- [ruby: Enable OPENSSL_FIPS macro for system SSL builds](gitlab-org/omnibus-gitlab@cb0137add87ad37aa266a05f30313a1cd32ffb63) ([merge request](gitlab-org/omnibus-gitlab!6030))
- [Always disable proxy_intercept_errors for kas](gitlab-org/omnibus-gitlab@2c76574dc69483a8c41bdadda3a0a83e810422f8) ([merge request](gitlab-org/omnibus-gitlab!5995))

### Changed (5 changes)

- [Update Mattermost to 6.5.0](gitlab-org/omnibus-gitlab@090603d39ddf8ebfe64ece70e6019e2d9779a084) by @stavros.foteinopoulos ([merge request](gitlab-org/omnibus-gitlab!5996))
- [gitaly: Set up newly introduced runtime directory](gitlab-org/omnibus-gitlab@00534f346f11d02a5fe550257f5424b6e998bee1) ([merge request](gitlab-org/omnibus-gitlab!5999))
- [Migrate Geo Tracking database configuration into database.yml](gitlab-org/omnibus-gitlab@4b88e899ecb99a0c0eef9dec8ef7b9df2903f2d0) ([merge request](gitlab-org/omnibus-gitlab!5962))
- [add pages zip http client timeout option](gitlab-org/omnibus-gitlab@d6d0a17bc97505ff12205b05b943cf2ec355f02c) ([merge request](gitlab-org/omnibus-gitlab!5975))
- [Update Mattermost to 6.4.2](gitlab-org/omnibus-gitlab@0e2ebff67f9ccf71c8d5f93d1f2c5893683d1809) by @stylianosrigas ([merge request](gitlab-org/omnibus-gitlab!5966))

### Security (3 changes)

- [mark credentials as sensitive](gitlab-org/omnibus-gitlab@9354ccc5d43df012eaacf46029e67ff4ecc2d482) ([merge request](gitlab-org/omnibus-gitlab!5971))
- [Upgrade zlib version](gitlab-org/omnibus-gitlab@056875b6497087a33fa837e5549baa1ecea33674) by @srslypascal ([merge request](gitlab-org/omnibus-gitlab!6015))
- [Update grafana version to 7.5.15](gitlab-org/omnibus-gitlab@5e98cbfb95cc3176fbaf5f38de99775d9cae512e)

## 14.9.5 (2022-06-01)

### Security (1 change)

- [Mattermost Security Updates May 2022](gitlab-org/security/omnibus-gitlab@04aba5468f2a0a7b1f52f7ec755d08ecf5859b22) ([merge request](gitlab-org/security/omnibus-gitlab!203))

## 14.9.4 (2022-04-29)

### Security (1 change)

- [Upgrade zlib version](gitlab-org/security/omnibus-gitlab@22de3296bc229d7812d1adb0de8b846390ca494b) ([merge request](gitlab-org/security/omnibus-gitlab!200))

## 14.9.3 (2022-04-12)

No changes.

## 14.9.2 (2022-03-31)

### Security (2 changes)

- [Update Mattermost version](gitlab-org/security/omnibus-gitlab@8f0ca9426e8c2226c715ee7adff9a93c147f1f00) ([merge request](gitlab-org/security/omnibus-gitlab!193))
- [Update grafana version to 7.5.15](gitlab-org/security/omnibus-gitlab@838321a59c0824d3d66d1e52f45b1ba2cd660c33) ([merge request](gitlab-org/security/omnibus-gitlab!196))

## 14.9.1 (2022-03-23)

No changes.

## 14.9.0 (2022-03-21)

### Added (9 changes)

- [Make GitLab Pages server shutdown timeout configurable](gitlab-org/omnibus-gitlab@ad23a2ae7fd982edf5cb82559bbd02868806bd13) by @HuseyinEmreAksoy ([merge request](gitlab-org/omnibus-gitlab!5965))
- [Exclude unnecessary files in gitlab-grpc gem](gitlab-org/omnibus-gitlab@7d8542a247df1245b81211a0ad500b7c3bd84cfc) ([merge request](gitlab-org/omnibus-gitlab!5968))
- [Add webhook delivery method to mailroom](gitlab-org/omnibus-gitlab@c5b5872edf9a32615cbdc23ae992441c4cddc054) ([merge request](gitlab-org/omnibus-gitlab!5927))
- [Add possibility to change nginx proxy buffer size](gitlab-org/omnibus-gitlab@6a680200bb6d52c2211f0db21ee5f0c53bb1a466) ([merge request](gitlab-org/omnibus-gitlab!5930))
- [Add gitlab_kas['log_level'] customization](gitlab-org/omnibus-gitlab@68986fe1a6e4b2589a53bd3ed1ae2107d19cf2f5) ([merge request](gitlab-org/omnibus-gitlab!5921))
- [Add bizible settings](gitlab-org/omnibus-gitlab@a9e9df87ecb223b0c4f233ca41d36a22b061a854) ([merge request](gitlab-org/omnibus-gitlab!5911))
- [Add tls rate-limiting options for GitLab Pages](gitlab-org/omnibus-gitlab@aa77e638d3dc491f9e96ca0ce3d67602f0f53610) ([merge request](gitlab-org/omnibus-gitlab!5926))
- [Add role for Spamcheck](gitlab-org/omnibus-gitlab@e366c575f4b46fe54a1ade3afa947189ef949fdf) ([merge request](gitlab-org/omnibus-gitlab!5893))
- [Add gitaly concurrency queue limit configs](gitlab-org/omnibus-gitlab@0c6c4ec78e570565b7c0833fcc6075e1c584c2e4) ([merge request](gitlab-org/omnibus-gitlab!5892))

### Fixed (4 changes)

- [Allow ACME challenge over HTTPS](gitlab-org/omnibus-gitlab@45eed63f3d42fa269e4ea9778547c4b60c89f8c1) ([merge request](gitlab-org/omnibus-gitlab!5916))
- [Enable C99 in CentOS 7 and SLES for building Git](gitlab-org/omnibus-gitlab@7656cc049abb180f4bfc9b3d8f6f805161354762) ([merge request](gitlab-org/omnibus-gitlab!5948))
- [gitlab-redis-cli: Fix passing of args to redis-cli](gitlab-org/omnibus-gitlab@7e1ff775cf4034a5aeaa8167a956cf9c0640b1a1) ([merge request](gitlab-org/omnibus-gitlab!5929))
- [Fix Gitaly max_queue_wait TOML config](gitlab-org/omnibus-gitlab@4652c08bd215f8c51d6f4bb0d1884a132e287f2d) ([merge request](gitlab-org/omnibus-gitlab!5935))

### Changed (5 changes)

- [Upgrade MailRoom to v0.0.20](gitlab-org/omnibus-gitlab@5f505cde8a1801387981410b397c8ea92ef6eadb) ([merge request](gitlab-org/omnibus-gitlab!5978))
- [Bump BUILDER_IMAGE_REVISION to v2.14.0](gitlab-org/omnibus-gitlab@162d3862b648d368f2e7942cb2ec21e411af145f) ([merge request](gitlab-org/omnibus-gitlab!5972))
- [Default enable separate metrics for Praefect](gitlab-org/omnibus-gitlab@fa7c52e32eb27e831855c872e2402af5436ff673) ([merge request](gitlab-org/omnibus-gitlab!5887))
- [Bump Container Registry to v3.31.0-gitlab](gitlab-org/omnibus-gitlab@3c267261bdc4b5d5a12208811d3b42b439e6eafa) ([merge request](gitlab-org/omnibus-gitlab!5944))
- [gitaly: enable bundled git as default and set a default binary](gitlab-org/omnibus-gitlab@b157bbe564298b47c136507d13a2996a5ab4823d) ([merge request](gitlab-org/omnibus-gitlab!5885))

### Security (5 changes)

- [Update OpenSSL to v1.1.1n](gitlab-org/omnibus-gitlab@5a4dcf2bcb7d361029760ced56c0b13c07eb3e7c) ([merge request](gitlab-org/omnibus-gitlab!5979))
- [Verifies full certificate rather than just CA](gitlab-org/omnibus-gitlab@9e005c447ac13549aef71c778103f5cd589304ed) ([merge request](gitlab-org/omnibus-gitlab!5963))
- [Update Bundler version to 2.2.33](gitlab-org/omnibus-gitlab@82e3d3e2618569de796a823dd1b93231d71ad4d7) ([merge request](gitlab-org/omnibus-gitlab!5889))
- [Upgrade gitlab-exporter to 11.11.0](gitlab-org/omnibus-gitlab@07fd1058c347a69177e4fa7bf879dbf88a4b1d56) ([merge request](gitlab-org/omnibus-gitlab!5915))
- [Upgrade gitlab-exporter to 11.10.0](gitlab-org/omnibus-gitlab@a54f42c2fec705774602efe7df9a48a4c45c2745) ([merge request](gitlab-org/omnibus-gitlab!5898))

### Other (3 changes)

- [Improve success message after promoting secondary nodes](gitlab-org/omnibus-gitlab@d19ed935875778233151fe9b19a07134d757f133) ([merge request](gitlab-org/omnibus-gitlab!5959))
- [Enable live stdout/stderr](gitlab-org/omnibus-gitlab@ae79d717a0f7735442463ec65121b1b19b67ec8a) ([merge request](gitlab-org/omnibus-gitlab!5958))
- [Update Mattermost to 6.4.0](gitlab-org/omnibus-gitlab@2db39bba83bede1ec856b519289eb6f44b003882) by @angelos.kyratzakos ([merge request](gitlab-org/omnibus-gitlab!5919))

## 14.8.6 (2022-04-29)

### Security (1 change)

- [Upgrade zlib version](gitlab-org/security/omnibus-gitlab@a197f94fd54297077c02704cff9309ae8f2ad3ed) ([merge request](gitlab-org/security/omnibus-gitlab!199))

## 14.8.5 (2022-03-31)

### Security (2 changes)

- [Update Mattermost version](gitlab-org/security/omnibus-gitlab@3ceef837a8d28b68eced040158bbc70d2a7ec66b) ([merge request](gitlab-org/security/omnibus-gitlab!194))
- [Update grafana version to 7.5.15](gitlab-org/security/omnibus-gitlab@dd99aa32346b2074167e2b0168d4fad23fc76678) ([merge request](gitlab-org/security/omnibus-gitlab!192))

## 14.8.4 (2022-03-16)

### Security (1 change)

- [Update OpenSSL to v1.1.1n](gitlab-org/omnibus-gitlab@f20bc5b7ae7f093a302b08d5766d306b5ca22d2f) ([merge request](gitlab-org/omnibus-gitlab!5983))

## 14.8.3 (2022-03-14)

No changes.

## 14.8.2 (2022-02-25)

No changes.

## 14.8.1 (2022-02-23)

No changes.

## 14.8.0 (2022-02-21)

### Added (10 changes)

- [Add TLS configuration to Consul](gitlab-org/omnibus-gitlab@dd830bcbfca95ec5e17b828a47feeff68d5006fd) ([merge request](gitlab-org/omnibus-gitlab!5822))
- [Add TLS termination options to GitLab KAS's APIs](gitlab-org/omnibus-gitlab@be8062afe1c2ce2c63f2da9482e8f53ed4c41085) by @fh1ch ([merge request](gitlab-org/omnibus-gitlab!5852))
- [Add ability for Sentinel to leverage hostnames](gitlab-org/omnibus-gitlab@4875705279cc76daf430c8a0afcc3c266ca81782) ([merge request](gitlab-org/omnibus-gitlab!5853))
- [Adding Secure Files settings](gitlab-org/omnibus-gitlab@4624ab3e884eed2a3c274c6033b9ef55f2cca66d) ([merge request](gitlab-org/omnibus-gitlab!5857))
- [Add gitaly concurrency queue limit configs](gitlab-org/omnibus-gitlab@acb7b76c1a420db1cb8ef40da590eebee764f95e) ([merge request](gitlab-org/omnibus-gitlab!5875))
- [Add openssl FIPS runtime dependencies](gitlab-org/omnibus-gitlab@bf51384b2c781f7ed45b616c446fce539db49bb4) ([merge request](gitlab-org/omnibus-gitlab!5865))
- [Add sentry configuration options for GitLab KAS](gitlab-org/omnibus-gitlab@e7891deb3332c66ae40633624bf8ef7a48e2977c) by @fh1ch ([merge request](gitlab-org/omnibus-gitlab!5826))
- [Add GITLAB_SKIP_TAIL_LOGS to docker wrapper](gitlab-org/omnibus-gitlab@7002b2d742f0975e91cdf9eb7666d596c24cf1f9) by @jpflouret ([merge request](gitlab-org/omnibus-gitlab!5799))
- [Add spamcheck to the package](gitlab-org/omnibus-gitlab@ea23589a7eb867ba672840ddee15e8a56d6766d5) ([merge request](gitlab-org/omnibus-gitlab!5478))
- [Provide packages for SLES 15.2](gitlab-org/omnibus-gitlab@05a700957052ef254aac0d71366b6eff20df0c62) ([merge request](gitlab-org/omnibus-gitlab!5811))

### Fixed (6 changes)

- [Update MailRoom to v0.0.19](gitlab-org/omnibus-gitlab@3a0d4355d00f2a07092befc6971ae84ace1c2c71) ([merge request](gitlab-org/omnibus-gitlab!5905))
- [Update Omnibus to v8.2.1.7](gitlab-org/omnibus-gitlab@e051251228d494e784f712cd2dbf275827502ea6) ([merge request](gitlab-org/omnibus-gitlab!5902))
- [Fix nginx www directory permission](gitlab-org/omnibus-gitlab@13d546ef9e5229532d332e9b2adb5e606aed3444) by @JulianForster01 ([merge request](gitlab-org/omnibus-gitlab!5619))
- [Correct GitLab KAS default redis port configuration](gitlab-org/omnibus-gitlab@15d2c741574ae10f00beebd8f068a254a2abaace) by @fh1ch ([merge request](gitlab-org/omnibus-gitlab!5825))
- [Update PG runtime conf before restarting](gitlab-org/omnibus-gitlab@15d0d1f7aa69789e039bb527335b494605bcde8e) ([merge request](gitlab-org/omnibus-gitlab!5848))
- [Ensure EE services are added when gitlab-ee::config recipe is included](gitlab-org/omnibus-gitlab@57058af7fc324374845b890b95f383ecc7ae829d) ([merge request](gitlab-org/omnibus-gitlab!5861))

### Changed (16 changes)

- [Add QA_BRANCH trigger var](gitlab-org/omnibus-gitlab@c495e01de5bf8bd9c5ccb3fae514a1cc4a4653e2) ([merge request](gitlab-org/omnibus-gitlab!5910))
- [Update Mattermost to 6.3.3](gitlab-org/omnibus-gitlab@59859b16cc9f97959212364a2683bda18baca6c4) by @spirosoik ([merge request](gitlab-org/omnibus-gitlab!5884))
- [Bump Container Registry to v3.24.1-gitlab](gitlab-org/omnibus-gitlab@6a72ffff1458266fa679063bdb5c56d1e863fc87) ([merge request](gitlab-org/omnibus-gitlab!5899))
- [Update libjpeg-turbo/libjpeg-turbo from 2.1.0 to 2.1.2](gitlab-org/omnibus-gitlab@f48e3a506d123a3d234505d9ed32619ff13207b1) ([merge request](gitlab-org/omnibus-gitlab!5534))
- [Enable KAS by default](gitlab-org/omnibus-gitlab@518103b793791e87fa94739764f4f2fc5b8b879d) ([merge request](gitlab-org/omnibus-gitlab!4762))
- [gitaly: Install both external and bundled Git](gitlab-org/omnibus-gitlab@e68e455716a29ef9d104e394ebb27dbb56062f6d) ([merge request](gitlab-org/omnibus-gitlab!5874))
- [Update Mattermost to 6.2.2](gitlab-org/omnibus-gitlab@280d9a23f8fc00756f89ed6594fe773fb66341c6) by @spirosoik ([merge request](gitlab-org/omnibus-gitlab!5872))
- [Update config/software/prometheus.rb](gitlab-org/omnibus-gitlab@ae9ea0a5fc7506c30d74ee17afb5fceeb97b0c01) ([merge request](gitlab-org/omnibus-gitlab!5849))
- [Upgrade Redis from 6.0 to 6.2](gitlab-org/omnibus-gitlab@3b613f875b26bc3b84fd9a1427c71924d26a64ee) ([merge request](gitlab-org/omnibus-gitlab!5867))
- [Upgrade Redis from 6.0 to 6.2](gitlab-org/omnibus-gitlab@bfa25f3e8b363f18d5a8a3ff6778a50509abb82c) ([merge request](gitlab-org/omnibus-gitlab!5843))
- [Bump postgres-exporter to 0.10.0](gitlab-org/omnibus-gitlab@f620283eee40fd426eb715dc5021ae81697d88d5) ([merge request](gitlab-org/omnibus-gitlab!5850))
- [Bump redis-exporter to 1.33.0](gitlab-org/omnibus-gitlab@96861ec6d370720bbd8bd30b8078320e53ae5bea) ([merge request](gitlab-org/omnibus-gitlab!5850))
- [Bump node-exporter to 1.3.1](gitlab-org/omnibus-gitlab@e30165e8bb60d493b0bf38b0017a526097767b0e) ([merge request](gitlab-org/omnibus-gitlab!5850))
- [Bump Alertmanager to 0.23.0](gitlab-org/omnibus-gitlab@3aaa25efbefb49b43d146a8d3b92d3386035eaa5) ([merge request](gitlab-org/omnibus-gitlab!5850))
- [Bump Grafana to 7.5.12](gitlab-org/omnibus-gitlab@4b34583492911dc468caca801f1a67cd5784db20) ([merge request](gitlab-org/omnibus-gitlab!5850))

### Deprecated (1 change)

- [Add a warning if Sidekiq exporter and health checks are on the same port](gitlab-org/omnibus-gitlab@2f142b79d1c9d8a7cd879df736255ae223cffb2a) ([merge request](gitlab-org/omnibus-gitlab!5844))

## 14.7.7 (2022-03-31)

### Security (2 changes)

- [Update Mattermost version](gitlab-org/security/omnibus-gitlab@c79f7657299a014485d73154726e380ee838c3be) ([merge request](gitlab-org/security/omnibus-gitlab!195))
- [Update grafana version to 7.5.15](gitlab-org/security/omnibus-gitlab@bbf79c23818c10906577d4168be2c44949e8a26a) ([merge request](gitlab-org/security/omnibus-gitlab!191))

## 14.7.6 (2022-03-24)

### Security (1 change)

- [Update OpenSSL to v1.1.1n](gitlab-org/omnibus-gitlab@4021e806ff4db72e0e2b956f137cefb20d633078) ([merge request](gitlab-org/omnibus-gitlab!5986))

## 14.7.5 (2022-03-09)

No changes.

## 14.7.4 (2022-02-25)

### Security (2 changes)

- [Mattermost February security updates](gitlab-org/security/omnibus-gitlab@a33d088a428e9f390352cd971fc63afa2f8eb5c6) ([merge request](gitlab-org/security/omnibus-gitlab!186))
- [Bump Grafana to 7.5.12](gitlab-org/security/omnibus-gitlab@29c7f7f88385d3b0d822466f866feb43bfa92da5) ([merge request](gitlab-org/security/omnibus-gitlab!183))

## 14.7.3 (2022-02-15)

### Fixed (1 change)

- [Update Omnibus to v8.2.1.7](gitlab-org/omnibus-gitlab@0847ad87f499ad8312f2aaa7367b957165c0e341) ([merge request](gitlab-org/omnibus-gitlab!5907))

## 14.7.2 (2022-02-08)

### Fixed (1 change)

- [Ensure EE services are added when gitlab-ee::config recipe is included](gitlab-org/omnibus-gitlab@bb7a99e05274969671dd5e0e0d82abeb9b5644a3) ([merge request](gitlab-org/omnibus-gitlab!5886))

## 14.7.1 (2022-02-03)

No changes.

## 14.7.0 (2022-01-21)

### Added (6 changes)

- [Add Redis TLS related settings](gitlab-org/omnibus-gitlab@660586e7aefc5f38f8b6ec796b6f32e941388f28) ([merge request](gitlab-org/omnibus-gitlab!5770))
- [Add gossip encryption configuration to Consul](gitlab-org/omnibus-gitlab@b08ff3cf8139f4f99b6602189802cae07cd7a5e9) ([merge request](gitlab-org/omnibus-gitlab!5842))
- [Add domain rate-limiting options for GitLab Pages](gitlab-org/omnibus-gitlab@b2dd448cbe8c60960c10f3ac55a9c87a61fd0182) ([merge request](gitlab-org/omnibus-gitlab!5832))
- [Add packages to skip list in preinst](gitlab-org/omnibus-gitlab@66de9c6c839b2e7eb0bbcfda25db889a707ab8ad) ([merge request](gitlab-org/omnibus-gitlab!5837))
- [add nginx proxy_protocol option for gitlab-http](gitlab-org/omnibus-gitlab@f87ff7372d414bb97d9feb6f299fd81eb8a11000) by @cruelsmith ([merge request](gitlab-org/omnibus-gitlab!5663))
- [Add config support for container registry middleware](gitlab-org/omnibus-gitlab@bd43f9134fb4dc593b9d0433be31ebacfc50cc66) ([merge request](gitlab-org/omnibus-gitlab!5807))

### Fixed (4 changes)

- [Include the cert file location by default as well](gitlab-org/omnibus-gitlab@b6bdff0fa3b022a9be514e09315dd1ff78742dcd) ([merge request](gitlab-org/omnibus-gitlab!5839))
- [Sync trailing slash usage for GitLab KAS routes](gitlab-org/omnibus-gitlab@da816362ef00c62a569a0515d0aecd5ab84c1d04) by @fh1ch ([merge request](gitlab-org/omnibus-gitlab!5824))
- [Revert chef-acme cookbook update](gitlab-org/omnibus-gitlab@3a595ef7921a2273c387f32005599e6a72bcbd60) ([merge request](gitlab-org/omnibus-gitlab!5819))
- [Set SSL_CERT_DIR variable for all services](gitlab-org/omnibus-gitlab@ed9beda692797fa8e7b5576b47c30bd4285a1e0a) ([merge request](gitlab-org/omnibus-gitlab!5765))

### Changed (6 changes)

- [Bump omnibus to 8.2.1.5](gitlab-org/omnibus-gitlab@611add7bacd7e1108ad87eeb642055fc40e488fc) ([merge request](gitlab-org/omnibus-gitlab!5855))
- [Upgrade MailRoom to v0.0.18](gitlab-org/omnibus-gitlab@f37f798b2e09af0bcdf3e34b556784038bdd8d7a) ([merge request](gitlab-org/omnibus-gitlab!5816))
- [Enable frame pointer in PostgreSQL compile options](gitlab-org/omnibus-gitlab@129be61ae511cd6aeacce30bb73ef6b9b64b51a6) ([merge request](gitlab-org/omnibus-gitlab!5845))
- [Bump Container Registry to v3.21.0-gitlab](gitlab-org/omnibus-gitlab@1dd3ce09f351acaab237c5b8d6783128ec510363) ([merge request](gitlab-org/omnibus-gitlab!5827))
- [Create cgroup root directory on gitaly startup](gitlab-org/omnibus-gitlab@d1e09648b557d7a6d2349b354744e59f506d2a14) ([merge request](gitlab-org/omnibus-gitlab!5800))
- [Skip terraform_state in preinst backup](gitlab-org/omnibus-gitlab@8dc6af4771f9089fa69e11c8199150754ff0b2d8) ([merge request](gitlab-org/omnibus-gitlab!5336))

### Security (1 change)

- [* bump prometheus version to 2.25.2](gitlab-org/omnibus-gitlab@303c2b4d97066357bbffc607d23f0fa94771bb21)

### Other (1 change)

- [Update Mattermost to 6.2.1](gitlab-org/omnibus-gitlab@05a5869b18ab109fffb7d0723ab04cb6da68ecf9) by @hmhealey ([merge request](gitlab-org/omnibus-gitlab!5828))

## 14.6.7 (2022-03-31)

### Security (1 change)

- [Update OpenSSL to v1.1.1n](gitlab-org/omnibus-gitlab@8a4fdc5fa226e5f17c235dc49317d64cf4731d43) ([merge request](gitlab-org/omnibus-gitlab!6001))

## 14.6.6 (2022-03-01)

### Fixed (1 change)

- [Ensure EE services are added when gitlab-ee::config recipe is included](gitlab-org/omnibus-gitlab@b90e485b01e3ca821c27b8884aef09b08d91c1c8) ([merge request](gitlab-org/omnibus-gitlab!5940))

## 14.6.5 (2022-02-25)

### Security (2 changes)

- [Mattermost February security updates](gitlab-org/security/omnibus-gitlab@96536555ac828a91719b680a9b2ada22b5cd33da) ([merge request](gitlab-org/security/omnibus-gitlab!187))
- [Bump Grafana to 7.5.12](gitlab-org/security/omnibus-gitlab@ca5139ba89ff852bbbd2ffdca4e0985ad7e98e20) ([merge request](gitlab-org/security/omnibus-gitlab!184))

## 14.6.4 (2022-02-03)

### Security (2 changes)

- [Update builder image to use golang 1.16.12](gitlab-org/security/omnibus-gitlab@97046c4ab099e663032b5d62a4c232122f2ed237) ([merge request](gitlab-org/security/omnibus-gitlab!180))
- [Update Mattermost to 6.1.1 (GitLab 14.6)](gitlab-org/security/omnibus-gitlab@2832fe9da7658bdfae28818517afd9ca4c514a19) ([merge request](gitlab-org/security/omnibus-gitlab!178))

## 14.6.3 (2022-01-18)

### Fixed (1 change)

- [Revert chef-acme cookbook update](gitlab-org/omnibus-gitlab@387e132a3d8b2a3b25591e2a79102713f1ab3eb1) ([merge request](gitlab-org/omnibus-gitlab!5856))

## 14.6.2 (2022-01-11)

No changes.

## 14.6.1 (2022-01-04)

No changes.

## 14.6.0 (2021-12-21)

### Added (5 changes)

- [Add --replicate-immediately flag to Praefect track-repository subcommand](gitlab-org/omnibus-gitlab@d35e0cc3c47835532ed54561ee9e18dac43fec81) ([merge request](gitlab-org/omnibus-gitlab!5789))
- [Provide packages for Debian Bullseye](gitlab-org/omnibus-gitlab@9eeffc1dd5e5180d5015ce1bb557fc4eab0b0097) ([merge request](gitlab-org/omnibus-gitlab!5755))
- [Add apply flag to praefect remove-repository subcommand](gitlab-org/omnibus-gitlab@0dd3d51a5723a38492152029f1a7a0eb2993a74d) ([merge request](gitlab-org/omnibus-gitlab!5785))
- [Add google tag manager nonce config](gitlab-org/omnibus-gitlab@28d0da1135961c79e2ef008fcf0ee02ad71dc907) ([merge request](gitlab-org/omnibus-gitlab!5763))
- [Add health-checks settings keys for Sidekiq](gitlab-org/omnibus-gitlab@6c7393963f6ef7d005b58f36051e08682274f312) ([merge request](gitlab-org/omnibus-gitlab!5743))

### Fixed (4 changes)

- [Return early from trusted certificate handling if hashing/symlinking failed](gitlab-org/omnibus-gitlab@edbd9514bad14b6921b06423745067b4df52bb2d) ([merge request](gitlab-org/omnibus-gitlab!5788))
- [Fix Google Memorystore support for Action Cable](gitlab-org/omnibus-gitlab@bf959c1b8ead8dc076a7b255962e0028ddeb2013) ([merge request](gitlab-org/omnibus-gitlab!5753))
- [Move deprecation message to gitlabc-ctl commands](gitlab-org/omnibus-gitlab@6631b5f7f9b8c9d96e54dd643f79d65ce049e6af) ([merge request](gitlab-org/omnibus-gitlab!5739))
- [gitlab-ctl geo promote requires restart of puma and workhorse services](gitlab-org/omnibus-gitlab@56ce0d27ee550547eba5a49f882eccfc0feb73fc) ([merge request](gitlab-org/omnibus-gitlab!5738))

### Changed (8 changes)

- [Upgrade mailroom to v0.0.15](gitlab-org/omnibus-gitlab@936956c794a42ed6b13970a02be994c2cef4887d) ([merge request](gitlab-org/omnibus-gitlab!5794))
- [Add patch to prevent Python from building nis module in Debian 11](gitlab-org/omnibus-gitlab@90a2190d5c2d8e873c2d3288812daab239960e32) ([merge request](gitlab-org/omnibus-gitlab!5755))
- [Update gitlab-exporter to 11.8.0](gitlab-org/omnibus-gitlab@bd8a21e5b953cda735f1cb2f93215190a4f9f84e) ([merge request](gitlab-org/omnibus-gitlab!5759))
- [Merge branch 'add-redis-ssl-kas' into 'master'](gitlab-org/omnibus-gitlab@acfcd985c6fe2b8cbeb88b71e6bbd8e4afad46d5) ([merge request](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5632))
- [Update 2 dependencies from git](gitlab-org/omnibus-gitlab@1a408cb1d73f64dc3975bb9a0a2087667036849a) ([merge request](gitlab-org/omnibus-gitlab!5590))
- [Use `geo:site:role` rake task to retrieve node role for the promote command](gitlab-org/omnibus-gitlab@0cae546fd9c5d04b59dac44b468217b244541782) ([merge request](gitlab-org/omnibus-gitlab!5724))
- [Use public sources for omnibus-gitlab builds by default](gitlab-org/omnibus-gitlab@981e78d0162c8f202a38093ed5ead9ab059f07c7) ([merge request](gitlab-org/omnibus-gitlab!5659))
- [Build rugged gem with system SSL on FIPS builds](gitlab-org/omnibus-gitlab@da0a44b28982ea1399e060396e892932b7e430d1) ([merge request](gitlab-org/omnibus-gitlab!5592))

## 14.5.4 (2022-02-03)

### Security (2 changes)

- [Update builder image to use golang 1.16.12](gitlab-org/security/omnibus-gitlab@143f67f02155945c7b4b3ab1d32e7ea9d4534e77) ([merge request](gitlab-org/security/omnibus-gitlab!181))
- [Update Mattermost to 5.38.3](gitlab-org/security/omnibus-gitlab@0a5be862558b2737903df134525a662388cd9073) ([merge request](gitlab-org/security/omnibus-gitlab!179))

## 14.5.3 (2022-01-11)

No changes.

## 14.5.2 (2021-12-03)

### Security (1 change)

- [Bump Mattermost to 5.39.2](gitlab-org/security/omnibus-gitlab@3095b598767458e264db42d820c14784c8e46ec1) ([merge request](gitlab-org/security/omnibus-gitlab!163))

## 14.5.1 (2021-12-01)

### Fixed (1 change)

- [Fix Google Memorystore support for Action Cable](gitlab-org/omnibus-gitlab@2da850830b22ca01d7ee1449b9c7d505d6b4af43) ([merge request](gitlab-org/omnibus-gitlab!5764))

## 14.5.0 (2021-11-19)

### Added (11 changes)

- [Add praefect prometheus_exclude_database_from_default_metrics config value](gitlab-org/omnibus-gitlab@35d37fd96323b1846b43d1c75a722aabd7e8624b) ([merge request](gitlab-org/omnibus-gitlab!5740))
- [Build packages for openSUSE 15.3](gitlab-org/omnibus-gitlab@afdc5f3b699dbe64de56a290e0b87fb113a0ab1d) ([merge request](gitlab-org/omnibus-gitlab!5720))
- [Add max_uri_length to GitLab Pages config](gitlab-org/omnibus-gitlab@594675b8e1a25a09a612f4389f9a1bca4706869e) ([merge request](gitlab-org/omnibus-gitlab!5729))
- [Add source-IP rate-limiting options to GitLab Pages](gitlab-org/omnibus-gitlab@b19a99391f7c95fdcfd408e7ce22a887fc48fca3) ([merge request](gitlab-org/omnibus-gitlab!5704))
- [Configure the Loose foreign key cleanup job](gitlab-org/omnibus-gitlab@2cc32e21b28f3570946de2f522199bbcf964c519) ([merge request](gitlab-org/omnibus-gitlab!5708))
- [Add configuration for the KAS CI tunnel feature](gitlab-org/omnibus-gitlab@832b8fffe7a96a75d5ee745b514ac2cf1886e392) ([merge request](gitlab-org/omnibus-gitlab!5686))
- [Add praefect check command](gitlab-org/omnibus-gitlab@503df6dbed3949f4aadecc693bd395187f9906de) ([merge request](gitlab-org/omnibus-gitlab!5688))
- [Allow configuring redis instance for sessions](gitlab-org/omnibus-gitlab@182245701d498863b703265bce7dd24a5b5d44a3) ([merge request](gitlab-org/omnibus-gitlab!5690))
- [Create a Consul service for GitLab Exporter](gitlab-org/omnibus-gitlab@5aebc282f4e7d4b00e21c58a7e4ce7141d2336df) ([merge request](gitlab-org/omnibus-gitlab!5672))
- [Build and publish ARM64 AMIs](gitlab-org/omnibus-gitlab@997afab74ebb5b8fc03e6841444a8b3bef6e8d30) ([merge request](gitlab-org/omnibus-gitlab!5682))
- [Add one_trust_id configuration](gitlab-org/omnibus-gitlab@e71fd56e87e0a53a1b24178da12c037ee54785eb) ([merge request](gitlab-org/omnibus-gitlab!5655))

### Fixed (5 changes)

- [Drop --without-gnutls flag from curl](gitlab-org/omnibus-gitlab@98901806aa0b37db3356bc1d2197f5e6a0d3006f) ([merge request](gitlab-org/omnibus-gitlab!5730))
- [adding helper text for subcommands](gitlab-org/omnibus-gitlab@655b5ee078728978e5d3bec0450068b09ef94d91) ([merge request](gitlab-org/omnibus-gitlab!5706))
- [Fix URL for unzip v6.0 download](gitlab-org/omnibus-gitlab@08806a5686a469779151d330808397338b53c7bd) ([merge request](gitlab-org/omnibus-gitlab!5705))
- [Geo - Restart Gitaly/Praefect services during promotion](gitlab-org/omnibus-gitlab@3b4160fb40f2de6e4ac5dc37a6021e64ae23289c) ([merge request](gitlab-org/omnibus-gitlab!5691))
- [Ensure letsencrypt is enabled when running  gitlab-ctl renew-le-certs](gitlab-org/omnibus-gitlab@0821de816202aac0019a9ab04d453b38c3954561) ([merge request](gitlab-org/omnibus-gitlab!5681))

### Changed (11 changes)

- [Update grafana-dashboards to 1.9.0](gitlab-org/omnibus-gitlab@7c2bef94efe6694c03871ebcf607273dea5ef6b1) ([merge request](gitlab-org/omnibus-gitlab!5736))
- [Bump container registry to v3.14.3](gitlab-org/omnibus-gitlab@43ee251ea2a68d5194c09b6d74c33c160d62f335) ([merge request](gitlab-org/omnibus-gitlab!5727))
- [Upgrade gitlab-exporter to v11.7.0](gitlab-org/omnibus-gitlab@7268bf80da3cedcab04f3ad9481e13e17f031136) ([merge request](gitlab-org/omnibus-gitlab!5725))
- [Make gitlab-ctl geo promote production ready](gitlab-org/omnibus-gitlab@e2b9eb88b5a88ed767ccd61436a03832de315989) ([merge request](gitlab-org/omnibus-gitlab!5719))
- [Ensure the selinux modules are enabled on rocky and almalinux](gitlab-org/omnibus-gitlab@8896fe22315369add8ec8c40d91b8bd74cb59c36) ([merge request](gitlab-org/omnibus-gitlab!5714))
- [Bump container registry to v3.14.1](gitlab-org/omnibus-gitlab@bc9f23610f94e298d716371c648dcfe5e6e91c42) ([merge request](gitlab-org/omnibus-gitlab!5709))
- [Drop custom compiler for CentOS 6](gitlab-org/omnibus-gitlab@bc8099a15b45676f1e9a2cbaddee4707949d08b4) ([merge request](gitlab-org/omnibus-gitlab!5707))
- [Upgrade Omnibus Builder to v2.5.0](gitlab-org/omnibus-gitlab@187830c0c70711ce04633faecff7d7f7e9143685) ([merge request](gitlab-org/omnibus-gitlab!5701))
- [Bump omnibus to 8.2.1.1](gitlab-org/omnibus-gitlab@d94c515b9b312147e018de9d89502c087ee691ea) ([merge request](gitlab-org/omnibus-gitlab!5667))
- [Update gitlab-mail_room to 0.0.14](gitlab-org/omnibus-gitlab@70dbff79af988b760eb9844c8c5899395bbcb1fb) ([merge request](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5687))
- [Bump Container Registry to v3.13.0-gitlab](gitlab-org/omnibus-gitlab@98e6ec691071322a324fdf821db5ca5d8e379ac5) ([merge request](gitlab-org/omnibus-gitlab!5684))

### Removed (1 change)

- [Remove Action Cable in-app setting](gitlab-org/omnibus-gitlab@e23ce52074df3e69bf9357f8531be3e0efe432a4) ([merge request](gitlab-org/omnibus-gitlab!5700))

### Security (2 changes)

- [Update Curl to version 7.79.1](gitlab-org/omnibus-gitlab@5e1d27acf27eed44f9f69609cd19d21a8147ec74)
- [Update openssl to 1.1.1l](gitlab-org/omnibus-gitlab@f107290e750c4df586bb475ca537401eb46094e3)

## 14.4.5 (2022-01-11)

No changes.

## 14.4.4 (2021-12-03)

### Security (1 change)

- [Bump Mattermost to 5.39.2](gitlab-org/security/omnibus-gitlab@57bf68e0fe9f165641ea2d39a2ba785824cf49d3) ([merge request](gitlab-org/security/omnibus-gitlab!161))

## 14.4.3 (2021-12-01)

### Added (1 change)

- [Add praefect prometheus_exclude_database_from_default_metrics config value](gitlab-org/omnibus-gitlab@4be6a278a6401c70e0676d2f487b8752a30c41d7) ([merge request](gitlab-org/omnibus-gitlab!5762))

## 14.4.2 (2021-11-08)

### Added (1 change)

- [Build and publish ARM64 AMIs](gitlab-org/omnibus-gitlab@062aef7148073a8b336b5394a5b1b19bc75957c8) ([merge request](gitlab-org/omnibus-gitlab!5715))

### Fixed (1 change)

- [Fix URL for unzip v6.0 download](gitlab-org/omnibus-gitlab@85ca56906a376ff746a62c0054c9704cbac48116) ([merge request](gitlab-org/omnibus-gitlab!5715))

## 14.4.1 (2021-10-28)

### Security (2 changes)

- [Update Curl to version 7.79.1](gitlab-org/security/omnibus-gitlab@882a0b93e38669049aa13d824945010b6895a382) ([merge request](gitlab-org/security/omnibus-gitlab!154))
- [Update openssl to 1.1.1l](gitlab-org/security/omnibus-gitlab@22584f0661c4dba0103caf083f30bd818ec63537) ([merge request](gitlab-org/security/omnibus-gitlab!152))

## 14.4.0 (2021-10-21)

### Added (6 changes)

- [add list-untracked-repositories command](gitlab-org/omnibus-gitlab@e42713ef3a93df8050e78e12a1a95069ebd99c14) ([merge request](gitlab-org/omnibus-gitlab!5662))
- [Introduce praefect track-repository command](gitlab-org/omnibus-gitlab@c893910cb7c77262a3bf8740af91c9caa34e392e) ([merge request](gitlab-org/omnibus-gitlab!5658))
- [Allow configuring redis instance for rate-limiting](gitlab-org/omnibus-gitlab@b3d85c90f911018e9fa4e9f1aea5cfee3b312106) ([merge request](gitlab-org/omnibus-gitlab!5624))
- [Introduce "praefect remove-repository" command](gitlab-org/omnibus-gitlab@c19995c77e8383212fedd7c4520af0d27f1c7cec) ([merge request](gitlab-org/omnibus-gitlab!5614))
- [Add new max_saml_message_size setting](gitlab-org/omnibus-gitlab@5de647796be4bcbc1353bad94e1090263f95a7db) ([merge request](gitlab-org/omnibus-gitlab!5613))
- [Make Redis stop-writes-on-bgsave-error setting configurable](gitlab-org/omnibus-gitlab@573dd55e824acf91161b67e585a81a6c92fc669b) ([merge request](gitlab-org/omnibus-gitlab!5616))

### Fixed (4 changes)

- [Don't generate public_attributes.json on non-reconfigure runs](gitlab-org/omnibus-gitlab@890543e38b89031d927ed0539ddbf753959d5320) ([merge request](gitlab-org/omnibus-gitlab!5674))
- [Update cacerts to 2021-09-30](gitlab-org/omnibus-gitlab@a90a59323c72277275c67c12de4bb2a0aaa6db08) ([merge request](gitlab-org/omnibus-gitlab!5650))
- [Delay praefect database[_direct_host,_port_no_proxy] removals](gitlab-org/omnibus-gitlab@fb1b94a1e1cd7d93fe54b17b7d87facec781eb4f) ([merge request](gitlab-org/omnibus-gitlab!5647))
- [Properly reload Patroni on config change](gitlab-org/omnibus-gitlab@e1697c547a421073dad5961219e0106cd4915f9b) ([merge request](gitlab-org/omnibus-gitlab!5644))

### Changed (7 changes)

- [Update gitlab-mail_room to 0.0.14](gitlab-org/omnibus-gitlab@7ea548474c0e9ba8aa15ba09e3410df03a5aeffa) ([merge request](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5687))
- [Downgrade grafana to the 7.x release branch](gitlab-org/omnibus-gitlab@ea6bb0bf64a22f2ede0aec0bcbb74905345d3647) ([merge request](gitlab-org/omnibus-gitlab!5675))
- [Add timeout block for Consul get_api](gitlab-org/omnibus-gitlab@b7f63aca40675d1db85a672f4c2082e57c19eea8) ([merge request](gitlab-org/omnibus-gitlab!5638))
- [Bump omnibus to 8.2.1](gitlab-org/omnibus-gitlab@0b970c9ecea72097f8031a2f2138cd4f5fe2cc4b) ([merge request](gitlab-org/omnibus-gitlab!5602))
- [Switch to supporting the new ee/db/geo/structure.sql](gitlab-org/omnibus-gitlab@9e2f2a4ef1ab907e318c4a7137ae2b6db1603ea6) ([merge request](gitlab-org/omnibus-gitlab!5637))
- [Gracefully handle empty roles](gitlab-org/omnibus-gitlab@69ec50023de59a6a05c5fc81e2c5d400b3f84052) ([merge request](gitlab-org/omnibus-gitlab!5634))
- [Bump Container Registry to v3.11.1-gitlab](gitlab-org/omnibus-gitlab@2499016a479c3747c30eef8945955dd49273f2b2) ([merge request](gitlab-org/omnibus-gitlab!5623))

### Deprecated (1 change)

- [Deprecate Pages `inplace_chroot` flag and stop running Pages as a daemon](gitlab-org/omnibus-gitlab@ae3cdf3bf6846415391a765661090456a06ce32b) by @feistel ([merge request](gitlab-org/omnibus-gitlab!5639))

## 14.3.6 (2021-12-03)

### Security (1 change)

- [Bump Mattermost to 5.38.4](gitlab-org/security/omnibus-gitlab@28663f0c7a3fd084d461a836c6dbe53282008074) ([merge request](gitlab-org/security/omnibus-gitlab!162))

## 14.3.5 (2021-11-26)

### Added (1 change)

- [Add praefect prometheus_exclude_database_from_default_metrics config value](gitlab-org/omnibus-gitlab@29473df822968966dfc640a53d95be908998f389) ([merge request](gitlab-org/omnibus-gitlab!5752))

### Fixed (2 changes)

- [Fix URL for unzip v6.0 download](gitlab-org/omnibus-gitlab@21fcea1eb78cdae7ceba302f6abef1b49135b48a) ([merge request](gitlab-org/omnibus-gitlab!5752))
- [Conditionally generate public_attributes.json](gitlab-org/omnibus-gitlab@7dbfb5e782a269040eebd673ba6279ae2de6d3b1) ([merge request](gitlab-org/omnibus-gitlab!5752))

### Changed (1 change)

- [Downgrade grafana to the 7.x release branch](gitlab-org/omnibus-gitlab@f32b875f748d763cfda4f231a9cfb4210d5793e6) ([merge request](gitlab-org/omnibus-gitlab!5752))

## 14.3.4 (2021-10-28)

### Security (2 changes)

- [Update Curl to version 7.79.1](gitlab-org/security/omnibus-gitlab@152ecf0a7e6888f7d301aef27d3db8b68fd7e252) ([merge request](gitlab-org/security/omnibus-gitlab!155))
- [Update openssl to 1.1.1l](gitlab-org/security/omnibus-gitlab@4a566defdbb9f224f932c8876c666840d6d3e77e) ([merge request](gitlab-org/security/omnibus-gitlab!147))

## 14.3.3 (2021-10-12)

### Fixed (2 changes)

- [Update cacerts to 2021-09-30](gitlab-org/omnibus-gitlab@b39f98773f7e3e6ac4817f7fb93efb2bee1ec795) ([merge request](gitlab-org/omnibus-gitlab!5668))
- [Delay praefect database_*_no_proxy removals](gitlab-org/omnibus-gitlab@b30716ae18cf94b69befb2de607ae5434864a8f1) ([merge request](gitlab-org/omnibus-gitlab!5668))

## 14.3.2 (2021-10-01)

No changes.

## 14.3.1 (2021-09-30)

No changes.

## 14.3.0 (2021-09-21)

### Added (6 changes)

- [Adds symantic metadata to consul services](gitlab-org/omnibus-gitlab@08b43e3b498cafa56902ba652141329aa1a99431) ([merge request](gitlab-org/omnibus-gitlab!5594))
- [Add AWS SSE-KMS support for backups](gitlab-org/omnibus-gitlab@088fa1ed836de22203488beb443f7cec75bcd4f7) ([merge request](gitlab-org/omnibus-gitlab!5584))
- [Allow specifying additional config directory to consul](gitlab-org/omnibus-gitlab@6cb5b0f45992f9f16352b5570a197e4774da83fc) ([merge request](gitlab-org/omnibus-gitlab!5559))
- [Allow service names used to register with Consul be customized](gitlab-org/omnibus-gitlab@96526d5a825348f0d98002b6dc011af4db80ad24) ([merge request](gitlab-org/omnibus-gitlab!5560))
- [Add support for gitlab['omniauth_cas3_session_duration']](gitlab-org/omnibus-gitlab@0bd4ac5958b82501291bc1260e54cfa4cc531612) ([merge request](gitlab-org/omnibus-gitlab!5558))
- [Add SMTP configuration support for SMTP secret encryption](gitlab-org/omnibus-gitlab@1bb2a4003fe10ba8d24d7eb70e119f1b1598ac14) ([merge request](gitlab-org/omnibus-gitlab!5536))

### Fixed (3 changes)

- [Fixes the use of wal_keep_size with GEO on PG13](gitlab-org/omnibus-gitlab@8bd646ad8f1223a937050b4878f316c88d0c8582) ([merge request](gitlab-org/omnibus-gitlab!5601))
- [Update gitlab.rb.template for Service Desk](gitlab-org/omnibus-gitlab@2ec10e4090ed4b1ad62ae643991ec51428434916) ([merge request](gitlab-org/omnibus-gitlab!5556))
- [Fix migration NameError in rails env helper](gitlab-org/omnibus-gitlab@62974d5c13bb072683dcc08a2d83437a48361331) ([merge request](gitlab-org/omnibus-gitlab!5552))

### Changed (8 changes)

- [Bump container registry to v3.11.0](gitlab-org/omnibus-gitlab@8d724a2c96e021e365352be1c9c7234913e6b67a) ([merge request](gitlab-org/omnibus-gitlab!5600))
- [Update grafana to 8.1.3](gitlab-org/omnibus-gitlab@90c9eb0487af4e852553d2fdee89d1904584cfc0) ([merge request](gitlab-org/omnibus-gitlab!5449))
- [Bump container registry to v3.10.1](gitlab-org/omnibus-gitlab@a83eae00206ad500141111afd0bcb63e22c197e4) ([merge request](gitlab-org/omnibus-gitlab!5585))
- [Update Ruby to 2.7.4](gitlab-org/omnibus-gitlab@3a4304d9f9547619e955bf2b5971d73193a9f9f4) ([merge request](gitlab-org/omnibus-gitlab!5545))
- [Update chef gems to 15.17.4](gitlab-org/omnibus-gitlab@62f95b0ab9f75566f60d4f9623f66566f8b7e0d0) ([merge request](gitlab-org/omnibus-gitlab!5450))
- [Bump Container Registry to v3.10.0-gitlab](gitlab-org/omnibus-gitlab@2b8c96cf8442928cf80723b154faee5161d374b5) ([merge request](gitlab-org/omnibus-gitlab!5562))
- [Bump container registry to v3.9.0](gitlab-org/omnibus-gitlab@dda7bdf4cd9c6eea21359e919d6cfc81b21c4989) ([merge request](gitlab-org/omnibus-gitlab!5542))
- [Use Python 3.9.6](gitlab-org/omnibus-gitlab@82d52ccf3727b4603d39657794f02fa0f4b588de) ([merge request](gitlab-org/omnibus-gitlab!5547))

### Deprecated (1 change)

- [Prefer gitaly custom_hooks_dir setting](gitlab-org/omnibus-gitlab@136d789f675b0a13c848ca68eb0332ffa489fe11) ([merge request](gitlab-org/omnibus-gitlab!4208))

### Removed (1 change)

- [Remove support for gitlab_pages['use_legacy_storage'] setting](gitlab-org/omnibus-gitlab@4c96751a8fa8b4dd814f781133fb558c90343ed8) by @feistel ([merge request](gitlab-org/omnibus-gitlab!5529))

### Security (1 change)

- [Update cURL to 7.77.0](gitlab-org/omnibus-gitlab@dd9bc79002b84a110bc4a1e6ce87fb36b165424e)

### Other (2 changes)

- [Update Mattermost to 5.38.2](gitlab-org/omnibus-gitlab@02d9eb7adfbd2c13048cd0db4550ab994fb9feaa) by @hmhealey ([merge request](gitlab-org/omnibus-gitlab!5587))
- [Update Python from 3.7.10 to 3.9.5](gitlab-org/omnibus-gitlab@055e29c12442df3ef278a566160e1664e5da331b) ([merge request](gitlab-org/omnibus-gitlab!5547))

## 14.2.7 (2021-11-26)

### Added (1 change)

- [Add praefect prometheus_exclude_database_from_default_metrics config value](gitlab-org/omnibus-gitlab@a92ad24941e479d2e30ba087107081d36cf888e4) ([merge request](gitlab-org/omnibus-gitlab!5750))

### Fixed (3 changes)

- [Fix URL for unzip v6.0 download](gitlab-org/omnibus-gitlab@23f4f83c0926fc81ebd3b2932b7e5a1bcd31b2e1) ([merge request](gitlab-org/omnibus-gitlab!5750))
- [Conditionally generate public_attributes.json](gitlab-org/omnibus-gitlab@440ce859b9bca7f2147c835b7f199a4e4b6f8f38) ([merge request](gitlab-org/omnibus-gitlab!5750))
- [Delay praefect database_*_no_proxy removals](gitlab-org/omnibus-gitlab@dddf6f9d893d5f59a089a7d039360c5918840bea) ([merge request](gitlab-org/omnibus-gitlab!5750))

## 14.2.6 (2021-10-28)

### Security (2 changes)

- [Update Curl to version 7.79.1](gitlab-org/security/omnibus-gitlab@151269917214a2b791b90949e7794d19a5fc304d) ([merge request](gitlab-org/security/omnibus-gitlab!156))
- [Update openssl to 1.1.1l](gitlab-org/security/omnibus-gitlab@df6605f7b2cf0042ec156fd8b8bd35a2b5be0d1f) ([merge request](gitlab-org/security/omnibus-gitlab!148))

## 14.2.5 (2021-09-30)

No changes.

## 14.2.4 (2021-09-17)

No changes.

## 14.2.3 (2021-09-01)

No changes.

## 14.2.2 (2021-08-31)

### Security (1 change)

- [Update cURL to 7.77.0](gitlab-org/security/omnibus-gitlab@416f65f903ee27f107e6378413649e002d85c4b6) ([merge request](gitlab-org/security/omnibus-gitlab!144))

## 14.2.1 (2021-08-23)

### Fixed (1 change)

- [Fix migration NameError in rails env helper](gitlab-org/omnibus-gitlab@6a1ddc413f4ac1b4d56abac3aa148f4cd81deec3) ([merge request](gitlab-org/omnibus-gitlab!5553))

## 14.2.0 (2021-08-20)

### Added (8 changes)

- [Add option to specify log level for nginx logs](gitlab-org/omnibus-gitlab@89b91fc05ae583143e757c1febdbdeb61314f46c) ([merge request](gitlab-org/omnibus-gitlab!5530))
- [Add a (experimental) single command to promote a Geo secondary node](gitlab-org/omnibus-gitlab@be85c4d2f060caa5301ed72ac99dc969d8c6f13d) ([merge request](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5401))
- [Add missing Patroni configuration - tags, recovery_conf, callbacks](gitlab-org/omnibus-gitlab@c862f1f98f84b4a84d925e1a9c76524c6f7a8cba) ([merge request](gitlab-org/omnibus-gitlab!5525))
- [Add support to specify additional databases to Rails application](gitlab-org/omnibus-gitlab@80349389150549e02721795cd46a5e8b48ced65c) ([merge request](gitlab-org/omnibus-gitlab!5480))
- [Enable TLS support for Patroni API](gitlab-org/omnibus-gitlab@f0f94de248bba9f73e331df544b2c989c9cf8a46) ([merge request](gitlab-org/omnibus-gitlab!5486))
- [Support Workhorse config options for propagating correlation IDs](gitlab-org/omnibus-gitlab@dd74092e5e7e812c355bf8540dd7bd23a19c59ef) ([merge request](gitlab-org/omnibus-gitlab!5496))
- [Connect Puma low-level error handler to Sentry](gitlab-org/omnibus-gitlab@b1ebcc1924e5a9093ac79ad7f5150309e9536a55) ([merge request](gitlab-org/omnibus-gitlab!5490))
- [Add patroni allowlist support](gitlab-org/omnibus-gitlab@9b366bb46878964b7d09b368abc54604dbc69170) ([merge request](gitlab-org/omnibus-gitlab!5476))

### Fixed (3 changes)

- [Add AES256-GCM-SHA384 to allowed list of Nginx SSL ciphers](gitlab-org/omnibus-gitlab@127525c7f57daf7ca5ec38209180f3dcf0e8940e) ([merge request](gitlab-org/omnibus-gitlab!5513))
- [Fix `could not change directory to "/root": Permission denied`](gitlab-org/omnibus-gitlab@aa91ab2988958af1dd0bcf6cedbf68babec804f8) ([merge request](gitlab-org/omnibus-gitlab!5498))
- [Don't ask users to upgrade to PG 13 yet](gitlab-org/omnibus-gitlab@74f82ad556f70c1159267c25180cff7a2b8b54d5) ([merge request](gitlab-org/omnibus-gitlab!5488))

### Changed (7 changes)

- [Update Mattermost to 5.37.1 and update websocket support](gitlab-org/omnibus-gitlab@af32991925af80fbf723195b1e84ef9c04d333ba) ([merge request](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5516))
- [Bump Container Registry to v3.7.0-gitlab](gitlab-org/omnibus-gitlab@ada9e5ac7d67a99fff614b4570ba4236c4fd5175) ([merge request](gitlab-org/omnibus-gitlab!5520))
- [Transform database.yml to use main syntax](gitlab-org/omnibus-gitlab@7a379098fb5f45849d9be8e8f4a7054245393387) ([merge request](gitlab-org/omnibus-gitlab!5510))
- [Bump Container Registry to v3.6.2-gitlab](gitlab-org/omnibus-gitlab@6672574804c36591dc5eee51eaaf8f079df30827) ([merge request](gitlab-org/omnibus-gitlab!5506))
- [Bump Container Registry to v3.6.1-gitlab](gitlab-org/omnibus-gitlab@7649c01c3bb370dad23bf2ce4aa6860e714b6ae2) ([merge request](gitlab-org/omnibus-gitlab!5489))
- [Transform database.yml to use main syntax](gitlab-org/omnibus-gitlab@4fd5be4dccd006eb9f9321478e67401529641356) ([merge request](gitlab-org/omnibus-gitlab!5491))
- [Avoid generic NoMethodError on non-Patroni nodes](gitlab-org/omnibus-gitlab@e26450d3f473dc7dc9443c240f6adfce6adc1881) ([merge request](gitlab-org/omnibus-gitlab!5472))

### Security (1 change)

- [Update libgcrypt to 1.9.3](gitlab-org/omnibus-gitlab@1b8e0bb1b3bf39a339b7a8a63d2d232ef132cbe2)

### Other (2 changes)

- [Remove docs redirects cleanup task](gitlab-org/omnibus-gitlab@c03703f3c3f678e383ce92b17bf2e888dbcfa883) ([merge request](gitlab-org/omnibus-gitlab!5539))
- [Bump gitlab-exporter to 11.2.0](gitlab-org/omnibus-gitlab@9e005c8e8ccf16766327bd872ad284ae612bf6fd) ([merge request](gitlab-org/omnibus-gitlab!5518))

## 14.1.8 (2021-11-15)

### Fixed (2 changes)

- [Conditionally generate public_attributes.json](gitlab-org/omnibus-gitlab@4c2df93ec3abd466b233b99dd1558043347d98f9) ([merge request](gitlab-org/omnibus-gitlab!5717))
- [Delay praefect database_*_no_proxy removals](gitlab-org/omnibus-gitlab@9679474648e51a2ae699c8aa23dbb523e45fb6e3) ([merge request](gitlab-org/omnibus-gitlab!5717))

## 14.1.7 (2021-09-30)

No changes.

## 14.1.6 (2021-09-27)

No changes.

## 14.1.5 (2021-09-02)

No changes.

## 14.1.4 (2021-08-31)

### Security (1 change)

- [Update cURL to 7.77.0](gitlab-org/security/omnibus-gitlab@77b0ac2436a269b52318dd39390efbacfc8c8244) ([merge request](gitlab-org/security/omnibus-gitlab!136))

## 14.1.3 (2021-08-17)

### Fixed (1 change)

- [Add AES256-GCM-SHA384 to allowed list of Nginx SSL ciphers](gitlab-org/omnibus-gitlab@43169882dfb36046dc01ae681eb7cc5df4a2887f) ([merge request](gitlab-org/omnibus-gitlab!5546))

## 14.1.2 (2021-08-03)

### Security (1 change)

- [Update libgcrypt to 1.9.3](gitlab-org/security/omnibus-gitlab@05a6f88dea9600243178741169fe243c48a9bcb2) ([merge request](gitlab-org/security/omnibus-gitlab!131))

## 14.1.1 (2021-07-28)

### Fixed (1 change)

- [Don't ask users to upgrade to PG 13 yet](gitlab-org/omnibus-gitlab@ea97a631cc97fd193f28f50a7a7510d0aa2fc8b1) ([merge request](gitlab-org/omnibus-gitlab!5493))

## 14.1.0 (2021-07-21)

### Added (6 changes)

- [Nginx: further modernisation and standardisation](gitlab-org/omnibus-gitlab@aa320de20a678cd27c730d7cc123aaaa276b9367) ([merge request](gitlab-org/omnibus-gitlab!5461))
- [Add PostgreSQL 13 binaries to Omnibus](gitlab-org/omnibus-gitlab@1400ba430e2abc4bd7f37fa08dc8276898564897) ([merge request](gitlab-org/omnibus-gitlab!5390))
- [Allow nginx keepalive_time to be configured](gitlab-org/omnibus-gitlab@eb756b2708595d2f88075d62bd07c77ff84ef444) ([merge request](gitlab-org/omnibus-gitlab!5427))
- [Add configuration for gitaly-backup path](gitlab-org/omnibus-gitlab@4e864e1243f689d0dcdb234fb903600331cfc1aa) ([merge request](gitlab-org/omnibus-gitlab!5419))
- [Add basic auth settings for patroni rest api](gitlab-org/omnibus-gitlab@082964bc706ddc1566d95949982d12fb66df2637) ([merge request](gitlab-org/omnibus-gitlab!5403))
- [Add role for Sidekiq](gitlab-org/omnibus-gitlab@9064ab1758476c19a9d7d1f7fb7b83ae75fdfc3d) ([merge request](gitlab-org/omnibus-gitlab!5365))

### Fixed (3 changes)

- [Centralize enabling and disabling of crond](gitlab-org/omnibus-gitlab@44375da451be5199a4412b322eeecfc8e0ebcebe) ([merge request](gitlab-org/omnibus-gitlab!5394))
- [Exempt unicorn['svlogd_prefix'] from deprecation check](gitlab-org/omnibus-gitlab@f1ff80d38a7398047524a13f384b8384bf0c0ea1) ([merge request](gitlab-org/omnibus-gitlab!5395))
- [Fix preinstall upgrade message](gitlab-org/omnibus-gitlab@1ddf5a8af58068fa82c25d9017cf5890fde8264b) ([merge request](gitlab-org/omnibus-gitlab!5385))

### Changed (11 changes)

- [Ensure systemd under Docker is correctly detected](gitlab-org/omnibus-gitlab@cafe7cc4ba6e45c021c67c05f24ed0d5d69acfaf) ([merge request](gitlab-org/omnibus-gitlab!5446))
- [Nginx: modernise TLS config](gitlab-org/omnibus-gitlab@ec870943213718e1c221bb17b1ae9db3b7a2e72f) ([merge request](gitlab-org/omnibus-gitlab!5461))
- [Bump Container Registry to v3.5.2-gitlab](gitlab-org/omnibus-gitlab@2b9508557beafda31823d66a37ca49d65d9620ea) ([merge request](gitlab-org/omnibus-gitlab!5463))
- [Update libjpeg-turbo 2.1.0](gitlab-org/omnibus-gitlab@75276e02b7d3ac56959862181268fcd0369985d8) ([merge request](gitlab-org/omnibus-gitlab!5451))
- [Bump ffi to 1.15.3](gitlab-org/omnibus-gitlab@fc84c088c9867bafe26c5f39350c6a8129821dad) ([merge request](gitlab-org/omnibus-gitlab!5468))
- [Update alertmanager to 0.22.2](gitlab-org/omnibus-gitlab@59542be7ba4155d6078421acfb95791211200798) ([merge request](gitlab-org/omnibus-gitlab!5301))
- [Update chef-acme to 4.1.3](gitlab-org/omnibus-gitlab@2a87d1f2b112a39e08f649ce271ccaa83754079e) ([merge request](gitlab-org/omnibus-gitlab!5459))
- [Update gitlab-exporter from 10.3.0 to 10.4.0](gitlab-org/omnibus-gitlab@259e16c2cc3951bfc7f64f278972d2becba8f271) ([merge request](gitlab-org/omnibus-gitlab!5324))
- [Set 14.0 as minimum version permitted to upgrade from](gitlab-org/omnibus-gitlab@0ee66c3aa5ee3b14c409ba7a8e63a7ec4df295ed) ([merge request](gitlab-org/omnibus-gitlab!5398))
- [Update grafana/grafana from 7.5.5 to 7.5.9](gitlab-org/omnibus-gitlab@ff6eca926c669d2431d5ae9225e9138ccf59920a) ([merge request](gitlab-org/omnibus-gitlab!5246))
- [Update go-crond from 20.7.0 to 21.5.0](gitlab-org/omnibus-gitlab@6077e939274d21b6e8af1e1eb5191f74ff9aed1a) ([merge request](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5237))

### Removed (3 changes)

- [Update Praefect defaults in template](gitlab-org/omnibus-gitlab@f5c06c3e080a14660daf7b54fff1a0b0df17648a) ([merge request](gitlab-org/omnibus-gitlab!5375))
- [Remove seat link setting](gitlab-org/omnibus-gitlab@c05c309c15b57fc3b306eb8ebaea537c95e4e48f) ([merge request](gitlab-org/omnibus-gitlab!5235))
- [Remove git2go software module](gitlab-org/omnibus-gitlab@c7638374fecadb2e7bc2b06e4d9a06591b9be775) ([merge request](gitlab-org/omnibus-gitlab!5396))

### Security (2 changes)

- [Move gitlab-rails-rc to more secure location](gitlab-org/omnibus-gitlab@21ab274d8951f6a0fd3c5659e07bf364e5e0f50f) ([merge request](gitlab-org/omnibus-gitlab!5421))
- [Add libxml2 security patches released as of May 2021](gitlab-org/omnibus-gitlab@371d600f0161ceab9e922068f86d9b93059392bb)

### Other (2 changes)

- [Space savings from stripping promethues build](gitlab-org/omnibus-gitlab@b3ba9e00b9b521eb6a56dbf2c672ab0ee86efc6f) ([merge request](gitlab-org/omnibus-gitlab!5443))
- [Update Mattermost to 5.36.1](gitlab-org/omnibus-gitlab@ee8c540ae04ad493ba4acaa5d4e398057697a83f) ([merge request](gitlab-org/omnibus-gitlab!5439))

### updated (2 changes)

- [Update Patroni to 2.1.0](gitlab-org/omnibus-gitlab@dbb5f1de558cd0e3405a7e48f90cac046d26b992) ([merge request](gitlab-org/omnibus-gitlab!5440))
- [Upgrade nginx to 1.20.1](gitlab-org/omnibus-gitlab@bceaa58eb380cbf20753454c6e60820a2845d1cf) ([merge request](gitlab-org/omnibus-gitlab!5417))

### fix (1 change)

- [Fix Praefect configuration template for session pooled connection](gitlab-org/omnibus-gitlab@1825c88764508a7efdccbf3eb70cb32e6bbb91d8) ([merge request](gitlab-org/omnibus-gitlab!5424))

## 14.0.12 (2021-11-05)

### Fixed (1 change)

- [Conditionally generate public_attributes.json](gitlab-org/omnibus-gitlab@84109feb04962e6af2c42a50fd2a56d0c7ced334) ([merge request](gitlab-org/omnibus-gitlab!5712))

## 14.0.11 (2021-09-23)

No changes.

## 14.0.10 (2021-09-02)

No changes.

## 14.0.9 (2021-08-31)

### Security (2 changes)

- [Patch NGINX against CVE-2021-23017](gitlab-org/security/omnibus-gitlab@b7a035067769fe6167f43d9ba13f316423a3523c) ([merge request](gitlab-org/security/omnibus-gitlab!142))
- [Update cURL to 7.77.0](gitlab-org/security/omnibus-gitlab@fdc278a442075eb3ed70aeede942bb10eadc75a5) ([merge request](gitlab-org/security/omnibus-gitlab!135))

## 14.0.8 (2021-08-25)

No changes.

## 14.0.7 (2021-08-03)

### Security (2 changes)

- [Update libgcrypt to 1.9.3](gitlab-org/security/omnibus-gitlab@4923730ca28a0ad461988378c0d416850658277d) ([merge request](gitlab-org/security/omnibus-gitlab!132))
- [Update Mattermost to 5.35.4 (GitLab 14.0)](gitlab-org/security/omnibus-gitlab@13f1bb4ed61d7f59479cfae473608167ff3042c6) ([merge request](gitlab-org/security/omnibus-gitlab!128))

## 14.0.6 (2021-07-20)

No changes.

## 14.0.5 (2021-07-08)

No changes.

## 14.0.4 (2021-07-07)

No changes.

## 14.0.3 (2021-07-06)

No changes.

## 14.0.2 (2021-07-01)

### Security (1 change)

- [Add libxml2 security patches released as of May 2021](gitlab-org/security/omnibus-gitlab@47261456691197d7c4baa722af96eb3f02740bf5) ([merge request](gitlab-org/security/omnibus-gitlab!123))

## 14.0.1 (2021-06-24)

### Fixed (1 change)

- [Exempt unicorn['svlogd_prefix'] from deprecation check](gitlab-org/omnibus-gitlab@8aa7c341a4f7fdc24833daf66a7abcc3333b6128) ([merge request](gitlab-org/omnibus-gitlab!5404))

## 14.0.0 (2021-06-21)

### Added (8 changes)

- [Prevent Docker upgrade to 14.0 if there data on legacy storage](gitlab-org/omnibus-gitlab@2609201ecaa54d4fe871802783e5b4c94d37ae54) ([merge request](gitlab-org/omnibus-gitlab!5320))
- [Build gitaly-git2go from previous gitaly version](gitlab-org/omnibus-gitlab@f55201824a745751dbcb9ae571aedbdc3cb7089c) ([merge request](gitlab-org/omnibus-gitlab!5359))
- [Add option to write initial root password to a file](gitlab-org/omnibus-gitlab@4d7757243ad8bfc6f6a449e174c5f5f626333a43) ([merge request](gitlab-org/omnibus-gitlab!5331))
- [Add option to disable printing of root password during initialization](gitlab-org/omnibus-gitlab@7369fd762861082057e5e6165917c625f9c1d39e) ([merge request](gitlab-org/omnibus-gitlab!5331))
- [Add Workhorse shutdown_timeout config setting](gitlab-org/omnibus-gitlab@3bf28cb060186b654fc639215c46df49634c745a) ([merge request](gitlab-org/omnibus-gitlab!5343))
- [Prevent upgrade to 14.0 if there is data on legacy storage](gitlab-org/omnibus-gitlab@35b97442337616b1147159c6f556c8ddc39276db) ([merge request](gitlab-org/omnibus-gitlab!5311))
- [Allow configuring redis instance for trace chunks](gitlab-org/omnibus-gitlab@8416adf9755ec5e63ac0e31595dfb049366ce4c7) ([merge request](gitlab-org/omnibus-gitlab!5316))
- [Prevent upgrade to 14.0 if there is data on legacy storage](gitlab-org/omnibus-gitlab@ad4e6d1a3b72f2bd1549d32f7b905e4fca2ede6d) ([merge request](gitlab-org/omnibus-gitlab!5256))

### Fixed (8 changes)

- [Fix get-postgresql-primary command for Geo](gitlab-org/omnibus-gitlab@87e7496565d851d8d37f2c6a78ccf12f9ab8239e) ([merge request](gitlab-org/omnibus-gitlab!5382))
- [Fix pitr_file to use the right path for ConsulError](gitlab-org/omnibus-gitlab@70216599a13ff7f8d83970d5888bd4503697f8d3) ([merge request](gitlab-org/omnibus-gitlab!5378))
- [Update consul lookup in get-postgresql-primary](gitlab-org/omnibus-gitlab@13eec4ee7dadf36f1f84c74efd30440acfb946eb) ([merge request](gitlab-org/omnibus-gitlab!5369))
- [Do not show Praefect deprecation if Praefect is disabled](gitlab-org/omnibus-gitlab@0a3fdc1c6a0df1b26eebbfed6808c1af1fdc218b) ([merge request](gitlab-org/omnibus-gitlab!5350))
- [Adds default for prepared_statements config in Geo secondary db.yml](gitlab-org/omnibus-gitlab@8637044b1c9bb9ab019441629e6b2c59a6921e7c) ([merge request](gitlab-org/omnibus-gitlab!5347))
- [Rotate mailroom logs](gitlab-org/omnibus-gitlab@47d3cebe00366181346e87797036f5cb314fbc42) ([merge request](gitlab-org/omnibus-gitlab!5319))
- [Fix passing environment variables for migrations](gitlab-org/omnibus-gitlab@11ea132e7ca8ce61a8fca8af5837669388b4a179) ([merge request](gitlab-org/omnibus-gitlab!5310))
- [Recreate SSL key if it does not match the config](gitlab-org/omnibus-gitlab@ee5b35f6278309c0c474b58ae71be70c7fba8b66) ([merge request](gitlab-org/omnibus-gitlab!5204))

### Changed (17 changes)

- [Use Busybox for editor in docker](gitlab-org/omnibus-gitlab@29b4f428f54b0534a556444b3bd26657f6b42b53) ([merge request](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/4142))
- [Upgrade Omnibus Builder to v1.6.0](gitlab-org/omnibus-gitlab@ade4aa24b943abbeac0cad3e37dcdd057c48a04e) ([merge request](gitlab-org/omnibus-gitlab!5374))
- [Don't enable consul with `postgres_role`.](gitlab-org/omnibus-gitlab@af8b3b46967b14fe29a6e56d3d3ac5fe99715265) ([merge request](gitlab-org/omnibus-gitlab!5370))
- [Upgrade postgresql-exporter to 0.9.0](gitlab-org/omnibus-gitlab@8bd053793c38c51c25d43a36696967e86e3822d0) ([merge request](gitlab-org/omnibus-gitlab!5364))
- [Use consul if available when pausing Geo replication](gitlab-org/omnibus-gitlab@bfeef1355c7187c10313ca6c8ee32afb0a82debb) ([merge request](gitlab-org/omnibus-gitlab!5300))
- [Upgrade docker-distribution-pruner to v0.2.0](gitlab-org/omnibus-gitlab@c75d2a948874d7f13597e5de08e92d557e96d65b) ([merge request](gitlab-org/omnibus-gitlab!5362))
- [Bump Container Registry to v3.5.0-gitlab](gitlab-org/omnibus-gitlab@104115b39b085628d0931220a7c697a03fc5c4ab) ([merge request](gitlab-org/omnibus-gitlab!5354))
- [Automatically generate initial root password if not set](gitlab-org/omnibus-gitlab@0af09d880118149e0d2e4ab6516679c489500489) ([merge request](gitlab-org/omnibus-gitlab!5331))
- [Update consul to version 1.9.6](gitlab-org/omnibus-gitlab@4fde3786d470f112d9894177afb89c3009df0c77) ([merge request](gitlab-org/omnibus-gitlab!5344))
- [change the default to `true` for deleting old backups](gitlab-org/omnibus-gitlab@99027bbefbd9fc53e3df2c77806d47fa79fa0c06) ([merge request](gitlab-org/omnibus-gitlab!5322))
- [Expand configuration of Praefect direct database connection](gitlab-org/omnibus-gitlab@6931fc428aa0746071cbf3d8fc52d1ec623dbc8e) ([merge request](gitlab-org/omnibus-gitlab!5251))
- [Bump redis to 6.0.14, drop custom patch](gitlab-org/omnibus-gitlab@238b13d1d78de96067e4ddd11fce5fc948fb31b1) ([merge request](gitlab-org/omnibus-gitlab!5327))
- [Upgrade Patroni to version 2.0.2](gitlab-org/omnibus-gitlab@bf36ff4fc22f3137f4a7d0113e70e551aebe5f1f) ([merge request](gitlab-org/omnibus-gitlab!5314))
- [Fix package-scripts version string](gitlab-org/omnibus-gitlab@8ee43bd70723f97467ac5da1be6e6fc94724960d) ([merge request](gitlab-org/omnibus-gitlab!5287))
- [Remove sidekiq_cluster service and settings](gitlab-org/omnibus-gitlab@be7a659861002803e2bf8c0244083c2d0e822ace) ([merge request](gitlab-org/omnibus-gitlab!5291))
- [Always use sidekiq-cluster binary for Sidekiq service](gitlab-org/omnibus-gitlab@9d754a15c2bc52d1823a5d7e68d075f424ce6504) ([merge request](gitlab-org/omnibus-gitlab!5291))
- [Set 13.12 as minimum version required to upgrade from](gitlab-org/omnibus-gitlab@2e65138d645cb92c79682c8a83b504b81a29ec3c) ([merge request](gitlab-org/omnibus-gitlab!5259))

### Removed (18 changes)

- [Remove repmgr installation support](gitlab-org/omnibus-gitlab@69c19633b786962d1eb511631e6994ce393153e0) ([merge request](gitlab-org/omnibus-gitlab!5372))
- [Remove support for Praefect election strategy](gitlab-org/omnibus-gitlab@60d4e3de2bce833b1fdcb46cd29dc332f7870465) ([merge request](gitlab-org/omnibus-gitlab!5351))
- [Omnibus v14 requires PG12 or higher](gitlab-org/omnibus-gitlab@f8bb478bd2dfe1136820c74e27af1d3fe927b3e0) ([merge request](gitlab-org/omnibus-gitlab!5348))
- [Remove deprecated `experimental_queue_selector` option for Sidekiq](gitlab-org/omnibus-gitlab@64fc0fcaaca69ec73ad6960bfe60080a9345831c) ([merge request](gitlab-org/omnibus-gitlab!5317))
- [Remove deprecated `experimental_queue_selector` option for Sidekiq](gitlab-org/omnibus-gitlab@02a2435eb46a0c2a5bd0877c7a3b95f005de967d) ([merge request](gitlab-org/omnibus-gitlab!5306))
- [Remove support for postgresql['data_dir'] setting](gitlab-org/omnibus-gitlab@2a2669ed9c89e8a7010c551c58668c879c3ac03c) ([merge request](gitlab-org/omnibus-gitlab!5279))
- [Remove deprecated `pgbouncer` public attributes](gitlab-org/omnibus-gitlab@1f954f5216694b1ce7812ba11d4c85eb4e23020a) ([merge request](gitlab-org/omnibus-gitlab!5299))
- [Remove node['gitlab']['pgbouncer-exporter'] deprecation](gitlab-org/omnibus-gitlab@14182dc8c0b471f0e60d7c1ab9e6e8aa3aa04377) ([merge request](gitlab-org/omnibus-gitlab!5298))
- [Remove Unicorn and related code](gitlab-org/omnibus-gitlab@b7566558b82396e262d7a8e8012365ad5fd3e872) ([merge request](gitlab-org/omnibus-gitlab!5295))
- [Remove Deprecated Piwik settings](gitlab-org/omnibus-gitlab@1723f793e4dc9a62eb198a4a26a2c6f6f27ba3aa) ([merge request](gitlab-org/omnibus-gitlab!5277))
- [Remove support for gitlab_pages['http_proxy']](gitlab-org/omnibus-gitlab@9f66bf2fe2adaf1a0c3942b60a20606a3dc56460) ([merge request](gitlab-org/omnibus-gitlab!5278))
- [Remove obsolete sidekiq['cluster'] setting](gitlab-org/omnibus-gitlab@84fcf243d8f165bb3cfd1376243240fa5c5936a2) ([merge request](gitlab-org/omnibus-gitlab!5291))
- [Remove support for client_output_buffer_limit_slave](gitlab-org/omnibus-gitlab@f1bdc7900d4a5ee1814ffc623ca0e5aece366af6) ([merge request](gitlab-org/omnibus-gitlab!5290))
- [Remove support for redis_slave_role](gitlab-org/omnibus-gitlab@78177c126c3532cf16bd0effad7773d79e2e1bd9) ([merge request](gitlab-org/omnibus-gitlab!5290))
- [Remove support for analytics_instance_statistics_count_job_trigger_worker_cron...](gitlab-org/omnibus-gitlab@697710c02dab6d4699662bcc51df55b5fce517e5) ([merge request](gitlab-org/omnibus-gitlab!5285))
- [Remove support for nginx['gzip'] in favor of nginx['gzip_enabled']](gitlab-org/omnibus-gitlab@4d8bb0429fffe4fde027e170b21fbdf7cdef1c8e) ([merge request](gitlab-org/omnibus-gitlab!5284))
- [Remove deprecated PostgreSQL FDW settings](gitlab-org/omnibus-gitlab@3f7a5ccd68be8391b565ec6a2a6d745161e3b923) ([merge request](gitlab-org/omnibus-gitlab!5255))
- [Stop building packages for openSUSE Leap 15.1](gitlab-org/omnibus-gitlab@b8780946690f3dc56c2095aabc6be2ad4869decd) ([merge request](gitlab-org/omnibus-gitlab!5264))

### Security (1 change)

- [Update Mattermost to 5.35.3](gitlab-org/omnibus-gitlab@891ae9c1cfd338d9a0f4612379a916645b475f57) ([merge request](gitlab-org/omnibus-gitlab!5358))

### Other (2 changes)

- [Bump gitlab-exporter to 10.3.0](gitlab-org/omnibus-gitlab@ff48e6e54f1da086711ea85b586713816eb6a42d) ([merge request](gitlab-org/omnibus-gitlab!5315))
- [Update Mattermost to 5.35.2](gitlab-org/omnibus-gitlab@c0592b2bb4be3ce0f61ae2e287410cf9128f6c19) ([merge request](gitlab-org/omnibus-gitlab!5329))

## 13.12.15 (2021-11-03)

No changes.

## 13.12.14 (2021-11-03)

No changes.

## 13.12.13 (2021-10-29)

### Fixed (1 change)

- [Conditionally generate public_attributes.json](gitlab-org/omnibus-gitlab@466e0c357dae6f66d12a558364a2bc5b62bcf2d6) ([merge request](gitlab-org/omnibus-gitlab!5699))

## 13.12.12 (2021-09-21)

No changes.

## 13.12.11 (2021-09-02)

No changes.

## 13.12.10 (2021-08-10)

No changes.

## 13.12.9 (2021-08-03)

### Security (2 changes)

- [Update libgcrypt to 1.9.3](gitlab-org/security/omnibus-gitlab@42eede86a73071d83db9297d1ad15778f95b0a83) ([merge request](gitlab-org/security/omnibus-gitlab!133))
- [Update Mattermost to 5.34.5 (GitLab 13.12)](gitlab-org/security/omnibus-gitlab@73c3c9eec3c1254f0f135728a013d9a02c2cdd1b) ([merge request](gitlab-org/security/omnibus-gitlab!129))

## 13.12.8 (2021-07-07)

No changes.

## 13.12.7 (2021-07-05)

No changes.

## 13.12.6 (2021-07-01)

### Security (2 changes)

- [Add libxml2 security patches released as of May 2021](gitlab-org/security/omnibus-gitlab@93950f475de418e473732ef6e3ae4b7255b242ac) ([merge request](gitlab-org/security/omnibus-gitlab!124))
- [Update Redis to 6.0.14](gitlab-org/security/omnibus-gitlab@5cc03fd6dffebdc2cf4053d5c6d54a5803d42b35) ([merge request](gitlab-org/security/omnibus-gitlab!120))

## 13.12.5 (2021-06-21)

No changes.

## 13.12.4 (2021-06-14)

### Fixed (1 change)

- [Do not show Praefect deprecation if Praefect is disabled](gitlab-org/omnibus-gitlab@a4101169ca38b46bed71f0e4546d87bc38f88fbb) ([merge request](gitlab-org/omnibus-gitlab!5368))

### Security (1 change)

- [Update Mattermost to 5.34.4](gitlab-org/omnibus-gitlab@0a44c28f79b5cade9be27942178f2c2e6b4c9f48) ([merge request](gitlab-org/omnibus-gitlab!5361))

## 13.12.3 (2021-06-07)

No changes.

## 13.12.2 (2021-06-01)

No changes.

## 13.12.1 (2021-05-25)

No changes.

## 13.12.0 (2021-05-21)

### Added (8 changes)

- [Add expired and expiring SSH key notification cron](gitlab-org/omnibus-gitlab@8c2740fb4ab9af542d40926e84d1077937348931) ([merge request](gitlab-org/omnibus-gitlab!5119))
- [Add support to configure Sidekiq routing rules](gitlab-org/omnibus-gitlab@9b75bd4218196590b70c40184e8504c0c941c9f3) ([merge request](gitlab-org/omnibus-gitlab!5202))
- [Add enable_disk flag for Pages](gitlab-org/omnibus-gitlab@7308676169f8d14173c38e470f0152d59a445363) ([merge request](gitlab-org/omnibus-gitlab!5242))
- [Added environment support for ECS/Fargate](gitlab-org/omnibus-gitlab@e94fbc72f6c0a1ae4bf656624a1ee2584bf6befb) ([merge request](gitlab-org/omnibus-gitlab!5164))
- [Add hide_server_tokens option for NGINX](gitlab-org/omnibus-gitlab@bd5b246d5885ea545865854c09c3aad76872db2b) ([merge request](gitlab-org/omnibus-gitlab!5208))
- [Add support in Workhorse for X-Request-Id header propagation](gitlab-org/omnibus-gitlab@ae97ab2dc7cf90b53379ba891f501828fea98600) ([merge request](gitlab-org/omnibus-gitlab!5207))
- [Toogle for workhorse keywatcher](gitlab-org/omnibus-gitlab@aa6dc87f520325037649a19bef38445afb62a4e4) ([merge request](gitlab-org/omnibus-gitlab!5173))
- [Add support for SMTP connection pooling](gitlab-org/omnibus-gitlab@6bf6e1039d1ac33812235f73d4981b885db287b6) ([merge request](gitlab-org/omnibus-gitlab!5175))

### Fixed (4 changes)

- [Fix an error where reconfigure would swap the praefect election strategy](gitlab-org/omnibus-gitlab@3a2ca5eecaba0282f62cbbcad2dc1999856c86f2) ([merge request](gitlab-org/omnibus-gitlab!5260))
- [Fix deprecation logic which could auto-enable services](gitlab-org/omnibus-gitlab@5798c379da43df0779e0baafe6540d645dc8c9a3) ([merge request](gitlab-org/omnibus-gitlab!5226))
- [Fix pg-upgrade failing on mattermost only deploys](gitlab-org/omnibus-gitlab@1df80f6c68587fe9b5f2abe700a70b899976f82a) ([merge request](gitlab-org/omnibus-gitlab!5223))
- [Fix crash in gitlab-exporter when running on Puma](gitlab-org/omnibus-gitlab@dd86f2bbbe9f9789cd1be6817a0b113df6002e26) ([merge request](gitlab-org/omnibus-gitlab!5181))

### Changed (6 changes)

- [Bump container registry to v3.4.1](gitlab-org/omnibus-gitlab@79f804d851e985b8b99cd3c56eae14115f4e877a) ([merge request](gitlab-org/omnibus-gitlab!5243))
- [Upgrade mailroom to v0.0.12](gitlab-org/omnibus-gitlab@a49943237377d14078091cc74a5d0ad34b3278dc) ([merge request](gitlab-org/omnibus-gitlab!5250))
- [Use backup_keep_time to prune configuration backups](gitlab-org/omnibus-gitlab@58cdb7aa419efb040863c9b2bdc9f4365fbaa8c4) ([merge request](gitlab-org/omnibus-gitlab!5102))
- [Update acme-client from 2.0.7 to 2.0.8](gitlab-org/omnibus-gitlab@55ea32ba4eddcb130e7b83a452f88691c2734eb1) ([merge request](gitlab-org/omnibus-gitlab!5211))
- [Include gzip directives in main nginx.conf only if enabled](gitlab-org/omnibus-gitlab@2624c960fca970eec4a6e31886596113bfd5f823) ([merge request](gitlab-org/omnibus-gitlab!5225))
- [Update git vendor to gitlab](gitlab-org/omnibus-gitlab@7a62e8b5141287823a674a153033f580901718fb) ([merge request](gitlab-org/omnibus-gitlab!5184))

### Deprecated (5 changes)

- [Deprecate Praefect's failover_election_strategy config option](gitlab-org/omnibus-gitlab@0c00c13f1be742a82ea887e9f734cfcc719d2161) ([merge request](gitlab-org/omnibus-gitlab!5228))
- [Deprecate configuring Gitaly nodes in virtual storage's config root](gitlab-org/omnibus-gitlab@4cb5946e9b55ad870412b07ac69aa7f1a229df2b) ([merge request](gitlab-org/omnibus-gitlab!5240))
- [Deprecate nginx['gzip'] setting in favor of nginx['gzip_enabled']](gitlab-org/omnibus-gitlab@f204a982e850bb781c0fa0562f45cdf82ccdfc8f) ([merge request](gitlab-org/omnibus-gitlab!5225))
- [Deprecate Unicorn settings](gitlab-org/omnibus-gitlab@da7349da515f895f9be5a2e7c0a9cff30f39410c) ([merge request](gitlab-org/omnibus-gitlab!5214))
- [Deprecate Unicorn settings](gitlab-org/omnibus-gitlab@ecdf7ff19fc1f91b1274d71245cc7e59b93aff74) ([merge request](gitlab-org/omnibus-gitlab!5180))

### Security (2 changes)

- [Update Python to 3.7.10](gitlab-org/omnibus-gitlab@88e5c6a1e047ceb965299282e47b2b07b0f24dc4)
- [Upgrade redis to 6.0.12](gitlab-org/omnibus-gitlab@0aac392e6315f0cf363fb0ec35f6fc711aee66bb)

### Performance (1 change)

- [Reuse `postgresql::sysctl` in geo-postgresql](gitlab-org/omnibus-gitlab@9ac7d69394559163356fb23af21bf830ef71bfbc) ([merge request](gitlab-org/omnibus-gitlab!5153))

### Other (4 changes)

- [Make `puma_config` `install_dir` resource attribute optional](gitlab-org/omnibus-gitlab@4908919a3e66429e7507fe5ad68a864a98ec8fb2) ([merge request](gitlab-org/omnibus-gitlab!5201))
- [Update Mattermost to 5.34.2](gitlab-org/omnibus-gitlab@1e7d5463b598950472870b346cd44e9368596f66) ([merge request](gitlab-org/omnibus-gitlab!5206))
- [Update libtiff from 4.2.0 to 4.3.0](gitlab-org/omnibus-gitlab@c4ebbb5116ddb6ce76cf61625a51b6ee6c4c2d26) ([merge request](gitlab-org/omnibus-gitlab!5189))
- [Update grafana from 7.5.1 to 7.5.4](gitlab-org/omnibus-gitlab@a322670d961092b7bde707af2ba94af864b09216) ([merge request](gitlab-org/omnibus-gitlab!5178))

## 13.11.7 (2021-07-07)

No changes.

## 13.11.6 (2021-07-01)

### Security (3 changes)

- [Add libxml2 security patches released as of May 2021](gitlab-org/security/omnibus-gitlab@b9df8cc391c18657f697ddba1e451725096bdf79) ([merge request](gitlab-org/security/omnibus-gitlab!125))
- [Update Redis to 6.0.14](gitlab-org/security/omnibus-gitlab@283f77dd10b91384a86edc7c0c872de0b44e2c0c) ([merge request](gitlab-org/security/omnibus-gitlab!121))
- [Update Mattermost to 5.33.5](gitlab-org/security/omnibus-gitlab@06a53e3a307d22d851468f63dfc7ffaeb4a9ad10) ([merge request](gitlab-org/security/omnibus-gitlab!118))

## 13.11.5 (2021-06-01)

No changes.

## 13.11.4 (2021-05-14)

No changes.

## 13.11.3 (2021-04-30)

No changes.

## 13.11.2 (2021-04-27)

### Security (2 changes)

- [Update Python to 3.7.10](gitlab-org/security/omnibus-gitlab@a2cf223f65bc6877e811fd745c40a1f5152e4dbc) ([merge request](gitlab-org/security/omnibus-gitlab!109))
- [Upgrade redis to 6.0.12](gitlab-org/security/omnibus-gitlab@94962afe65714eb8bb8c6ecf8a0c42907b12a4eb) ([merge request](gitlab-org/security/omnibus-gitlab!108))

## 13.11.1+ee.0 (2021-04-22)

No changes.

## 13.11.0+ee.0 (2021-04-21)

### Added (9 changes)

- [Add in-product marketing emails cron worker](gitlab-org/omnibus-gitlab@3930fad0ec906d6a61b44f1470f2638542faff17) ([merge request](gitlab-org/omnibus-gitlab!5096))
- [Allow config for geo_secondary_usage_data_cron](gitlab-org/omnibus-gitlab@92026ace7583a0563682b8a27e18506248b23e75) ([merge request](gitlab-org/omnibus-gitlab!5165))
- [Add summarized gitaly apdex for usage ping](gitlab-org/omnibus-gitlab@bc8880331a03dad963461045f0b1b86a55e3802e) ([merge request](gitlab-org/omnibus-gitlab!5148))
- [Added new local_store config for Pages](gitlab-org/omnibus-gitlab@09801f4a99709074d7c19543c6c9b66805c0218a) ([merge request](gitlab-org/omnibus-gitlab!5058))
- [Render Gitaly pack_objects_cache settings](gitlab-org/omnibus-gitlab@4d20f64edb46fe3a69f71bc5310e63480601337e) ([merge request](gitlab-org/omnibus-gitlab!5120))
- [Build openSUSE Leap 15.2 packages](gitlab-org/omnibus-gitlab@6868ce60edfcc883f769154e1761293623bfce4a) ([merge request](gitlab-org/omnibus-gitlab!5134))
- [Use git provided by Gitaly](gitlab-org/omnibus-gitlab@d7db53d06f149a0aa34d982edc034e62837596f3) ([merge request](gitlab-org/omnibus-gitlab!5113))
- [Gitaly default maintenance override](gitlab-org/omnibus-gitlab@13de4d226be5de0b29a596e9a1fef076a2a9e3c6) ([merge request](gitlab-org/omnibus-gitlab!5089))
- [Add net-protocol BSD-2 license](gitlab-org/omnibus-gitlab@baa4f138e03bf9ed3d74666a3ba98fe1b3a75c5a) ([merge request](gitlab-org/omnibus-gitlab!5118))

### Fixed (7 changes)

- [Fix grafana for RPi](gitlab-org/omnibus-gitlab@6c460d41a15737f5ebd13ebf250827a38eec963e) ([merge request](gitlab-org/omnibus-gitlab!5162))
- [Update AWS Marketplace Release code to match new API requirements](gitlab-org/omnibus-gitlab@9cffb5bd967bf32dc57437e8e09c3406c8398f38) ([merge request](gitlab-org/omnibus-gitlab!5146))
- [Run AWS jobs on both CE and EE non-RC-or-auto-deploy tags](gitlab-org/omnibus-gitlab@cf4b73b40d5634b8d7fad13d89b5abde2e749e18) ([merge request](gitlab-org/omnibus-gitlab!5147))
- [Update gitlab-exporter to 10.1.0 to avoid query failures](gitlab-org/omnibus-gitlab@301afe78fc9e6620d5eb4578be62d1d161ba9639) ([merge request](gitlab-org/omnibus-gitlab!5123))
- [Use specified key size for self-signed certificate also](gitlab-org/omnibus-gitlab@fad9c0441b309cf1aa1ae5911d1039fd62c4614d) ([merge request](gitlab-org/omnibus-gitlab!5083))
- [Fix use_http2 & redirect_http GitLab Pages settings](gitlab-org/omnibus-gitlab@5afa8c3ed302f78e0688b4ffcda123f9c113aa42) ([merge request](gitlab-org/omnibus-gitlab!5116))
- [Update Gitaly log permissions in Docker image](gitlab-org/omnibus-gitlab@cd0d3666f8d0a6503466f91847029a02afb3e209) ([merge request](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5117))

### Changed (6 changes)

- [Change devops adoption update to be weekly](gitlab-org/omnibus-gitlab@abbd439e1c64cee4637cd9bf6623caf5ed3ec898) ([merge request](gitlab-org/omnibus-gitlab!5142))
- [Upgrade OpenSSL to 1.1.1k](gitlab-org/omnibus-gitlab@fadd066fcb28c14e86440640629648413bd18e85) ([merge request](gitlab-org/omnibus-gitlab!5140))
- [Add mail_room as a separate Gem dependency](gitlab-org/omnibus-gitlab@7926d212f199bff8ed3702be06b8adcabb3463be) ([merge request](gitlab-org/omnibus-gitlab!5122))
- [Disable statement timeout while running analyze for pg-upgrade](gitlab-org/omnibus-gitlab@1b0c2ce3a1e780df2467ab4c4770d0cda38a2be3) ([merge request](gitlab-org/omnibus-gitlab!5121))
- [Bump container registry version to v3.2.1](gitlab-org/omnibus-gitlab@9b0da5a1c51e4bfe186a7dbcd370dac9ed1d9977) ([merge request](gitlab-org/omnibus-gitlab!5111))
- [Bump Container Registry to v3.2.0-gitlab](gitlab-org/omnibus-gitlab@e852191df15ce4d49fb931fd14a9a8ad253e2589) ([merge request](gitlab-org/omnibus-gitlab!5097))

### Deprecated (1 change)

- [Add deprecation warning for openSUSE Leap 15.1](gitlab-org/omnibus-gitlab@04deb3c05eb489d342073b8d43b20f016abb88a9) ([merge request](gitlab-org/omnibus-gitlab!5135))

### Security (3 changes)

- [Only allow exiftool to process JPEG and TIFF files](gitlab-org/omnibus-gitlab@e52dc79d56bf7673c417a9aab8887222891958ae)
- [Bump PostgreSQL versions to 11.11 and 12.6](gitlab-org/omnibus-gitlab@363a4d13f830ae8e7939c018f28a8db637d05e87)
- [Update GraphicsMagick to 1.3.36](gitlab-org/omnibus-gitlab@8548cb9e419d91c526376ecf0bb988ecc32753b5) ([merge request](gitlab-org/omnibus-gitlab!5075))

### Performance (1 change)

- [Backport BLOCKED_MODULE performance fix from Redis unstable](gitlab-org/omnibus-gitlab@a9de7c8fe3a45d7f6a12271dda3b2524e6004afc) ([merge request](gitlab-org/omnibus-gitlab!5125))

### Other (2 changes)

- [Update grafana from 7.4.2 to 7.5.1](gitlab-org/omnibus-gitlab@f24acaa0eda025c8a2982770b1a012775a2e1ecc) ([merge request](gitlab-org/omnibus-gitlab!5041))
- [Update Mattermost to 5.33.3](gitlab-org/omnibus-gitlab@5ea328d92881bfc991582bf83bb3aba2a248aaad) ([merge request](gitlab-org/omnibus-gitlab!5151))

## 13.10.5 (2021-06-01)

No changes.

## 13.10.4 (2021-04-27)

### Security (2 changes)

- [Update Python to 3.7.10](gitlab-org/security/omnibus-gitlab@f893a4a8369c8d9ce077e71a3aec756f9b5aac47) ([merge request](gitlab-org/security/omnibus-gitlab!106))
- [Upgrade redis to 6.0.12](gitlab-org/security/omnibus-gitlab@b286c6ed65dfc1cac8c1d04545b610e8d205469b) ([merge request](gitlab-org/security/omnibus-gitlab!103))

## 13.10.3 (2021-04-13)

### Security (1 change)

- Only allow exiftool to process JPEG and TIFF files.

### Fixed (1 change)

- Update AWS Marketplace Release code to match new API requirements. !5146


## 13.10.2 (2021-04-01)

### Fixed (1 change)

- Update gitlab-exporter to avoid query failures. !5123


## 13.10.1 (2021-03-31)

### Security (1 change)

- Bump PostgreSQL versions to 11.11 and 12.6.


## 13.10.0 (2021-03-22)

### Removed (2 changes)

- Drop unused awesomeprint gem. !5023
- Remove upgrade survey. !5045

### Fixed (5 changes, 1 of them is from the community)

- gitlab-redis-cli: fix authentication with unquoted values. !5010
- Ensure that pg_basebackup will not ask for password. !5012
- Geo - Fix command to work with Patroni. !5033
- Fix postgresql['dir'] references in geo commands. !5061
- Fix gitlab pages on alternate port. !5070 (Lee Tickett @leetickett)

### Deprecated (1 change)

- Deprecate gitlab_pages['domain_config_source']. !5079

### Changed (10 changes, 1 of them is from the community)

- Add Grafana reporting option. !5000
- Update monitoring components. !5013
- Add internal and external URL config for KAS. !5016
- Add member option for command. !5025
- Update the package metadata vendor name to be GitLab, Inc. !5027
- Set permissions on assets that were copied into the container. !5036 (Edison Hanchell)
- Set Grafana auth scope based on allowed groups. !5038
- Bump Container Registry to v3.1.0-gitlab. !5054
- Use sha256 for signing RPM packages. !5072
- Remove recommended Pages max_connections limit. !5078

### Added (6 changes, 2 of them are from the community)

- Added Debian 10 ARM64 builds. !5018
- Add GitLab Pages propagate-correlation-id configuration parameter. !5043 (Ercan Ucan)
- Allow custom smtp configuration for grafana in omnibus-gitlab. !5047 (msschl)
- Expose Rails allowed_hosts setting in gitlab.rb. !5057
- Allow gitlab build remote overrides from the environment. !5067
- Add GitLab Pages cache configuration settings. !5084

### Other (7 changes, 2 of them are from the community)

- Add user_status_cleanup_batch cronjob. !5009
- Rename instance statistics count worker. !5021
- Explicitly set group for GitLab data directories. !5090 (Ben Bodenmiller (@bbodenmiller))
- Use builders with updated Go version. !5092
- Enable `nakayoshi_fork` by default.
- Update Mattermost to 5.32.1.
- Remove apt-transport-https as apt natively support https. (Simon Deziel)


## 13.9.7 (2021-04-27)

### Security (2 changes)

- [Update Python to 3.7.10](gitlab-org/security/omnibus-gitlab@ceab316d499057d89e63524e3f368dda8622eb79) ([merge request](gitlab-org/security/omnibus-gitlab!107))
- [Upgrade redis to 6.0.12](gitlab-org/security/omnibus-gitlab@54d594a01573ba5fbff173b0395e9e394373192a) ([merge request](gitlab-org/security/omnibus-gitlab!104))

## 13.9.6 (2021-04-13)

### Security (1 change)

- Only allow exiftool to process JPEG and TIFF files.

### Fixed (1 change)

- Update AWS Marketplace Release code to match new API requirements. !5146


## 13.9.5 (2021-03-31)

### Security (2 changes)

- Update openssl from 1i to 1j.
- Bump PostgreSQL versions to 11.11 and 12.6.


## 13.9.4 (2021-03-17)

- No changes.

## 13.9.3 (2021-03-08)

- No changes.

## 13.9.2 (2021-03-04)

- No changes.

## 13.9.1 (2021-02-23)

### Fixed (1 change)

- Ensure Marketplace AMIs have licenses embedded. !5031


## 13.9.0 (2021-02-22)

### Security (1 change)

- Add HTTP header to prevent content sniffing in /assets/* directory.

### Fixed (2 changes, 1 of them is from the community)

- Reconfigure nolonger errors in a FIPS environment. !4932
- configure sshd and git account so that pam is not used any longer in docker. !4953 (Fnordpol)

### Deprecated (2 changes)

- Add warning message to migration nodes for PG verisons older than 12. !4918
- Deprecate support for Ubuntu 16.04. !5006

### Changed (7 changes)

- Update libtiff to 4.2.0. !4859
- Make GitLab Docker image and AWS AMIs use Ubuntu 20.04 packages. !4876
- Raise warning if node attribute file can't be found. !4894
- Update logrotate to 3.18.0. !4902
- Upgrade Redis to 6.0.10. !4930
- Bump Container Registry to v3.0.0-gitlab. !4962
- Add redis config for gitlab-kas. !4974

### Performance (3 changes)

- Bump gitlab-exporter to 10.0.0, use jemalloc allocator. !4922
- Add Git refs performance patches. !4977
- Tune Ruby GC for gitlab-exporter. !4987

### Added (6 changes)

- Add application settings cache expiry to gitlab.rb. !4938
- Emit Ruby Prometheus metrics for gitlab-exporter. !4958
- Add flag to disable kernel parameter modification. !4967
- Add matomo_disable_cookies setting. !4979
- Add default replication factor configuration option to Praefect. !4988
- Patch Ruby 2.7 with counting memory allocations.

### Other (4 changes, 2 of them are from the community)

- Compile workhorse as part of gitlab-rails. !4829
- Remove Bundler 1.17.3 bundling. !4903 (Takuya Noguchi)
- Bump Grafana version to 7.3.7. !4933
- Update Mattermost to 5.31.1. !5003 (Harrison Healey)


## 13.8.8 (2021-04-13)

### Security (1 change)

- Only allow exiftool to process JPEG and TIFF files.


## 13.8.7 (2021-03-31)

### Security (2 changes)

- Update openssl from 1i to 1j.
- Bump PostgreSQL versions to 11.11 and 12.6.


## 13.8.6 (2021-03-17)

- No changes.

## 13.8.5 (2021-03-04)

- No changes.

## 13.8.4 (2021-02-11)

- No changes.

## 13.8.3 (2021-02-05)

### Fixed (1 change)

- Fix selinux nil error when workhorse is set to use tcp. !4978


## 13.8.2 (2021-02-01)

### Security (2 changes)

- Add patch for libxml2 CVE-2019-20388,CVE-2020-7595.
- Update PG11 and PG12 minor versions.


## 13.8.1 (2021-01-26)

### Fixed (1 change)

- Skip pages auth settings when access control is disabled. !4952


## 13.8.0 (2021-01-22)

### Security (1 change)

- Update OpenSSL to 1.1.1i. !4830

### Removed (2 changes)

- Remove `process_*` metrics from probes config. !4853
- Remove `git_process` metrics probes. !4863

### Fixed (4 changes)

- Patroni switchover and failover commands do not ask for user confirmation. !4909
- Fix https and custom domains pages settings. !4919
- Ensure EE services are considered disabled when on CE. !4927
- Safely lookup PostgreSQL parameters in Patroni settings. !4928

### Deprecated (1 change)

- Deprecate node['gitlab']['pgbouncer-exporter'] in favor of node['monitoring']['pgbouncer-exporter']. !4766

### Changed (10 changes)

- Update logrotate to 3.17.0. !4432
- Print PG11 deprecation notice. !4706
- Update consul to 1.6.10. !4789
- Update configs for Puma 5.1.0. !4803
- Generate Pages access control secrets only if access control is enabled. !4842
- Auto-upgrade to PG12 for single node installs. !4848
- Switch to enabling patroni by default with new patroni role. !4851
- Use more PostgreSQL attributes for Patroni parameters. !4857
- Add setting to change Rack server used for gitlab-exporter, bump it to 8.0.0. !4896
- Bump Container Registry to v2.13.1-gitlab. !4913

### Performance (1 change)

- Use Puma `nakayoshi_fork`. !4914

### Added (5 changes)

- Add support for configuring Workhorse alternate root path. !4856
- Add Patroni check-standby-leader command. !4864
- Expose setting for encrypted settings path. !4884
- Add logging to Let's Encrypt auto renewal cron job. !4911
- Add package upgrade survey link. !4931

### Other (6 changes, 3 of them are from the community)

- Bump Patroni to version 2.0.1. !4820
- Remove deprecated Prometheus settings from gitlab.yml. !4869
- Bump Grafana to 7.3.6. !4873
- Update Docker to 20.10 in our pipelines on CI/CD. !4878 (Takuya Noguchi)
- Use Debian 10 as examples in development docs. !4883 (Takuya Noguchi)
- Update Mattermost to 5.30.1. !4885 (hmhealey)


## 13.7.9 (2021-03-17)

- No changes.

## 13.7.8 (2021-03-04)

- No changes.

## 13.7.7 (2021-02-11)

- No changes.

## 13.7.6 (2021-02-01)

### Security (3 changes)

- Update OpenSSL to 1.1.1i.
- Update PG11 and PG12 minor versions.
- Add patch for libxml2 CVE-2019-20388,CVE-2020-7595.


## 13.7.5 (2021-01-25)

### Fixed (2 changes)

- Patroni switchover and failover commands do not ask for user confirmation. !4909
- Fix https and custom domains pages settings. !4919


## 13.7.4 (2021-01-13)

- No changes.

## 13.7.3 (2021-01-08)

- No changes.

## 13.7.2 (2021-01-07)

### Security (2 changes)

- Patch bundler to not use insecure temp directory as home.
- Update curl to 7_74_0.


## 13.7.1 (2020-12-23)

### Fixed (1 change)

- Ensure patroni and consul remain up during upgrade migrations. !4854


## 13.7.0 (2020-12-22)

### Fixed (8 changes)

- Improve PostgreSQL service status check. !4672
- Switch to gitlab:db:active for GEO replication. !4763
- Make Build::Check.on_tag? silent. !4769
- Update Promethes and Grafana. !4774
- Fix shmmax for arm64. !4799
- Increase jemalloc page size on arm64. !4800
- Exclude windows .ruby files from gems. !4838
- Fix incorrect deprecation warning for Sidekiq experimental queue selector. !4839

### Deprecated (1 change)

- Remove CentOS 6 Builds. !4782

### Changed (11 changes, 1 of them is from the community)

- Update OpenSSL to 1.1.1h. !4593
- Rename Piwik config items after rebranding to Matomo. !4667 (Katrin Leinweber @katrinleinweber)
- Update libjpeg-turbo to 2.0.6. !4765
- Default to PostgreSQL 12 in fresh installs. !4777
- Use the configurable PostgreSQL readiness check for Patroni. !4787
- Bump Container Registry to v2.12.0-gitlab. !4796
- PostgreSQL status helper should not fail fast. !4798
- Always `pg_rewind` when Patroni primary resumes. !4810
- Update gitlab-kas to v13.7.0. !4817
- Generate warning on consul configuration change. !4828
- Add install survey link to package installation. !4845

### Performance (2 changes)

- Update gitlab-exporter to v7.1.1. !4783
- Adjust Postgres memory settings to current best practice. !4788

### Added (11 changes)

- Generate encrypted_settings_key_base rails secret. !4687
- Patroni: reinitialize-replica command. !4692
- Add centos 8 arm64 packages. !4743
- Add Pages zip configuration flags. !4754
- Allow PostgreSQL adapter tcp parameter tuning. !4776
- Add /database_bloat endpoint for gitlab-exporter. !4785
- Add support for configuring database application_name for Rails. !4808
- Add options for Patroni pg_rewind assumptions. !4811
- Add devops adoption worker settings. !4812
- Add FortiToken Cloud configuration to gitlab.rb. !4824
- Allow setting Gitaly cgroups configuration. !4837

### Other (4 changes, 1 of them is from the community)

- Bump consul version to 1.6.4. !3802
- pages: Support for HTTPS over PROXYv2 protocol. !4760
- Use the 'main' branch for gitlab-shell nightlies. !4772
- Update Mattermost to 5.29.1. !4807 (hmhealey)


## 13.6.7 (2021-02-11)

- No changes.

## 13.6.6 (2021-02-01)

### Security (3 changes)

- Update OpenSSL to 1.1.1i.
- Update PG11 and PG12 minor versions.
- Add patch for libxml2 CVE-2019-20388,CVE-2020-7595.


## 13.6.5 (2021-01-13)

- No changes.

## 13.6.4 (2021-01-07)

### Security (2 changes)

- Patch bundler to not use insecure temp directory as home.
- Update curl to 7_74_0.


## 13.6.3 (2020-12-10)

### Fixed (1 change)

- Fix Unicorn custom socket not being honored by Workhorse. !4778


## 13.6.2 (2020-12-07)

### Security (3 changes)

- Update GnuPG to version 2.2.23.
- Update libxml2 to version 2.9.10.
- Update GraphicsMagick to 1.3.35 and patch PNG vulnerability.


## 13.6.1 (2020-11-23)

- No changes.

## 13.6.0 (2020-11-22)

### Security (1 change)

- Set instance ID as root password on AMI instance startup. !4638

### Fixed (6 changes)

- Add support for custom database ports to pg_upgrade. !4665
- Use PostgreSQL's default values to override Patroni dynamic config. !4677
- Ensure pg_rewind can be used and won't fail for Patroni. !4689
- Restart Gitaly when Ruby version changes. !4696
- Use license_finder on GitLab Workhorse. !4705
- Drop --with-cflags gRPC argument from Raspberry Pi build. !4711

### Changed (4 changes)

- logrotate defaults: set notifempty so empty files are not rotated. !3820
- Support for alternative auth_types in pgbouncer. !4671
- Mark Sidekiq queue selector as no longer experimental. !4714
- Bump Container Registry to v2.11.0-gitlab. !4741

### Performance (2 changes)

- Update postgres_exporter metrics. !4586
- Update Prometheus components. !4682

### Added (7 changes)

- Support gitlab-shell ssl_cert_dir config setting. !4379
- Add google_tag_manager_id configuration. !4473
- Allow setting Gitaly's git.bin_path. !4668
- Upgrade Git to v2.29.0. !4690
- Instruct more cleary how to proceed when old failed PostgreSQL upgrades exist on disk. !4694
- Display root account username at the end of first reconfigure. !4712
- Add role for GitLab Pages. !4740

### Other (12 changes)

- Upgrade Ruby to v2.7.2. !4632
- Add Image Resizer config defaults. !4639
- Clean up pg_query gem native extension directory. !4683
- Clean up nokogumbo extension dir. !4698
- Exclude exe files from Python libraries from the package. !4699
- Ensure users are using Patroni before upgrading PG to 12. !4700
- Bump development Ruby version to v2.7.2. !4703
- Add note about backing up gitlab.rb in Docker. !4707
- Update Grafana version to 7.3.1. !4722
- Update GITLAB_KAS_VERSION to 13.6.1. !4742
- Update rake to v13. !4745
- Update Mattermost to 5.28.1.


## 13.5.7 (2021-01-13)

- No changes.

## 13.5.6 (2021-01-07)

### Security (2 changes)

- Patch bundler to not use insecure temp directory as home.
- Update curl to 7_74_0.


## 13.5.5 (2020-12-07)

### Security (3 changes)

- Update GnuPG to version 2.2.23.
- Update libxml2 to version 2.9.10.
- Update GraphicsMagick to 1.3.35 and patch PNG vulnerability.


## 13.5.4 (2020-11-13)

- No changes.

## 13.5.3 (2020-11-03)

### Fixed (1 change)

- Geo: Perform point-in-time recovery before promotion of secondary node. !4636

### Performance (1 change)

- Set net.core.somaxconn kernel parameter for Puma. !4688


## 13.5.2 (2020-11-02)

- No changes.

## 13.5.1 (2020-10-22)

### Fixed (1 change)

- Ensure group is set before mode in storage_directory. !4661


## 13.5.0 (2020-10-22)

### Fixed (10 changes, 2 of them are from the community)

- Configure pg-upgrade to work with patroni service. !4529
- Exit non-zero during upgrade if reconfigure fails. !4591
- Remove EE only note for packages in gitlab.yml.erb. !4594 (Ben Bodenmiller (@bbodenmiller))
- Add selinux module for gitlab-shell. !4598
- Support geo data dir for pg-upgrade. !4603
- Allows special characters in Grafana admin password. !4606
- Update workhorse auth socket when puma uses custom socket. !4620
- Error during docker build on package download failure. !4641
- Fix onsolidated form object storage configuration template. !4656
- Fix libatomic package name for RHEL/CentOS. !4660 (Hi Key @HiKey)

### Deprecated (1 change)

- Add deprecation warning for CentOS 6. !4596

### Changed (6 changes)

- Update Chef from 15.12.22 to 15.14.0. !4537
- Update unixcharles/acme-client from 2.0.6 to 2.0.7. !4581
- Only send one Referrer-Policy header. !4584
- Make Gitaly internal API calls go through Workhorse. !4592
- Add support for cert authentication with PostgreSQL. !4618
- Remove extraneous rbtrace files from build. !4647

### Added (14 changes)

- Allow configuring permanent replication slots in patroni. !4534
- Allow bootstrapping patroni Standby Cluster. !4558
- Gitaly daily maintenance config. !4572
- Add gitlab-kas to omnibus. !4579
- Praefect configuration for database with no proxy. !4583
- Add wrappers for Patroni restart and reload commands. !4601
- Add database reindexing cronjob. !4602
- Add Kerberos LDAP mapping configuration. !4608
- Allow promotion task to alter Geo node configuration. !4609
- Support revert-pg-upgrade for Patroni cluster nodes. !4611
- Specify display_version for sofware without proper version string. !4622
- Add pages object storage settings. !4623
- Expose wal_log_hints PostgreSQL setting. !4642
- Add FortiAuthenticator configuration to gitlab.rb. !4645

### Other (7 changes, 1 of them is from the community)

- Remove Praefect primary config. !4559
- Add member invitation reminder emails cron worker. !4582
- Explicitly set group for repositories_storages and improve manage-storage-directories tests. !4589 (Ben Bodenmiller (@bbodenmiller))
- Remove ee/spec from final package. !4621
- Move email configuration section closer to SMTP settings in template. !4631
- Reduce Ubuntu 20 ARM package size. !4637
- Update Mattermost to 5.27.0.


## 13.4.7 (2020-12-07)

### Security (3 changes)

- Update GnuPG to version 2.2.23.
- Update libxml2 to version 2.9.10.
- Update GraphicsMagick to 1.3.35 and patch PNG vulnerability.


## 13.4.6 (2020-11-03)

### Fixed (1 change)

- Geo: Perform point-in-time recovery before promotion of secondary node. !4636


## 13.4.5 (2020-11-02)

- No changes.

## 13.4.4 (2020-10-15)

### Fixed (1 change)

- Force install PrettyTable 0.7. !4628


## 13.4.3 (2020-10-06)

- No changes.

## 13.4.2 (2020-10-01)

### Security (1 change)

- Add config for remove unaccepted member invites cron worker.


## 13.4.1 (2020-09-24)

- No changes.

## 13.4.0 (2020-09-22)

### Security (3 changes, 3 of them are from the community)

- Update Python to 3.7.9. !4544 (Takuya Noguchi)
- Update PostgreSQL 11 from 11.7 to 11.9. !4545 (Takuya Noguchi)
- Update PostgreSQL 12 from 12.3 to 12.4. !4546 (Takuya Noguchi)

### Fixed (6 changes, 2 of them are from the community)

- Remove stub_status => on from nginx status on gitlab.rb config file. !4500 (Kelvin Jasperson)
- fix: remove useless query string match and disable buffering for artifacts. !4516 (Chieh-Min Wang)
- Reload PostgreSQL configuration when Patroni is enabled. !4548
- Fix missing gitlab-geo.conf when initiating replication. !4556
- Improve pgbouncer running? method. !4557
- Move TLS below Prometheus in Praefect config. !4575

### Changed (8 changes, 1 of them is from the community)

- Allow Prometheus external_labels to be configured. !4494 (Chris Weyl @rsrchboy)
- Update replicate-geo-database to support PostgreSQL 12. !4495
- Make gitlab-shell go through Workhorse. !4498
- Added ability to disable a previously enabled consul service. !4502
- Geo: Add final confirmation for promotion to primary. !4523
- Upgrade GnuPG related software. !4525
- Add guidance for setting the timeout value for PG upgrades. !4563
- Add option to enable Sidekiq Exporter logs. !4573

### Performance (1 change)

- Inline Gitaly gRPC recording rule. !4561

### Added (6 changes)

- Add auto_link_user setting. !4415
- Add arm64 package for ubuntu 20.04. !4478
- Add Azure Blob Storage configuration. !4505
- Build openSUSE 15.1 arm64. !4535
- Add PostgreSQL connect_timeout parameter. !4555
- Add Praefect reconciliation config options. !4571

### Other (7 changes)

- Update Prometheus components. !4303
- Expose Consul api_url to gitlab.yml. !4482
- Add prometheus recording rule for database query Apdex. !4489
- Cron worker settings for CI platform target metrics. !4526
- Address TODOs for removing legacy attribute support. !4533
- Add instance statistics cron worker. !4567
- Update Mattermost to 5.26.2.


## 13.3.9 (2020-11-02)

- No changes.

## 13.3.8 (2020-10-21)

- No changes.

## 13.3.6 (2020-09-14)

- No changes.

## 13.3.5 (2020-09-04)

### Fixed (1 change)

- Fix geo fdw deprecation message. !4528


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


## 13.2.9 (2020-09-04)

### Fixed (1 change)

- Add rhel 8 to helper and selinux files. !4501


## 13.2.8 (2020-09-02)

- No changes.

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


## 13.1.10 (2020-09-02)

- No changes.

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
- Fixed pg upgrade for separate geo tracking db. !4091
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

- Fix prometheus duplicate rule. !3891


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
- Do not cleanup old gitlab-monitor directory if explicitly using it. !3634
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
- Add smartcard_san_extensions to gitlab.rb. !3566

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
- Properly check whether postgres is enabled when doing pg-upgrade. !3381
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
- Properly check whether postgres is enabled when doing pg-upgrade. !3381
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
- Properly check whether postgres is enabled when doing pg-upgrade. !3381
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
- Make migrations during upgrade only stop unnecessary services

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
- Bump Git version to 2.13.5
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
- Default redis prometheus exporter to off if redis is not managed locally 63056441
- Default postgres prometheus exporter to off if postgres is not managed locally 63056441
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

- Expose artifacts configuration options 4aca77a5ae78a836cc9f3be060afacc3c4e72a28
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
- Add backup encryption option for AWS backups 8562644f3dfe44b6faed35f8e0769a0b7c202569
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
