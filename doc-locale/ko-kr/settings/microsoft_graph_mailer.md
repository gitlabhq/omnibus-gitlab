---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Microsoft Graph Mailer 설정
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [GitLab 15.5에서 도입됨](https://gitlab.com/groups/gitlab-org/-/epics/8259).

{{< /history >}}

전제 조건:

- Microsoft Graph API를 사용하여 메일을 보내려면 먼저 Azure Active Directory에서 [애플리케이션을 만들어야](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app) 하고 `Mail.Send` [애플리케이션 권한](https://learn.microsoft.com/en-us/graph/permissions-reference)을 추가해야 합니다.
- 애플리케이션 권한을 **App-only access**로 설정합니다. 권한이 **Delegated**으로 설정되지 않았는지 확인합니다.

대신 [Microsoft Graph API](https://learn.microsoft.com/en-us/graph/api/user-sendmail?view=graph-rest-1.0&tabs=http) 를 사용하여 애플리케이션 이메일을 [OAuth 2.0 클라이언트 자격 증명 플로우](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow)로 보내려면 `/etc/gitlab/gitlab.rb`에 다음 구성 정보를 추가하고 `gitlab-ctl reconfigure`을 실행합니다.

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

## 문제 해결 {#troubleshooting}

### `ErrorSendAsDenied` {#errorsendasdenied}

전체 오류 메시지는 다음과 같습니다:

```plaintext
"ErrorSendAsDenied","message":"The user account which was used to submit this request does not have the right to send mail on behalf of the specified sending account., Cannot submit message."
```

이 오류를 해결하려면:

1. [애플리케이션 권한](https://learn.microsoft.com/en-us/graph/permissions-reference)을 검토하여 API 권한이 올바른지 확인합니다.
1. 다음 필드를 사용 중인 계정의 이메일 주소로 설정합니다:
   - `gitlab_rails['gitlab_email_from']`.
   - `gitlab_rails['gitlab_email_reply_to']`.

권한 외에도 이 오류는 때때로 서버에서 기본 `gitlab_email_from` 값을 사용하도록 허용하지 않기 때문에 발생합니다. 값을 인증하는 데 사용 중인 계정의 이메일 주소로 설정해야 합니다.

### `Tail logs` {#tail-logs}

문제 해결을 위해 `tail logs` 명령을 사용하여 실시간 GitLab 로그 업데이트를 확인합니다:

```ruby
# Tail all logs for the application
sudo gitlab-ctl tail

# Tail logs for an application sub-directory
sudo gitlab-ctl tail gitlab-rails

# Tail logs for an individual file in the application
sudo gitlab-ctl tail nginx/gitlab_error.log
```

이러한 명령을 중지하려면 <kbd>Control</kbd>+<kbd>C</kbd>를 누르세요.
