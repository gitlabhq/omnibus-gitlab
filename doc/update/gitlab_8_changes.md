# GitLab 8 specific changes

## Updating from GitLab `8.10` and lower to `8.11` or newer

GitLab 8.11 introduces new key names for several secrets, to match the GitLab
Rails app and clarify the use of the secrets. For most installations, this
process should be transparent as the 8.11 and higher packages will try to
migrate the existing secrets to the new key names.

## Migrating legacy secrets

These keys have been migrated from old names:

- `gitlab_rails['otp_key_base']` is used for encrypting the OTP secrets in the
  database. Changing this secret will stop two-factor auth from working for all
  users. Previously called `gitlab_rails['secret_token']`
- `gitlab_rails['db_key_base']` is used for encrypting import credentials and CI
  secret variables. Previously called `gitlab_ci['db_key_base']`; **note** that
  `gitlab_rails['db_key_base']` was not previously used for this - setting it
  would have no effect
- `gitlab_rails['secret_key_base']` is used for password reset links, and other
  'standard' auth features. Previously called `gitlab_ci['db_key_base']`;
  **note** that `gitlab_rails['secret_token']` was not previously used for this,
  despite the name

These keys were not used any more, and have simply been removed:

- `gitlab_ci['secret_token']`
- `gitlab_ci['secret_key_base']`
