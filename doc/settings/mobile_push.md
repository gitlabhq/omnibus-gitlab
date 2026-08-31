---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mobile push notification settings
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248026) in GitLab 19.3 [with flags](https://docs.gitlab.com/administration/feature_flags/) named `mobile_push_registration_api`, `mobile_push_notifications_dispatch`, and `mobile_push_notifications`. Disabled by default.

{{< /history >}}

GitLab can deliver mobile push notifications for to-dos through the Apple Push
Notification service (APNs), using Apple provider token (p8) authentication.
Delivery is skipped entirely when no signing key is configured.

The server-side feature is controlled by
[feature flags](https://docs.gitlab.com/administration/feature_flags/) that are
disabled by default: `mobile_push_registration_api` gates the
[mobile push subscriptions API](https://docs.gitlab.com/api/mobile_push_subscriptions/)
that devices register with, and `mobile_push_notifications_dispatch` and
`mobile_push_notifications` gate delivery. Devices cannot register and no
pushes are delivered until an administrator enables all three.

Prerequisites:

- An [APNs provider token signing key](https://developer.apple.com/documentation/usernotifications/establishing-a-token-based-connection-to-apns)
  (`.p8` file) from an Apple Developer account, together with its key ID and
  the Apple Developer team ID.

To configure APNs delivery:

1. Copy the `.p8` signing key to a path readable by GitLab, for example
   `/etc/gitlab/mobile_push_apns_auth_key.p8`, and restrict access to it:

   ```shell
   sudo chown git:root /etc/gitlab/mobile_push_apns_auth_key.p8
   sudo chmod 0400 /etc/gitlab/mobile_push_apns_auth_key.p8
   ```

   `/etc/gitlab` is world-readable, so without the `chmod` a plain copy
   leaves the private signing key readable by every local user. The key must
   stay readable by the `git` user: a root-only key passes
   `gitlab-ctl reconfigure` (which runs as `root`) but silently breaks
   delivery for the application (which runs as `git`).

1. Add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['mobile_push_apns_auth_key_path'] = "/etc/gitlab/mobile_push_apns_auth_key.p8"
   gitlab_rails['mobile_push_apns_key_id'] = "YOUR-APNS-KEY-ID"
   gitlab_rails['mobile_push_apns_team_id'] = "YOUR-APPLE-TEAM-ID"
   ```

   Optionally, set `gitlab_rails['mobile_push_apns_topic']` to override the
   `apns-topic` header sent for device subscriptions that don't carry a
   bundle identifier. When unset, the topic defaults to
   `com.gitlab-mobile.app`.

1. Save the file and run `gitlab-ctl reconfigure`.

The auth key path, key ID, and team ID must all be set together:
`gitlab-ctl reconfigure` fails when only some of them are set. If no file
exists at the configured key path, reconfigure prints a warning, and APNs
delivery fails until the key is placed there and is readable by the `git`
user.

Device registration is exposed through the
[mobile push subscriptions API](https://docs.gitlab.com/api/mobile_push_subscriptions/).
