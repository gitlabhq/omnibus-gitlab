---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループアクセストークンを利用するためのVault連携
---

このドキュメントでは、Omnibus GitLabがHashiCorp Vaultとインテグレーションして、ビルド中にプライベートリポジトリにアクセスするためのグループアクセストークンを取得する方法について説明します。

## 概要 {#overview}

GitLabパッケージをビルドする際、Omnibusはセキュリティに機密性の高いコンポーネントを含むプライベートリポジトリにアクセスする必要があります。以前は、これは広範な権限を持つ`CI_JOB_TOKEN`ユーザーからの`gitlab-bot`を使用して処理されていました。[`infra-mgmt`](https://gitlab.com/gitlab-com/gl-infra/infra-mgmt)でのミラー設定の一元化により、現在ではVaultに保存されている専用のグループアクセストークンを使用しています。

## グループアクセストークン {#group-access-token}

グループアクセストークンは、次のパスのVaultに保存されます:

```shell
ci/metadata/access_tokens/gitlab-com/gitlab-org/security/_group_access_tokens/build-token
```

このトークンには、以下が含まれます:

- **ロール**: デベロッパー
- **スコープ**: `read_repository`
- **アクセス**: GitLab.comセキュリティグループとそのプロジェクト

## CI設定 {#ci-configuration}

### Vaultインテグレーションテンプレート {#vault-integration-template}

`.with-build-token`テンプレートは、以下を提供します:

1. **IDトークンの設定**: VaultとのJSON Webトークン認証をセットアップします
1. **条件付きシークレットの取得**: セキュリティプロジェクトでは、Vaultから`SECURITY_PRIVATE_TOKEN`を自動的にフェッチします
1. **環境のセットアップ**: 必要に応じて、セキュアなリポジトリへのアクセスを有効にします

テンプレートの動作は、プロジェクトのコンテキストに基づいて自動的に適応します:

- **セキュリティプロジェクト**（`$SECURITY_PROJECT_PATH`）: Vaultから`SECURITY_PRIVATE_TOKEN`を含めます
- **その他のプロジェクト**: セキュリティトークンなしで基本的なVaultインテグレーションを提供します

### ジョブでの使用 {#usage-in-jobs}

Vaultインテグレーションを必要とするジョブは、`.with-build-token`テンプレートを拡張する必要があります:

```yaml
my-build-job:
  extends: .with-build-token
  script:
    -  # Your build commands here
    -  # SECURITY_PRIVATE_TOKEN is automatically available in security builds
```

## 仕組み {#how-it-works}

1. **認証**: ジョブは、GitLab JSON Webトークントークンを使用してVaultで認証を行います
1. **Token Retrieval**（トークンの取得）: グループアクセストークンは、Vaultからフェッチされ、`SECURITY_PRIVATE_TOKEN`として設定されます

## トラブルシューティング {#troubleshooting}

### トークンが利用できません {#token-not-available}

`SECURITY_PRIVATE_TOKEN`が見つからないというエラーが表示された場合:

1. セキュリティプロジェクト（`$CI_PROJECT_PATH == $SECURITY_PROJECT_PATH`）で実行していることを確認します
1. ジョブが`.with-build-token`を拡張していることを確認します
1. `gitlab-ci-config/vault-security-secrets.yml`でVaultのパスが正しいことを確認してください

### リポジトリへのアクセスが拒否されました {#repository-access-denied}

リポジトリへのアクセス時に403エラーが発生した場合:

1. グループアクセストークンに正しい権限があることを確認します
1. `ALTERNATIVE_SOURCES`または`SECURITY_SOURCES`が有効になっていることを確認します
1. リポジトリがセキュリティグループのアクセススコープ内にあることを確認します

### Vault認証の問題 {#vault-authentication-issues}

Vault認証が失敗した場合:

1. `VAULT_ID_TOKEN`が正しく設定されていることを確認します
1. `aud`フィールドがVaultサーバーのURLと一致することを確認します
1. GitLabプロジェクトに必要なVaultロール権限があることを確認します
