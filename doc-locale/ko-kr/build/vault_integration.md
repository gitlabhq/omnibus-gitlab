---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 액세스 토큰을 위한 Vault 통합
---

이 문서는 Omnibus GitLab이 HashiCorp Vault와 통합되어 빌드 중에 비공개 리포지토리에 액세스하기 위한 그룹 액세스 토큰을 검색하는 방법을 설명합니다.

## 개요 {#overview}

GitLab 패키지를 빌드할 때 Omnibus는 보안에 민감한 구성 요소를 포함하는 비공개 리포지토리에 액세스해야 합니다. 이전에는 광범위한 권한이 있던 `CI_JOB_TOKEN` 사용자의 `gitlab-bot`를 사용하여 처리했습니다. [`infra-mgmt`](https://gitlab.com/gitlab-com/gl-infra/infra-mgmt)에서 미러 구성이 중앙 집중화됨에 따라, 이제 Vault에 저장된 전용 그룹 액세스 토큰을 사용합니다.

## 그룹 액세스 토큰 {#group-access-token}

그룹 액세스 토큰은 다음 경로의 Vault에 저장됩니다:

```shell
ci/metadata/access_tokens/gitlab-com/gitlab-org/security/_group_access_tokens/build-token
```

이 토큰의 속성은 다음과 같습니다:

- **역할**:  개발자
- **범위**: `read_repository`
- **액세스**:  GitLab.com 보안 그룹 및 해당 프로젝트

## CI 구성 {#ci-configuration}

### Vault 통합 템플릿 {#vault-integration-template}

`.with-build-token` 템플릿은 다음을 제공합니다:

1. **ID Token Configuration**:  Vault를 사용하여 JWT 인증을 설정합니다
1. **Conditional Secret Retrieval**:  보안 프로젝트에서 Vault에서 `SECURITY_PRIVATE_TOKEN`를 자동으로 가져옵니다
1. **Environment Setup**:  필요할 때 보안 리포지토리 액세스를 활성화합니다

템플릿 동작은 프로젝트 컨텍스트에 따라 자동으로 조정됩니다:

- **Security projects** (`$SECURITY_PROJECT_PATH`):  Vault에서 `SECURITY_PRIVATE_TOKEN`를 포함합니다
- **기타 프로젝트**:  보안 토큰 없이 기본 Vault 통합을 제공합니다

### 작업에서의 사용 {#usage-in-jobs}

Vault 통합이 필요한 작업은 `.with-build-token` 템플릿을 확장해야 합니다:

```yaml
my-build-job:
  extends: .with-build-token
  script:
    -  # Your build commands here
    -  # SECURITY_PRIVATE_TOKEN is automatically available in security builds
```

## 작동 방식 {#how-it-works}

1. **인증**:  작업은 GitLab JWT 토큰을 사용하여 Vault로 인증합니다
1. **Token Retrieval**:  그룹 액세스 토큰을 Vault에서 가져와 `SECURITY_PRIVATE_TOKEN`로 설정합니다

## 문제 해결 {#troubleshooting}

### 토큰을 사용할 수 없음 {#token-not-available}

`SECURITY_PRIVATE_TOKEN`에 대한 누락 오류가 표시되는 경우:

1. 보안 프로젝트에서 실행 중인지 확인하세요 (`$CI_PROJECT_PATH == $SECURITY_PROJECT_PATH`)
1. 작업이 `.with-build-token`을 확장하는지 확인하세요
1. Vault 경로가 `gitlab-ci-config/vault-security-secrets.yml`에서 올바른지 확인하세요

### 리포지토리 액세스 거부됨 {#repository-access-denied}

리포지토리에 액세스할 때 403 오류가 발생하는 경우:

1. 그룹 액세스 토큰에 올바른 권한이 있는지 확인하세요
1. `ALTERNATIVE_SOURCES` 또는 `SECURITY_SOURCES`이 활성화되어 있는지 확인하세요
1. 리포지토리가 보안 그룹의 범위 내에 있는지 확인하세요

### Vault 인증 이슈 {#vault-authentication-issues}

Vault 인증이 실패하는 경우:

1. `VAULT_ID_TOKEN`이 올바르게 구성되어 있는지 확인하세요
1. `aud` 필드가 Vault 서버 URL과 일치하는지 확인하세요
1. GitLab 프로젝트에 필요한 Vault 역할 권한이 있는지 확인하세요
