# Vault Integration for Group Access Tokens

This document describes how Omnibus GitLab integrates with HashiCorp Vault to retrieve Group Access Tokens for accessing private repositories during builds.

## Overview

When building GitLab packages, Omnibus needs to access private repositories that contain security-sensitive components. Previously, this was handled using the `CI_JOB_TOKEN` from the `gitlab-bot` user, which had broad permissions. With the centralization of mirror configurations in `infra-mgmt`, we now use a dedicated Group Access Token stored in Vault.

## Group Access Token

The Group Access Token is stored in Vault at the following path:
```
ci/metadata/access_tokens/gitlab-com/gitlab-org/security/_group_access_tokens/build-token
```

This token has:
- **Role**: Developer
- **Scope**: `read_repository`
- **Access**: GitLab.com security group and its projects

## CI Configuration

### Vault Integration Template

The `.with-build-token` template in `gitlab-ci-config/vault-integration.yml` provides:

1. **ID Token Configuration**: Sets up JWT authentication with Vault
2. **Secret Retrieval**: Automatically fetches the `ALTERNATIVE_PRIVATE_TOKEN` from Vault
3. **Environment Setup**: Enables `ALTERNATIVE_SOURCES` for private repository access

### Usage in Jobs

Jobs that need access to private repositories should extend the `.with-build-token` template:

```yaml
my-build-job:
  extends: .with-build-token
  script:
    - # Your build commands here
    - # ALTERNATIVE_PRIVATE_TOKEN is automatically available
```

## How It Works

1. **Authentication**: Jobs authenticate with Vault using GitLab's JWT token
2. **Token Retrieval**: The Group Access Token is fetched from Vault and set as `ALTERNATIVE_PRIVATE_TOKEN`
3. **Repository Access**: `lib/gitlab/version.rb` uses this token to access private repositories when:
   - `ALTERNATIVE_SOURCES` is enabled, or
   - `SECURITY_SOURCES` is enabled for security builds

## Code Integration

The `lib/gitlab/version.rb` file has been updated to:

1. **Prioritize Build Token**: Use `ALTERNATIVE_PRIVATE_TOKEN` when available
2. **Fallback Gracefully**: Fall back to `CI_JOB_TOKEN` if the build token is not available
3. **Support Security Sources**: Handle both alternative and security source channels

## Migration Benefits

1. **Security**: Reduced token scope (read-only repository access)
2. **Maintainability**: Centralized token management through Vault
3. **Compatibility**: Seamless integration with existing `infra-mgmt` workflows
4. **Reliability**: Automatic token rotation capabilities

## Troubleshooting

### Token Not Available

If you see errors about missing `ALTERNATIVE_PRIVATE_TOKEN`:

1. Ensure your job extends `.with-build-token` or `.with-security-build-token`
2. Check that the Vault path is correct in `gitlab-ci-config/vault-integration.yml`
3. Verify the job has the necessary `id_tokens` configuration

### Repository Access Denied

If you get 403 errors when accessing repositories:

1. Verify the Group Access Token has the correct permissions
2. Check that `ALTERNATIVE_SOURCES` or `SECURITY_SOURCES` is enabled
3. Ensure the repository is within the security group's access scope

### Vault Authentication Issues

If Vault authentication fails:

1. Check that `VAULT_ID_TOKEN` is properly configured
2. Verify the `aud` field matches the Vault server URL
3. Ensure the GitLab project has the necessary Vault role permissions