---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab 15 specific changes **(FREE SELF)**

NOTE:
When upgrading to a new major version, remember to first [check for background migrations](https://docs.gitlab.com/ee/update/index.html#checking-for-background-migrations-before-upgrading).

## 15.0

### AES256-GCM-SHA384 SSL cipher no longer allowed by default by NGINX

Starting with GitLab 15.0, the `AES256-GCM-SHA384` SSL cipher will not be allowed by
NGINX by default. If you require this cipher (for example, if you use
[AWS's Classic Load Balancer](https://docs.aws.amazon.com/en_en/elasticloadbalancing/latest/classic/elb-ssl-security-policy.html#ssl-ciphers)),
you can add the cipher back to the allow list by following the steps below:

1. Edit `/etc/gitlab/gitlab.rb` and add the following line to it:

   ```ruby
   nginx['ssl_ciphers'] = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:AES256-GCM-SHA384"
   ```

1. Run `sudo gitlab-ctl reconfigure`.

### Removing support for Gitaly's internal socket path

In 14.10, [Gitaly introduced a new directory](gitlab_14_changes.md#gitaly-runtime-directory) that holds all runtime data Gitaly requires to operate correctly. This new directory replaces the old internal socket directory, and consequentially the usage of `gitaly['internal_socket_dir']` was deprecated in favor of `gitaly['runtime_dir']`.

The old `gitaly['internal_socket_dir']` configuration was removed in this release.
