---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Vault Integration for Group Access Tokens
---

This document describes how Omnibus GitLab integrates with HashiCorp Vault to retrieve Group Access Tokens for accessing private repositories during builds.

## Overview

When building GitLab packages, Omnibus needs to access private repositories that contain security-sensitive components. Previously, this was handled using the `CI_JOB_TOKEN` from the `gitlab-bot` user, which had broad permissions. With the centralization of mirror configurations in [`infra-mgmt`](https://gitlab.com/gitlab-com/gl-infra/infra-mgmt), we now use a dedicated Group Access Token stored in Vault.

## Group Access Token

The Group Access Token is stored in Vault at the following path:

```shell
ci/metadata/access_tokens/gitlab-com/gitlab-org/security/_group_access_tokens/build-token
```

This token has:

- **Role**: Developer
- **Scope**: `read_repository`
- **Access**: GitLab.com security group and its projects

## CI Configuration

### Vault Integration Template

The `.with-build-token` template provides:

1. **ID Token Configuration**: Sets up JWT authentication with Vault
1. **Conditional Secret Retrieval**: In security projects, automatically fetches the `SECURITY_PRIVATE_TOKEN` from Vault
1. **Environment Setup**: Enables secure repository access when needed

The template behavior automatically adapts based on the project context:

- **Security projects** (`$SECURITY_PROJECT_PATH`): Include `SECURITY_PRIVATE_TOKEN` from Vault
- **Other projects**: Provide basic Vault integration without security tokens

### Usage in Jobs

Jobs that need Vault integration should extend the `.with-build-token` template:

```yaml
my-build-job:
  extends: .with-build-token
  script:
    -  # Your build commands here
    -  # SECURITY_PRIVATE_TOKEN is automatically available in security builds
```

## How It Works

1. **Authentication**: Jobs authenticate with Vault using a GitLab JWT token
1. **Token Retrieval**: The Group Access Token is fetched from Vault and set as `SECURITY_PRIVATE_TOKEN`

## Troubleshooting

### Token Not Available

If you see errors about missing `SECURITY_PRIVATE_TOKEN`:

1. Verify you're running in a security project (`$CI_PROJECT_PATH == $SECURITY_PROJECT_PATH`)
1. Ensure your job extends `.with-build-token`
1. Check that the Vault path is correct in `gitlab-ci-config/vault-security-secrets.yml`

### Repository Access Denied

If you get 403 errors when accessing repositories:

1. Verify the Group Access Token has the correct permissions
1. Check that `ALTERNATIVE_SOURCES` or `SECURITY_SOURCES` is enabled
1. Ensure the repository is within the security group's access scope

### Vault Authentication Issues

If Vault authentication fails:

1. Check that `VAULT_ID_TOKEN` is properly configured
1. Verify the `aud` field matches the Vault server URL
1. Ensure the GitLab project has the necessary Vault role permissions
