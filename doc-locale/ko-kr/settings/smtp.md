---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SMTP 설정
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Sendmail 또는 Postfix 대신 SMTP 서버를 통해 애플리케이션 이메일을 보내려면 `/etc/gitlab/gitlab.rb`에 다음 구성 정보를 추가하고 `gitlab-ctl reconfigure`을(를) 실행합니다.

> [!warning]
> `smtp_password`은(는) Ruby 또는 YAML에 사용되는 문자열 구분 기호(예: `'`)를 포함하지 않아야 하므로 구성 설정 처리 중 예기치 않은 동작을 방지할 수 있습니다.

[예제 구성](#example-configurations)이 이 페이지의 끝에 있습니다.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.server"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "smtp user"
gitlab_rails['smtp_password'] = "smtp password"
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

# If your SMTP server does not like the default 'From: gitlab@localhost' you
# can change the 'From' with this setting.
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@example.com'

# If your SMTP server is using a self signed certificate or a certificate which
# is signed by a CA which is not trusted by default, you can specify a custom ca file.
# Please note that the certificates from /etc/gitlab/trusted-certs/ are
# not used for the verification of the SMTP server certificate.
gitlab_rails['smtp_ca_file'] = '/path/to/your/cacert.pem'
```

## SMTP 연결 풀링 {#smtp-connection-pooling}

다음 설정으로 SMTP 연결 풀링을 활성화할 수 있습니다:

```ruby
gitlab_rails['smtp_pool'] = true
```

이를 통해 Sidekiq 워커는 여러 작업에 대해 SMTP 연결을 재사용할 수 있습니다. 풀의 최대 연결 수는 [Sidekiq의 최대 동시성 구성](https://docs.gitlab.com/administration/sidekiq/extra_sidekiq_processes/#concurrency)을 따릅니다.

## 암호화된 자격 증명 사용 {#using-encrypted-credentials}

SMTP 자격 증명을 구성 파일에 일반 텍스트로 저장하는 대신 SMTP 자격 증명에 암호화된 파일을 사용할 수 있습니다. 이 기능을 사용하려면 먼저 [GitLab 암호화된 구성](https://docs.gitlab.com/administration/encrypted_configuration/)을 활성화해야 합니다.

SMTP의 암호화된 구성은 암호화된 YAML 파일에 있습니다. 기본적으로 파일은 `/var/opt/gitlab/gitlab-rails/shared/encrypted_settings/smtp.yaml.enc`에 생성됩니다. 이 위치는 GitLab 구성에서 설정할 수 있습니다.

파일의 암호화되지 않은 내용은 `smtp_*'` 설정에서 `gitlab_rails` 구성 블록의 설정 하위 집합이어야 합니다.

암호화된 파일에서 지원되는 구성 항목은 다음과 같습니다:

- `user_name`
- `password`

암호화된 내용은 [SMTP 비밀 편집 Rake 명령](https://docs.gitlab.com/administration/raketasks/smtp/)으로 구성할 수 있습니다.

`/etc/gitlab/gitlab.rb`의 SMTP 구성이 다음과 같은 경우를 예로 들어보겠습니다:

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.server"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "smtp user"
gitlab_rails['smtp_password'] = "smtp password"
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
```

다시 구성하려면:

1. 암호화된 비밀을 편집합니다:

   ```shell
   sudo gitlab-rake gitlab:smtp:secret:edit EDITOR=vim
   ```

1. SMTP 비밀의 암호화되지 않은 내용을 다음과 같이 입력합니다:

   ```yaml
   user_name: 'smtp user'
   password: 'smtp password'
   ```

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 `smtp_user_name` 및 `smtp_password`의 설정을 제거합니다.
1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 예제 구성 {#example-configurations}

### localhost의 SMTP {#smtp-on-localhost}

이 구성은 SMTP를 단순히 활성화하고 기타 기본 설정을 사용하며 `sendmail` 인터페이스를 제공하지 않거나 GitLab과 호환되지 않는 `sendmail` 인터페이스를 제공하는 localhost에서 실행되는 MTA(예: Exim)에 사용할 수 있습니다.

```ruby
gitlab_rails['smtp_enable'] = true
```

### SSL 없는 SMTP {#smtp-without-ssl}

기본적으로 SMTP에는 SSL이 활성화되어 있습니다. SMTP 서버가 SSL을 통한 통신을 지원하지 않는 경우 다음 설정을 사용합니다:

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = 'localhost'
gitlab_rails['smtp_port'] = 25
gitlab_rails['smtp_domain'] = 'localhost'
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_ssl'] = false
gitlab_rails['smtp_force_ssl'] = false
```

### Gmail {#gmail}

전제 조건:

- [2단계 인증 활성화됨](https://support.google.com/accounts/answer/185839).
- [앱 비밀번호](https://support.google.com/mail/answer/185833).

> [!note]
> Gmail의 [엄격한 전송 제한](https://support.google.com/a/answer/166852)은 조직이 성장함에 따라 기능을 저하시킬 수 있습니다. SMTP 구성을 사용하는 팀을 위해 [SendGrid](https://sendgrid.com/en-us) 또는 [Mailgun](https://www.mailgun.com/)과 같은 트랜잭션 서비스를 사용할 것을 강력히 권장합니다.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.gmail.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "my.email@gmail.com"
gitlab_rails['smtp_password'] = "my-gmail-password"
gitlab_rails['smtp_domain'] = "smtp.gmail.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'peer' # Can be: 'none', 'peer', 'client_once', 'fail_if_no_peer_cert', see http://api.rubyonrails.org/classes/ActionMailer/Base.html
```

_`my.email@gmail.com`을(를) 이메일 주소로, `my-gmail-password`을(를) 자신의 비밀번호로 변경하는 것을 잊지 마세요._

### Google SMTP 릴레이 {#google-smtp-relay}

Google을 통해 비Gmail 발신 메시지를 라우팅할 수 있습니다([Google SMTP 릴레이 서비스 사용](https://support.google.com/a/answer/2956491?hl=en)).

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp-relay.gmail.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_domain'] = "yourdomain.com"
gitlab_rails['gitlab_email_from'] = 'username@yourdomain.com'
gitlab_rails['gitlab_email_reply_to'] = 'username@yourdomain.com'
```

### Mailgun {#mailgun}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.mailgun.org"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_user_name'] = "postmaster@mg.gitlab.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "mg.gitlab.com"
```

### Amazon Simple Email Service (AWS SES) {#amazon-simple-email-service-aws-ses}

- STARTTLS 사용

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "email-smtp.region-1.amazonaws.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "IAMmailerKey"
gitlab_rails['smtp_password'] = "IAMmailerSecret"
gitlab_rails['smtp_domain'] = "yourdomain.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

ACL 및 보안 그룹에서 포트 587을 통한 아웃바운드 연결이 허용되는지 확인합니다.

- TLS 래퍼 사용

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "email-smtp.region-1.amazonaws.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "IAMmailerKey"
gitlab_rails['smtp_password'] = "IAMmailerSecret"
gitlab_rails['smtp_domain'] = "yourdomain.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_ssl'] = true
gitlab_rails['smtp_force_ssl'] = true
```

ACL 및 보안 그룹에서 포트 465를 통한 아웃바운드 연결이 허용되는지 확인합니다.

### Mandrill {#mandrill}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.mandrillapp.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "MandrillUsername"
gitlab_rails['smtp_password'] = "MandrillApiKey" # https://mandrillapp.com/settings
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### SMTP.com {#smtpcom}

[SMTP.com](https://www.smtp.com/) 이메일 서비스를 사용할 수 있습니다. 계정에서 [발신자 로그인 및 비밀번호를 검색](https://knowledge.smtp.com/s/article/My-Account)합니다.

`SMTP.com`이(가) 사용자 도메인을 대신하여 이메일을 보내도록 허가하여 전달 성능을 향상시키려면 다음을 수행해야 합니다:

- GitLab 도메인 이름을 사용하여 `from` 및 `reply_to` 주소를 지정합니다.
- [도메인에 대해 SPF 및 DKIM을 설정](https://knowledge.smtp.com/s/article/Email-authentication-SPF-DKIM-DMARC)합니다.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = 'send.smtp.com'
gitlab_rails['smtp_port'] = 25 # If your outgoing port 25 is blocked, try 2525, 2082
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_authentication'] = 'plain'
gitlab_rails['smtp_user_name'] = 'your_sender_login'
gitlab_rails['smtp_password'] = 'your_sender_password'
gitlab_rails['smtp_domain'] = 'your.gitlab.domain.com'
gitlab_rails['gitlab_email_from'] = 'user@your.gitlab.domain.com'
gitlab_rails['gitlab_email_reply_to'] = 'user@your.gitlab.domain.com'
```

추가 지원을 받으려면 [SMTP.com 지식 기반](https://knowledge.smtp.com/s/)을 확인하세요.

### SparkPost {#sparkpost}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.sparkpostmail.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "SMTP_Injection"
gitlab_rails['smtp_password'] = "SparkPost_API_KEY" # https://app.sparkpost.com/account/credentials
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### Gandi {#gandi}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.gandi.net"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_user_name'] = "your.email@domain.com"
gitlab_rails['smtp_password'] = "your.password"
gitlab_rails['smtp_domain'] = "domain.com"
gitlab_rails['gitlab_email_from'] = 'gitlab@domain.com'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@domain.com'
```

### Zoho Mail {#zoho-mail}

이 구성은 Zoho Mail과 사용자 정의 도메인으로 테스트되었습니다.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.zoho.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_user_name'] = "gitlab@mydomain.com"
gitlab_rails['smtp_password'] = "mypassword"
gitlab_rails['smtp_domain'] = "smtp.zoho.com"
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@example.com'
```

### SiteAge, LLC Zimbra Mail {#siteage-llc-zimbra-mail}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = 'mail.siteage.net'
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = 'gitlab@domain.com'
gitlab_rails['smtp_password'] = 'password'
gitlab_rails['smtp_authentication'] = 'login'
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['gitlab_email_from'] = "gitlab@domain.com"
gitlab_rails['smtp_tls'] = true
```

### OVH {#ovh}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "ssl0.ovh.net"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "ssl0.ovh.net"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### Outlook {#outlook}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp-mail.outlook.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "username@outlook.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "smtp-mail.outlook.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
```

### Office365 {#office365}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.office365.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "username@yourdomain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "yourdomain.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
gitlab_rails['gitlab_email_from'] = 'username@yourdomain.com'
```

### Office365 릴레이 {#office365-relay}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "your mx endpoint"
gitlab_rails['smtp_port'] = 25
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_domain'] = "yourdomain.com"
gitlab_rails['gitlab_email_from'] = 'username@yourdomain.com'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@yourdomain.com'
```

### Online.net {#onlinenet}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtpauth.online.net"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "online.net"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### Prolateral outMail {#prolateral-outmail}

Prolateral에서 제공하는 [outMail](https://www.prolateral.com/email-services/outmail-outgoing-smtp/outmail-outgoing-smtp-server.html) 서비스를 사용할 수 있습니다.

outMail이 사용자 도메인을 대신하여 이메일을 보내도록 허가하여 전달 성능을 향상시키려면 다음을 수행해야 합니다:

- GitLab 도메인 이름을 사용하여 올바른 발신자 및 회신 주소를 지정합니다.
- outMail을 포함하도록 유효한 [SPF (Sender Policy Framework)](https://www.prolateral.com/help/kb/dns-engine/457-what-is-a-spf-record.html) 레코드를 설정합니다.
- outMail이 [DKIM (DomainKeys Identified Mail)](https://www.prolateral.com/help/kb/outmail/643-how-do-i-enable-dkim-signing-of-emails-through-outmail.html) GitLab 이메일을 서명하도록 합니다.

도메인 이름의 책임 있는 이메일 발신자로서 [DMARC (Domain-based Message Authentication, Reporting, and Conformance)](https://www.prolateral.com/help/kb/outmail/647-what-is-dmarc-what-is-its-purpose-and-why-it-is-important.html) 정책 추가도 고려해야 합니다.

outMail 서비스 세부 정보에 액세스하려면 Prolateral 관리 포털에 로그인하고 outMail 서비스 설정으로 이동한 후 다음과 같은 적절한 값으로 GitLab을 구성합니다:

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = '<mxXXXXXX.smtp-engine.com>' # Please see your outMail service settings in the Prolateral portal
gitlab_rails['smtp_port'] = 587 # Alternate SMTP ports are available, 25, 465, 2525, and 8025
gitlab_rails['smtp_user_name'] = '<outmail-username>' # Please see your outMail service settings in the Prolateral portal
gitlab_rails['smtp_password'] = '<outmail-password>'  # Please see your outMail service settings in the Prolateral portal
gitlab_rails['smtp_domain'] = 'example.com'
gitlab_rails['gitlab_email_from'] = 'user@example.com'
gitlab_rails['gitlab_email_reply_to'] = 'user@example.com'
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_authentication'] = 'login'
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
```

TCP 포트 465를 사용하는 경우 관련 줄을 다음과 같이 변경합니다:

```ruby
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_tls'] = true
```

### Amen.fr / Securemail.pro {#amenfr--securemailpro}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp-fr.securemail.pro"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_tls'] = true
```

### 1&1 {#11}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.1and1.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "my.email@domain.com"
gitlab_rails['smtp_password'] = "1and1-email-password"
gitlab_rails['smtp_domain'] = "domain.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### yahoo {#yahoo}

```ruby
gitlab_rails['gitlab_email_from'] = 'user@yahoo.com'
gitlab_rails['gitlab_email_reply_to'] = 'user@yahoo.com'

gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.mail.yahoo.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "user@yahoo.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
```

### QQ exmail {#qq-exmail}

QQ exmail (腾讯企业邮箱)

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.exmail.qq.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "xxxx@xx.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['gitlab_email_from'] = 'xxxx@xx.com'
gitlab_rails['smtp_domain'] = "exmail.qq.com"
```

### NetEase Free Enterprise Email {#netease-free-enterprise-email}

NetEase Free Enterprise Email (网易免费企业邮)

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.ym.163.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "xxxx@xx.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['gitlab_email_from'] = 'xxxx@xx.com'
gitlab_rails['smtp_domain'] = "smtp.ym.163.com"
```

### 사용자 이름/비밀번호 인증을 사용하는 SendGrid {#sendgrid-with-usernamepassword-authentication}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.sendgrid.net"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "a_sendgrid_crendential"
gitlab_rails['smtp_password'] = "a_sendgrid_password"
gitlab_rails['smtp_domain'] = "smtp.sendgrid.net"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
```

### API 키 인증을 사용하는 SendGrid {#sendgrid-with-api-key-authentication}

사용자 이름/비밀번호를 제공하지 않으려면 [API 키](https://www.twilio.com/docs/sendgrid/for-developers/sending-email/getting-started-smtp)를 사용할 수 있습니다:

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.sendgrid.net"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "apikey"
gitlab_rails['smtp_password'] = "the_api_key_you_created"
gitlab_rails['smtp_domain'] = "smtp.sendgrid.net"
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
# If use Single Sender Verification You must configure from. If not fail
# 550 The from address does not match a verified Sender Identity. Mail cannot be sent until this error is resolved.
# Visit https://sendgrid.com/docs/for-developers/sending-email/sender-identity/ to see the Sender Identity requirements
gitlab_rails['gitlab_email_from'] = 'email@sender_owner_api'
gitlab_rails['gitlab_email_reply_to'] = 'email@sender_owner_reply_api'
```

`smtp_user_name`은(는) 문자 그대로 `"apikey"`로 설정되어야 합니다. 생성한 API 키는 `smtp_password`에 입력해야 합니다.

### Brevo {#brevo}

이 구성은 Brevo [SMTP 릴레이 서비스](https://www.brevo.com/free-smtp-server/)로 테스트되었습니다. 이 예제에서 주석으로 처리된 URL을 통해 관련 계정 자격 증명을 얻으려면 [Brevo 계정에 로그인](https://login.brevo.com)합니다.

자세한 내용은 Brevo [도움말 페이지](https://help.brevo.com/hc/en-us/articles/209462765-What-is-Brevo-SMTP)를 참조하세요.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp-relay.sendinblue.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "<username@example.com>" # https://app.brevo.com/settings/keys/smtp
gitlab_rails['smtp_password'] = "<password>"              # https://app.brevo.com/settings/keys/smtp
gitlab_rails['smtp_domain'] = "<example.com>"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['gitlab_email_from'] = '<gitlab@example.com>'
gitlab_rails['gitlab_email_reply_to'] = '<noreply@example.com>'
```

### SMTP2GO {#smtp2go}

이 구성은 [SMTP2GO](https://www.smtp2go.com/)를 사용하여 테스트되었습니다. 이 예제에서 주석으로 처리된 URL을 사용하여 관련 계정 자격 증명을 얻으려면 [SMTP2GO 계정에 로그인](https://app.smtp2go.com/login/)합니다.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.smtp2go.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "<username>"    # https://app.smtp2go.com/settings/users
gitlab_rails['smtp_password'] = "<password>"     # https://app.smtp2go.com/settings/users
gitlab_rails['smtp_domain'] = "<example.com>"    # https://app.smtp2go.com/settings/sender_domains
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
```

### Yandex {#yandex}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.yandex.ru"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "login"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "yourdomain_or_yandex.ru"
gitlab_rails['gitlab_email_from'] = 'login_or_login@yandex.ru'
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
```

### UD Media {#ud-media}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.udXX.udmedia.de" # Replace XX, see smtp server information: https://www.udmedia.de/login/mail/
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "login"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
```

### Microsoft Exchange (인증 없음) {#microsoft-exchange-no-authentication}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "example.com"
gitlab_rails['smtp_port'] = 25
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### Microsoft Exchange (인증 포함) {#microsoft-exchange-with-authentication}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.example.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = 'password'
gitlab_rails['smtp_domain'] = "mail.example.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### Strato.de {#stratode}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.strato.de"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@stratodomain.de"
gitlab_rails['smtp_password'] = "strato_email_password"
gitlab_rails['smtp_domain'] = "stratodomain.de"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### Rackspace {#rackspace}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "secure.emailsrvr.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "domain.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

gitlab_rails['gitlab_email_from'] = 'username@domain.com'
gitlab_rails['gitlab_email_reply_to'] = 'username@domain.com'
```

### DomainFactory (df.eu) {#domainfactory-dfeu}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "sslout.df.eu"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "domain.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### Infomaniak (infomaniak.com) {#infomaniak-infomaniakcom}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.infomaniak.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "mail.infomaniak.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_ssl'] = true
```

### GoDaddy (TLS) {#godaddy-tls}

- 유럽 서버: smtpout.europe.secureserver.net
- 아시아 서버: smtpout.asia.secureserver.net
- 글로벌(US) 서버: smtpout.secureserver.net

```ruby
gitlab_rails['gitlab_email_from'] = 'username@domain.com'

gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtpout.secureserver.net"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "domain.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
```

### GoDaddy (TLS 없음) {#godaddy-no-tls}

메일 서버 목록은 위의 GoDaddy (TLS) 항목을 참조하세요.

```ruby
gitlab_rails['gitlab_email_from'] = 'username@domain.com'

gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtpout.secureserver.net"
gitlab_rails['smtp_port'] = 80
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "domain.com"
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = false
```

### OpenSRS (hostedemail.com) {#opensrs-hostedemailcom}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.hostedemail.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "domain.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

gitlab_rails['gitlab_email_from'] = 'username@domain.com'
gitlab_rails['gitlab_email_reply_to'] = 'username@domain.com'
```

### Aruba (aruba.it) {#aruba-arubait}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtps.aruba.it"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "user@yourdomain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "yourdomain.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_ssl'] = true
```

### Alibaba Cloud Direct Mail (TLS 없음) {#alibaba-cloud-direct-mail-no-tls}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtpdm-ap-southeast-1.aliyun.com"    # Set to the Direct Mail service region in use, refer to: https://www.alibabacloud.com/help/en/directmail/latest/smtp-service-address
gitlab_rails['smtp_port'] = 80
gitlab_rails['smtp_user_name'] = "<username@example.com>"            # Direct Mail sender address
gitlab_rails['smtp_password'] = "<password>"                         # Set Direct Mail password
gitlab_rails['smtp_domain'] = "<example.com>"                        # Email domain configured in Direct Mail
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
gitlab_rails['gitlab_email_from'] = "<username@example.com>"         # Email domain configured in Direct Mail
```

### Alibaba Cloud Direct Mail (TLS) {#alibaba-cloud-direct-mail-tls}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtpdm-ap-southeast-1.aliyun.com"    # Set to the Direct Mail service region in use, refer to: https://www.alibabacloud.com/help/en/directmail/latest/smtp-service-address
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "<username@example.com>"            # Direct Mail sender address
gitlab_rails['smtp_password'] = "<password>"                         # Set Direct Mail password
gitlab_rails['smtp_domain'] = "<example.com>"                        # Email domain configured in Direct Mail
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['gitlab_email_from'] = "<username@example.com>"         # Email domain configured in Direct Mail
```

### Aliyun Direct Mail {#aliyun-direct-mail}

Aliyun Direct Mail (阿里云邮件推送)

```ruby
gitlab_rails['gitlab_email_from'] = 'username@your domain'
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtpdm.aliyun.com"
gitlab_rails['smtp_port'] = 80
gitlab_rails['smtp_user_name'] = "username@your domain"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "your domain"
gitlab_rails['smtp_authentication'] = "login"
```

### Aliyun Enterprise Mail with TLS {#aliyun-enterprise-mail-with-tls}

Aliyun Enterprise Mail with TLS (阿里企业邮箱)

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.qiye.aliyun.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@your domain"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "your domain"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
```

### FastMail {#fastmail}

FastMail은 2단계 인증이 활성화되지 않은 경우에도 [앱 비밀번호](https://www.fastmail.help/hc/en-us/articles/360058752854-App-passwords)가 필요합니다.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.fastmail.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "account@fastmail.com"
gitlab_rails['smtp_password'] = "app-specific-password"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
```

### Dinahosting {#dinahosting}

```ruby
gitlab_rails['gitlab_email_from'] = 'username@example.com'
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "example-com.correoseguro.dinaserver.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "username-example-com"
gitlab_rails['smtp_password'] = "mypassword"
gitlab_rails['smtp_domain'] = "example-com.correoseguro.dinaserver.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
```

### GMX Mail {#gmx-mail}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.gmx.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "my-gitlab@gmx.com"
gitlab_rails['smtp_password'] = "Pa5svv()rD"
gitlab_rails['smtp_domain'] = "mail.gmx.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

### Email Settings
gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = 'my-gitlab@gmx.com'
gitlab_rails['gitlab_email_display_name'] = 'My GitLab'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@gmx.com'
```

### Hetzner {#hetzner}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.your-server.de"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "user@example.com"
gitlab_rails['smtp_password'] = "mypassword"
gitlab_rails['smtp_domain'] = "mail.your-server.de"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['gitlab_email_from'] = "example@example.com"
```

### Snel.com {#snelcom}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtprelay.snel.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_authentication'] = false
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['gitlab_email_from'] = "example@example.com"
gitlab_rails['gitlab_email_reply_to'] = "example@example.com"
```

### JangoSMTP {#jangosmtp}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "express-relay.jangosmtp.net"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_user_name'] = "your.username"
gitlab_rails['smtp_password'] = "your.password"
gitlab_rails['smtp_domain'] = "domain.com"
gitlab_rails['gitlab_email_from'] = 'gitlab@domain.com'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@domain.com'
```

### Mailjet {#mailjet}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "in-v3.mailjet.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "mailjet-api-key"
gitlab_rails['smtp_password'] = "mailjet-secret-key"
gitlab_rails['smtp_domain'] = "in-v3.mailjet.com"
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['gitlab_email_from'] = 'gitlab@domain.com'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@domain.com'
```

### Mailcow {#mailcow}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.example.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "yourmail@example.com"
gitlab_rails['smtp_password'] = "yourpassword"
gitlab_rails['smtp_domain'] = "smtp.example.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### ALL-INKL.COM {#all-inklcom}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "<userserver>.kasserver.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "<username>"
gitlab_rails['smtp_password'] = "<password>"
gitlab_rails['smtp_domain'] = "<your.domain>"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_tls'] = true
```

### webgo.de {#webgode}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "sXX.goserver.host" # or serverXX.webgo24.de
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "webXXXpX"
gitlab_rails['smtp_password'] = "Your Password"
gitlab_rails['smtp_domain'] = "sXX.goserver.host" # or serverXX.webgo24.de
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['gitlab_email_from'] = 'Your Mail Address'
gitlab_rails['gitlab_email_reply_to'] = 'Your Mail Address'
```

### mxhichina.com {#mxhichinacom}

```ruby
gitlab_rails['gitlab_email_from'] = "username@company.com"
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.mxhichina.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@company.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "mxhichina.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
```

### Postmark {#postmark}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.postmarkapp.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "your_api_token"
gitlab_rails['smtp_password'] = "your_api_token"
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@example.com'
```

### easyDNS (아웃바운드 메일) {#easydns-outbound-mail}

[제어판](https://cp.easydns.com/manage/domains/mail/outbound/)에서 사용 가능한지 확인하고 구성 설정을 확인합니다.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mailout.easydns.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_force_ssl'] = true
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_user_name'] = "example.com"
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_password'] = "password_you_set"
gitlab_rails['gitlab_email_from'] = 'no-reply@git.example.com'
```

### Campaign Monitor {#campaign-monitor}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.api.createsend.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "your_api_token" # Menu > Transactional > Send with SMTP > SMTP tokens > Token
gitlab_rails['smtp_password'] = "your_api_token"  # Same as gitlab_rails['smtp_user_name'] value
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@example.com'
```

### Freehostia {#freehostia}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mbox.freehostia.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@example.com"
gitlab_rails['smtp_password'] = "password_you_set"
gitlab_rails['smtp_domain'] = "mbox.freehostia.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### Mailbox.org {#mailboxorg}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.mailbox.org"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@example.com"
gitlab_rails['smtp_password'] = "password_you_set"
gitlab_rails['smtp_domain'] = "smtp.mailbox.org"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### Mittwald CM Service (mittwald.de) {#mittwald-cm-service-mittwaldde}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.agenturserver.de"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "username@example.com"
gitlab_rails['smtp_password'] = "password_you_set"
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true

gitlab_rails['gitlab_email_from'] = "username@example.com"
gitlab_rails['gitlab_email_reply_to'] = "username@example.com"
```

### Unitymedia (.de) {#unitymedia-de}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "submit.unitybox.de"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "username@unitybox.de"
gitlab_rails['smtp_password'] = "yourPassword"
gitlab_rails['smtp_domain'] = "submit.unitybox.de"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@example.com'
```

### united-domains AG (united-domains.de) {#united-domains-ag-united-domainsde}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.udag.de"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "example-com-0001"
gitlab_rails['smtp_password'] = "smtppassword"
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
gitlab_rails['gitlab_email_display_name'] = 'GitLab - my company'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@example.com'
```

### IONOS by 1&1 (ionos.de) {#ionos-by-11-ionosde}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.ionos.de"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "your-user@your-domain.de"
gitlab_rails['smtp_password'] = "Y0uR_Pass_H3r3"
gitlab_rails['smtp_domain'] = "your-domain.de"
gitlab_rails['smtp_authentication'] = 'login'
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
gitlab_rails['gitlab_email_from'] = 'your-user@your-domain.de'
```

### AWS Workmail {#aws-workmail}

[AWS Workmail 설명서](https://docs.aws.amazon.com/workmail/latest/userguide/using_IMAP.html)에서:

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.server"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "smtp user"
gitlab_rails['smtp_password'] = "smtp password"
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
```

### Open Telekom Cloud {#open-telekom-cloud}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "login-cloud.mms.t-systems-service.com"
gitlab_rails['smtp_port'] = 25
gitlab_rails['smtp_domain'] = "yourdomain"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_user_name'] = "username"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['gitlab_email_from'] = 'gitlab@yourdomain'
```

### Uberspace 6 {#uberspace-6}

[Uberspace Wiki](https://manual.uberspace.de/)에서:

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "<your-host>.uberspace.de"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "<your-user>@<your-domain>"
gitlab_rails['smtp_password'] = "<your-password>"
gitlab_rails['smtp_domain'] = "<your-domain>"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
```

### Tipimail {#tipimail}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = 'smtp.tipimail.com'
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = 'username'
gitlab_rails['smtp_password'] = 'password'
gitlab_rails['smtp_authentication'] = 'login'
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### Netcup {#netcup}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = '<your-host>.netcup.net'
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "username"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "<your-gitlab-domain>"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
# Netcup is picky about the usage of GitLab's TLD instead of the subdomain (if you use one).
# If this is not set up correctly, the scheduled emails will fail. For example, if
# GitLab's domain name is 'gitlab.example.com', the following setting should be set to
# 'gitlab@example.com'.
gitlab_rails['gitlab_email_from'] = "gitlab@<your-top-level-domain>"
```

### Mail-in-a-Box {#mail-in-a-box}

```ruby
gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'

gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = 'box.example.com'
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "username@example.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "<your-gitlab-domain>"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### NIFCLOUD ESS {#nifcloud-ess}

[SMTP 인터페이스](https://docs.nifcloud.com/ess/spec/smtp.htm).

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.ess.nifcloud.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "SMTP user name"
gitlab_rails['smtp_password'] = "SMTP user password"
gitlab_rails['smtp_domain'] = "smtp.ess.nifcloud.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

gitlab_rails['gitlab_email_from'] = 'username@example.com'
gitlab_rails['gitlab_email_reply_to'] = 'username@example.com'
```

ESS [대시보드](https://docs.nifcloud.com/ess/help/dashboard.htm)에서 SMTP 사용자 이름과 SMTP 사용자 비밀번호를 확인합니다. `gitlab_email_from`와 `gitlab_email_reply_to`은(는) ESS 인증된 발신자 이메일 주소여야 합니다.

### Sina mail {#sina-mail}

사용자는 먼저 웹메일 인터페이스를 통해 메일박스 설정에서 SMTP를 활성화하고 인증 코드를 얻어야 합니다. Sina mail의 [도움말 페이지](http://help.sina.com.cn/comquestiondetail/view/1566/)에서 자세한 내용을 확인하세요.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.sina.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "username@sina.com"
gitlab_rails['smtp_password'] = "authentication code"
gitlab_rails['smtp_domain'] = "smtp.sina.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['gitlab_email_from'] = 'username@sina.com'
```

### Feishu mail {#feishu-mail}

Feishu mail의 [도움말 페이지](https://www.feishu.cn/hc/en-US/articles/360049068017-admin-allow-members-to-access-feishu-mail-using-third-party-email-clients)에서 자세한 내용을 확인하세요.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.feishu.cn"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "your-user@your-domain"
gitlab_rails['gitlab_email_from'] = "username@yourdomain.com"
gitlab_rails['smtp_domain'] = "yourdomain.com"
gitlab_rails['smtp_password'] = "authentication code"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
```

### Hostpoint {#hostpoint}

Hostpoint 이메일에 대한 자세한 내용은 [도움말 페이지](https://support.hostpoint.ch/en/technical/e-mail/frequently-asked-questions/e-mail-settings-at-a-glance#hp-section3)를 방문하세요.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "asmtp.mail.hostpoint.ch"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "username@example.com"
gitlab_rails['smtp_password'] = "authentication code"
gitlab_rails['smtp_domain'] = "asmtp.mail.hostpoint.ch"
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['gitlab_email_from'] = 'username@example.com'
```

### Fastweb (fastweb.it) {#fastweb-fastwebit}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.fastwebnet.it"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "your_fastweb_fastmail_username@fastwebnet.it"
gitlab_rails['smtp_password'] = "your_fastweb_fastmail_password"
gitlab_rails['smtp_domain'] = "smtp.fastwebnet.it"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### Scaleway Transactional Email {#scaleway-transactional-email}

[Scaleway의 Transactional Email](https://www.scaleway.com/en/docs/transactional-email/how-to/generate-api-keys-for-tem-with-iam/)에 대해 자세히 알아보세요.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.tem.scw.cloud"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "transactional_email_user_name"
gitlab_rails['smtp_password'] = "secret_key_of_api_key"
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### Proton Mail {#proton-mail}

Proton 설명서:  [Proton Mail에서 비즈니스 애플리케이션 또는 디바이스를 사용하도록 SMTP를 설정하는 방법](https://proton.me/support/smtp-submission)

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.protonmail.ch"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_user_name'] = "<the Proton email address for which you generated the SMTP token>"
gitlab_rails['smtp_password'] = "<the generated SMTP token>"
gitlab_rails['smtp_domain'] = "<your domain>"
gitlab_rails['gitlab_email_from'] = "<the Proton email address for which you generated the SMTP token>"
gitlab_rails['gitlab_email_reply_to'] = "<the Proton email address for which you generated the SMTP token>"
```

### Sendamatic {#sendamatic}

Sendamatic 사용에 대한 자세한 내용은 [Sendamatic 문서](https://docs.sendamatic.net)를 참조하세요.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "in.smtp.sendamatic.net"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "<mail credential user>" # https://docs.sendamatic.net/mail-credentials/
gitlab_rails['smtp_password'] = "<mail credential password>"
gitlab_rails['smtp_domain'] = "<mail identity domain>"    # https://docs.sendamatic.net/mail-identities/
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['gitlab_email_from'] = "example@<mail identity domain>"
gitlab_rails['gitlab_email_reply_to'] = "example@<mail identity domain>"
```

### 더 많은 예제를 환영합니다 {#more-examples-are-welcome}

예제 구성을 스스로 파악한 경우 다른 사람의 시간을 절약하기 위해 머지 리퀘스트를 보내주세요.

## SMTP 구성 테스트 {#testing-the-smtp-configuration}

Rails 콘솔을 사용하여 GitLab이 이메일을 제대로 보낼 수 있는지 확인할 수 있습니다. GitLab 서버에서 `gitlab-rails console`을(를) 실행하여 콘솔에 들어갑니다. 그런 다음 콘솔 프롬프트에서 다음 명령을 입력하여 GitLab이 테스트 이메일을 보내도록 할 수 있습니다:

```ruby
Notify.test_email('destination_email@address.com', 'Message Subject', 'Message Body').deliver_now
```

## SPF, DKIM 및 DMARC 구성 {#configuring-spf-dkim-and-dmarc}

GitLab 인스턴스에서 SMTP를 구성한 후 다음 프로토콜을 최대한 많이 구성해야 합니다:

- [Sender Policy Framework (SPF)](https://en.wikipedia.org/wiki/Sender_Policy_Framework).
- [DomainKeys Identified Mail (DKIM)](https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail).
- [Domain-based Message Authentication, Reporting and Conformance (DMARC)](https://en.wikipedia.org/wiki/DMARC).

이 프로토콜들은 함께 작동하여 이메일 발신자 신원을 확인하고 이메일 스푸핑을 방지합니다.

DNS 공급자는 구성할 수 있는 프로토콜과 구성 방법을 결정합니다. 예를 들어 Cloudflare가 DNS 공급자인 경우 [Cloudflare의 이러한 프로토콜을 구성](https://www.cloudflare.com/en-au/learning/email-security/dmarc-dkim-spf/)하는 방법을 볼 수 있습니다.

자세한 내용은 [SPF, DKIM 및 DMARC 이해:를 참조하세요: 간단한 가이드](https://github.com/nicanorflavier/spf-dkim-dmarc-simplified).

## 문제 해결 {#troubleshooting}

### 주요 클라우드 공급자에서 포트 25로의 아웃바운드 연결이 차단됨 {#outgoing-connections-to-port-25-is-blocked-on-major-cloud-providers}

클라우드 공급자를 사용하여 GitLab 인스턴스를 호스팅하고 SMTP 서버에 포트 25를 사용하는 경우 클라우드 공급자가 포트 25로의 아웃바운드 연결을 차단할 수 있습니다. 이것으로 인해 GitLab이 아웃바운드 메일을 보내지 못합니다. 클라우드 공급자에 따라 다음 지침을 따를 수 있습니다:

- AWS: [Amazon EC2 인스턴스 또는 AWS Lambda 함수에서 포트 25 제한을 제거하려면 어떻게 해야 합니까?](https://repost.aws/knowledge-center/ec2-port-25-throttle)
- Azure: [Azure에서 아웃바운드 SMTP 연결 문제 해결](https://learn.microsoft.com/en-us/azure/virtual-network/troubleshoot-outbound-smtp-connectivity)
- GCP: [인스턴스에서 이메일 보내기](https://cloud.google.com/compute/docs/tutorials/sending-mail)

### SSL/TLS를 사용할 때 잘못된 버전 번호 {#wrong-version-number-when-using-ssltls}

많은 사용자가 SMTP를 구성한 후 다음 오류가 발생합니다:

```plaintext
OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=error: wrong version number)
```

이 오류는 일반적으로 잘못된 설정으로 인해 발생합니다:

- SMTP 공급자가 포트 25 또는 587을 사용하는 경우 SMTP 연결은 **unencrypted** 상태로 시작되지만 [STARTTLS](https://en.wikipedia.org/wiki/Opportunistic_TLS)를 통해 업그레이드할 수 있습니다. 다음 설정이 설정되어 있는지 확인하세요:

  ```ruby
  gitlab_rails['smtp_enable_starttls_auto'] = true
  gitlab_rails['smtp_tls'] = false # This is the default and can be omitted
  gitlab_rails['smtp_ssl'] = false # This is the default and can be omitted
  ```

- SMTP 공급자가 포트 465를 사용하는 경우 SMTP 연결은 **encrypted** TLS를 통해 시작됩니다. 다음 줄이 있는지 확인하세요:

  ```ruby
  gitlab_rails['smtp_tls'] = true
  ```

자세한 내용은 [SMTP 포트, TLS 및 STARTTLS의 혼동에 대해](https://www.fastmail.help/hc/en-us/articles/360058753834-SSL-TLS-and-STARTTLS) 읽어보세요.

### 외부 Sidekiq 사용 시 이메일을 보내지 못함 {#emails-not-sending-when-using-external-sidekiq}

인스턴스에 [외부 Sidekiq](https://docs.gitlab.com/administration/sidekiq/)이 구성된 경우 SMTP 구성은 외부 Sidekiq 서버의 `/etc/gitlab/gitlab.rb`에 있어야 합니다. SMTP 구성이 없으면 많은 GitLab 이메일이 Sidekiq를 통해 전송되므로 이메일이 SMTP를 통해 전송되지 않는 것을 알 수 있습니다.

### Sidekiq 라우팅 규칙 사용 시 이메일을 보내지 못함 {#emails-not-sending-when-using-sidekiq-routing-rules}

Sidekiq [라우팅 규칙](https://docs.gitlab.com/administration/sidekiq/processing_specific_job_classes/#routing-rules)을 사용하는 경우 구성에 아웃바운드 메일에 필요한 `mailers` 큐가 없을 수 있습니다.

자세한 내용은 [예제 구성](https://docs.gitlab.com/administration/sidekiq/processing_specific_job_classes/#detailed-example)을 검토하세요.

### 이메일을 보내지 못함 {#email-not-sent}

> [!warning]
> 데이터를 직접 변경하는 모든 명령은 올바르게 실행하지 않거나 적절한 조건에서 실행하지 않으면 손상될 수 있습니다. 테스트 환경에서 인스턴스의 백업을 준비한 상태에서 실행하는 것을 강력히 권장합니다.

이메일 서버를 올바르게 구성했지만 이메일을 보내지 못하는 경우:

1. [Rails 콘솔](https://docs.gitlab.com/administration/operations/rails_console/#starting-a-rails-console-session)을 실행합니다.
1. `ActionMailer` `delivery_method`을(를) 확인합니다. 사용 중인 서버 유형과 일치해야 하며, SMTP 서버의 경우 `:smtp`, Sendmail의 경우 `:sendmail`입니다. SMTP를 구성한 경우 `:smtp`으로 표시되어야 합니다. Sendmail을 사용하는 경우 `:sendmail`으로 표시되어야 합니다:

   ```ruby
   irb(main):001:0> ActionMailer::Base.delivery_method
   => :smtp
   ```

1. SMTP를 사용하는 경우 메일 설정을 확인하세요:

   ```ruby
   irb(main):002:0> ActionMailer::Base.smtp_settings
   => {:address=>"localhost", :port=>25, :domain=>"localhost.localdomain", :user_name=>nil, :password=>nil, :authentication=>nil, :enable_starttls_auto=>true}
   ```

   위의 예제에서 SMTP 서버는 로컬 머신에 대해 구성됩니다. 이것이 의도한 경우 자세한 내용은 로컬 메일 로그(예: `/var/log/mail.log`)를 확인하세요.

1. 콘솔을 사용하여 테스트 메시지를 보냅니다:

   ```ruby
   irb(main):003:0> Notify.test_email('youremail@email.com', 'Hello World', 'This is a test message').deliver_now
   ```

   이메일을 받지 못했거나 오류 메시지가 표시되면 메일 서버 설정을 확인하세요.

### STARTTLS 및 SMTP TLS 사용 시 이메일을 보내지 못함 {#email-not-sent-when-using-starttls-and-smtp-tls}

STARTTLS 및 SMTP TLS이 모두 활성화된 경우 다음 오류가 발생할 수 있습니다:

```plaintext
:enable_starttls and :tls are mutually exclusive. Set :tls if you're on an SMTPS connection. Set :enable_starttls if you're on an SMTP connection and using STARTTLS for secure TLS upgrade.
```

이 오류는 `gitlab_rails['smtp_enable_starttls_auto']`과(와) `gitlab_rails['smtp_tls']`이(가) 모두 `true`으로 설정된 경우 발생합니다. SMTPS를 사용하는 경우 `gitlab_rails['smtp_enable_starttls_auto']`을(를) `false`로 설정합니다. STARTTLS를 사용하는 SMTP를 사용하는 경우 `gitlab_rails['smtp_tls']`을(를) `false`로 설정합니다. `sudo gitlab-ctl reconfigure`을(를) 실행하여 변경 사항을 적용합니다.

## 모든 아웃바운드 이메일 비활성화 {#disable-all-outgoing-email}

> [!note]
> GitLab 인스턴스에서 **전체** 아웃바운드 이메일을 비활성화하며, 여기에는 알림 이메일, 직접 언급 및 비밀번호 재설정 이메일이 포함되지만 이에 국한되지 않습니다.

**전체** 아웃바운드 이메일을 비활성화하기 위해 `/etc/gitlab/gitlab.rb`에 다음 줄을 편집하거나 추가할 수 있습니다:

```ruby
gitlab_rails['gitlab_email_enabled'] = false
```

`sudo gitlab-ctl reconfigure`을(를) 실행하여 변경 사항을 적용합니다.
