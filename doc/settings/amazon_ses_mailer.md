---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Amazon SES Mailer settings
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/3655) in GitLab 19.3.

{{< /history >}}

To send application emails using the [Amazon SES API](https://docs.aws.amazon.com/ses/latest/dg/send-email-api.html),
add the following configuration to `/etc/gitlab/gitlab.rb` and run `gitlab-ctl reconfigure`.

> [!warning]
> If you enabled SMTP, set `gitlab_rails['smtp_enable']` to `false`. When SMTP is enabled,
> it overrides the Amazon SES mailer, and GitLab sends email through SMTP.

## Authenticate with an IAM role

To authenticate with an IAM role, provide the role Amazon Resource Name (ARN).
Credentials are obtained through AWS Security Token Service (STS).

```ruby
gitlab_rails['amazon_ses_mailer_enabled'] = true
gitlab_rails['amazon_ses_mailer_region'] = "<your_aws_region>"
gitlab_rails['amazon_ses_mailer_role_arn'] = "arn:aws:iam::123456789012:role/<your_role>"
```

## Authenticate with static keys

To authenticate with static keys, provide the access key ID and secret access key.

```ruby
gitlab_rails['amazon_ses_mailer_enabled'] = true
gitlab_rails['amazon_ses_mailer_region'] = "<your_aws_region>"
gitlab_rails['amazon_ses_mailer_access_key_id'] = "<your_aws_access_key_id>"
gitlab_rails['amazon_ses_mailer_secret_access_key'] = "<your_aws_secret_access_key>"
```

## Authenticate with the AWS credential provider chain

When you omit `role_arn`, `access_key_id`, and `secret_access_key`, GitLab falls back to the
[AWS credential provider chain](https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/credential-providers.html#credchain).
The chain checks credentials from sources such as environment variables, a shared profile, ECS,
and EC2.

```ruby
gitlab_rails['amazon_ses_mailer_enabled'] = true
gitlab_rails['amazon_ses_mailer_region'] = "<your_aws_region>"
```
