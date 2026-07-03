---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Vaultとグループアクセストークンのインテグレーション
---

このドキュメントでは、Omnibus GitLabがHashiCorp Vaultとどのようにインテグレーションして、ビルド中にプライベートリポジトリにアクセスするためのグループアクセストークンを取得するかを説明します。

## 概要 {#overview}

GitLabのパッケージをビルドする際、Omnibusはセキュリティ上重要なコンポーネントを含むプライベートリポジトリにアクセスする必要があります。以前は、広範な権限を持つ`gitlab-bot`ユーザーからの`CI_JOB_TOKEN`を使用して処理されていました。ミラー設定の[`infra-mgmt`](https://gitlab.com/gitlab-com/gl-infra/infra-mgmt)への一元化により、現在ではVaultに格納された専用のグループアクセストークンを使用しています。

## グループアクセストークン {#group-access-token}

このグループアクセストークンは、Vaultの次のパスに保存されています:

```shell
ci/metadata/access_tokens/gitlab-com/gitlab-org/security/_group_access_tokens/build-token
```

このトークンには、次のものがあります:

- **ロール**: デベロッパー
- **スコープ**: `read_repository`
- **アクセス**: GitLab.comのセキュリティグループとそのプロジェクト

## CI設定 {#ci-configuration}

### Vaultインテグレーションテンプレート {#vault-integration-template}

`.with-build-token`テンプレートは以下を提供します:

1. **IDトークン設定**: VaultによるJWT認証を設定します。
1. **条件付きシークレット取得**: セキュリティプロジェクトでは、Vaultから`SECURITY_PRIVATE_TOKEN`を自動的にフェッチします。
1. **環境設定**: 必要に応じて安全なリポジトリアクセスを有効にします

テンプレートの動作は、プロジェクトのコンテキストに基づいて自動的に適応します:

- **セキュリティプロジェクト** (`$SECURITY_PROJECT_PATH`): Vaultから`SECURITY_PRIVATE_TOKEN`を含めます
- **その他のプロジェクト**: セキュリティトークンなしで基本的なVaultインテグレーションを提供します

### ジョブでの使用 {#usage-in-jobs}

Vaultインテグレーションが必要なジョブは、`.with-build-token`テンプレートを拡張する必要があります:

```yaml
my-build-job:
  extends: .with-build-token
  script:
    -  # Your build commands here
    -  # SECURITY_PRIVATE_TOKEN is automatically available in security builds
```

## 仕組み {#how-it-works}

1. **認証**: ジョブはGitLab JWTトークンを使用してVaultで認証します
1. **トークン取得**: グループアクセストークンはVaultからフェッチされ、`SECURITY_PRIVATE_TOKEN`として設定されます。

## トラブルシューティング {#troubleshooting}

### トークンが利用できません {#token-not-available}

`SECURITY_PRIVATE_TOKEN`が見つからないというエラーが表示される場合:

1. セキュリティプロジェクト (`$CI_PROJECT_PATH == $SECURITY_PROJECT_PATH`) で実行していることを確認します
1. あなたのジョブが`.with-build-token`を拡張していることを確認します
1. Vaultのパスが`gitlab-ci-config/vault-security-secrets.yml`で正しいことを確認します

### リポジトリへのアクセスが拒否されました {#repository-access-denied}

リポジトリにアクセスするときに403エラーが発生する場合:

1. グループアクセストークンが正しい権限を持っていることを確認します
1. `ALTERNATIVE_SOURCES`または`SECURITY_SOURCES`が有効になっていることを確認します
1. リポジトリがセキュリティグループのアクセススコープ内にあることを確認します

### Vault認証の問題 {#vault-authentication-issues}

Vault認証が失敗する場合:

1. `VAULT_ID_TOKEN`が適切に設定されていることを確認します
1. `aud`フィールドがVaultサーバーURLと一致することを確認します
1. GitLabプロジェクトに必要なVaultロール権限があることを確認します
