---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Microsoft Graph Mailer設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.5で[導入されました](https://gitlab.com/groups/gitlab-org/-/work_items/8259)。

{{< /history >}}

前提条件: 

- Microsoft Graph APIを使用してメールを送信するには、まずAzure Active Directoryで[アプリケーションを作成](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)し、`Mail.Send` [アプリケーションのアクセス許可](https://learn.microsoft.com/en-us/graph/permissions-reference)を追加する必要があります。
- アプリケーションのアクセス許可を**App-only access**に設定します。アクセス許可が**Delegated**に設定されていないことを確認してください。

アプリケーションメールを送信する場合は、[Microsoft Graph API](https://learn.microsoft.com/en-us/graph/api/user-sendmail?view=graph-rest-1.0&tabs=http)と[OAuth 2.0クライアント認証情報フロー](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow)を使用して、次の設定情報を`/etc/gitlab/gitlab.rb`に追加し、`gitlab-ctl reconfigure`を実行してください。

```ruby
# The originating email address for outgoing mail
gitlab_rails['gitlab_email_from'] = '<YOUR_ACCOUNT_EMAIL>'

# The reply-to email address
gitlab_rails['gitlab_email_reply_to'] = '<YOUR_ACCOUNT_EMAIL>'

gitlab_rails['microsoft_graph_mailer_enabled'] = true

# The unique identifier for the user. To use Microsoft Graph on behalf of the user.
gitlab_rails['microsoft_graph_mailer_user_id'] = "<YOUR_USER_ID>"

# The directory tenant the application plans to operate against, in GUID or domain-name format.
gitlab_rails['microsoft_graph_mailer_tenant'] = "<YOUR_TENANT_ID>"

# The application ID that's assigned to your app. You can find this information in the portal where you registered your app.
gitlab_rails['microsoft_graph_mailer_client_id'] = "<YOUR_CLIENT_ID>"

# The client secret that you generated for your app in the app registration portal.
gitlab_rails['microsoft_graph_mailer_client_secret'] = "<YOUR_CLIENT_SECRET_ID>"

gitlab_rails['microsoft_graph_mailer_azure_ad_endpoint'] = "https://login.microsoftonline.com"

gitlab_rails['microsoft_graph_mailer_graph_endpoint'] = "https://graph.microsoft.com"
```

## トラブルシューティング {#troubleshooting}

### `ErrorSendAsDenied` {#errorsendasdenied}

完全なエラーメッセージは次のとおりです:

```plaintext
"ErrorSendAsDenied","message":"The user account which was used to submit this request does not have the right to send mail on behalf of the specified sending account., Cannot submit message."
```

このエラーを解決するには:

1. APIアクセス許可を確認して、アクセス許可が正しいことを検証するには、[アプリケーションのアクセス許可](https://learn.microsoft.com/en-us/graph/permissions-reference)を確認してください。
1. 次のフィールドを使用しているアカウントのメールアドレスに設定します:
   - `gitlab_rails['gitlab_email_from']`。
   - `gitlab_rails['gitlab_email_reply_to']`。

アクセス許可以外にも、サーバーがデフォルトの`gitlab_email_from`値の使用を許可していないためにこのエラーが発生する場合があります。この値を、認証に使用するアカウントのメールアドレスに設定する必要があります。

### `Tail logs` {#tail-logs}

トラブルシューティングの場合、`tail logs`コマンドを使用してライブのGitLabログの更新を表示します:

```ruby
# Tail all logs for the application
sudo gitlab-ctl tail

# Tail logs for an application sub-directory
sudo gitlab-ctl tail gitlab-rails

# Tail logs for an individual file in the application
sudo gitlab-ctl tail nginx/gitlab_error.log
```

これらのコマンドを停止するには、<kbd>Control</kbd>+<kbd>C</kbd>を押します。
