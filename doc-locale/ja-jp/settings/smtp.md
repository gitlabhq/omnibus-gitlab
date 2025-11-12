---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SMTP設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

SendmailまたはPostfix経由ではなく、SMTPサーバー経由でアプリケーションメールを送信する場合は、以下の設定情報を`/etc/gitlab/gitlab.rb`に追加し、`gitlab-ctl reconfigure`を実行します。

{{< alert type="warning" >}}

設定の処理中に予期しない動作が発生しないように、`smtp_password`にRubyまたはYAMLで使用されている文字列区切り文字（例: `'`）を含めないでください。

{{< /alert >}}

このページの最後に[構成例](#example-configurations)があります。

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

## SMTP接続プール {#smtp-connection-pooling}

次の設定で、SMTP接続プールを有効にできます:

```ruby
gitlab_rails['smtp_pool'] = true
```

これにより、Sidekiqワーカーは複数のジョブに対してSMTP接続を再利用できます。プール内の最大接続数は、[Sidekiqの最大並行処理設定](https://docs.gitlab.com/administration/sidekiq/extra_sidekiq_processes/#concurrency)に従います。

## 暗号化された認証情報を使用する。 {#using-encrypted-credentials}

SMTP認証情報をプレーンテキストとして設定ファイルに保存する代わりに、オプションで暗号化されたファイルをSMTP認証情報に使用できます。この機能を使用するには、まず[GitLab暗号化設定](https://docs.gitlab.com/administration/encrypted_configuration/)を有効にする必要があります。

SMTPの暗号化された設定は、暗号化されたYAMLファイルとして存在します。デフォルトでは、ファイルは`/var/opt/gitlab/gitlab-rails/shared/encrypted_settings/smtp.yaml.enc`に作成されます。この場所はGitLabの設定で設定可能です。

このファイルに含める暗号化されていない内容は、`gitlab_rails`設定ブロックの`smtp_*'`の設定のサブセットである必要があります。

暗号化されたファイルでサポートされている設定項目は次のとおりです:

- `user_name`
- `password`

暗号化されたコンテンツは、[SMTPシークレット編集Rakeコマンド](https://docs.gitlab.com/administration/raketasks/smtp/)で設定できます。

**設定**

最初にSMTP設定が次のようになっている場合:

1. `/etc/gitlab/gitlab.rb`で:

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

1. 暗号化されたシークレットを編集します:

   ```shell
   sudo gitlab-rake gitlab:smtp:secret:edit EDITOR=vim
   ```

1. SMTPシークレットの暗号化されていないコンテンツは、次のように入力する必要があります:

   ```yaml
   user_name: 'smtp user'
   password: 'smtp password'
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、`smtp_user_name`と`smtp_password`の設定を削除します。
1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 設定例 {#example-configurations}

### ローカルマシン上のSMTP {#smtp-on-localhost}

SMTPを有効にするだけで、それ以外はデフォルト設定を使用するこの設定は、`sendmail`インターフェースを提供しないか、Eximなど、GitLabと互換性のない`sendmail`インターフェースを提供するローカルマシン上で実行されているMTAに使用できます。

```ruby
gitlab_rails['smtp_enable'] = true
```

### SSLなしのSMTP {#smtp-without-ssl}

デフォルトでは、SSLはSMTPに対して有効になっています。SMTPサーバーがSSL経由の通信をサポートしていない場合は、次の設定を使用します:

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

前提要件: 

- [2段階認証が有効](https://support.google.com/accounts/answer/185839)になっている。
- [アプリパスワード](https://support.google.com/mail/answer/185833)。

{{< alert type="note" >}}

Gmailには[厳格な送信制限](https://support.google.com/a/answer/166852)があり、組織が成長するにつれて機能が損なわれる可能性があります。SMTP設定を使用するチームには、[SendGrid](https://sendgrid.com/en-us)や[Mailgun](https://www.mailgun.com/)のようなトランザクションサービスを使用することを強くお勧めします。

{{< /alert >}}

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

_`my.email@gmail.com`を自分のメールアドレスに、`my-gmail-password`を自分のパスワードに必ず変更してください。_

### Google SMTPリレー {#google-smtp-relay}

Google SMTPリレーサービスを使用すると、Gmail以外の送信メッセージをGoogle経由で[ルーティングできます](https://support.google.com/a/answer/2956491?hl=en)。

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

### Amazon SimpleメールService (AWS SES) {#amazon-simple-email-service-aws-ses}

- STARTTLSの使用

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

ACLおよびセキュリティグループでポート587経由のエグレスを許可するようにしてください。

- TLSラッパーの使用

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

ACLおよびセキュリティグループでポート465経由のエグレスを許可するようにしてください。

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

[SMTP.com](https://www.smtp.com/)メールサービスを利用できます。[送信者のログイン名とパスワードを](https://knowledge.smtp.com/s/article/My-Account)アカウントから取得します。

`SMTP.com`がドメインの代わりにメールを送信することを承認して配信を改善するには、以下を実行する必要があります:

- GitLabドメイン名を使用して`from`アドレスと`reply_to`アドレスを指定します。
- [ドメインのSPFとDKIMをセットアップ](https://knowledge.smtp.com/s/article/Email-authentication-SPF-DKIM-DMARC)します。

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

詳細については、[SMTP.comナレッジベース](https://knowledge.smtp.com/s/)を確認してください。

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

### Zohoメール {#zoho-mail}

この設定は、カスタムドメインを使用したZohoメールでテストされています。

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

### SiteAge, LLC Zimbraメール {#siteage-llc-zimbra-mail}

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

### Office365リレー {#office365-relay}

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

Prolateralの[outMail](https://www.prolateral.com/email-services/outmail-outgoing-smtp/outmail-outgoing-smtp-server.html)サービスを使用できます。

outMailにドメインの代わりにメールを送信することを承認して配信を改善するには、以下を実行する必要があります:

- GitLabドメイン名を使用して、有効な送信元アドレスと返信先アドレスを指定します。
- outMailを含めるように、有効な[SPF（送信者ポリシーフレームワーク）](https://www.prolateral.com/help/kb/dns-engine/457-what-is-a-spf-record.html)レコードをセットアップします。
- GitLabメールに署名するために、outMailで[DKIM（DomainKeys Identified Mail）](https://www.prolateral.com/help/kb/outmail/643-how-do-i-enable-dkim-signing-of-emails-through-outmail.html)を有効にします。

ドメイン名のメールの責任ある送信者として、[DMARC（ドメインベースのメッセージ認証、レポート、および準拠）](https://www.prolateral.com/help/kb/outmail/647-what-is-dmarc-what-is-its-purpose-and-why-it-is-important.html)ポリシーを追加することも検討する必要があります。

outMailサービスの詳細にアクセスするには、Prolateral管理ポータルにログインし、outMailサービスの設定に移動して、次の適切な値でGitLabを設定します:

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

TCPポート465を使用している場合は、関連する行を次のように変更します:

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

QQ exmail（腾讯企业邮箱）

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

### NetEase Free Enterpriseメール {#netease-free-enterprise-email}

NetEase Free Enterpriseメール（网易免费企业邮）

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

### ユーザー名/パスワード認証によるSendGrid {#sendgrid-with-usernamepassword-authentication}

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

### APIキー認証によるSendGrid {#sendgrid-with-api-key-authentication}

ユーザー名/パスワードを提供したくない場合は、[APIキー](https://www.twilio.com/docs/sendgrid/for-developers/sending-email/getting-started-smtp)を使用できます:

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

`smtp_user_name`は文字どおり`"apikey"`に設定する必要があることに注意してください。作成したAPIキーは、`smtp_password`に入力する必要があります。

### Brevo {#brevo}

この設定は、Brevo [SMTPリレーサービス](https://www.brevo.com/free-smtp-server/)でテストされています。この例にコメントされているURLを介して関連するアカウント認証情報を取得するには、[Brevoアカウントにログインしてください](https://login.brevo.com)。

詳細については、Brevo [ヘルプページ](https://help.brevo.com/hc/en-us/articles/209462765-What-is-Brevo-SMTP)を参照してください。

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

この設定は、[SMTP2GO](https://www.smtp2go.com/)を使用してテストされています。この例にコメントされているURLを使用して関連するアカウント認証情報を取得するには、[SMTP2GOアカウントにサインイン](https://app.smtp2go.com/login/)します。

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

### Microsoft Exchange（認証なし） {#microsoft-exchange-no-authentication}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "example.com"
gitlab_rails['smtp_port'] = 25
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### Microsoft Exchange（認証あり） {#microsoft-exchange-with-authentication}

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

- ヨーロッパサーバー: smtpout.europe.secureserver.net
- アジアサーバー: smtpout.asia.secureserver.net
- グローバル（US）サーバー: smtpout.secureserver.net

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

### GoDaddy（TLSなし） {#godaddy-no-tls}

メールサーバーリストについては、上記のGoDaddy（TLS）エントリを参照してください。

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

### Alibaba Cloud Directメール（TLSなし） {#alibaba-cloud-direct-mail-no-tls}

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

### Alibaba Cloud Directメール（TLS） {#alibaba-cloud-direct-mail-tls}

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

### Aliyun Directメール {#aliyun-direct-mail}

Aliyun Directメール（阿里云邮件推送）

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

### TLSを使用したAliyun Enterpriseメール {#aliyun-enterprise-mail-with-tls}

TLSを使用したAliyun Enterpriseメール（阿里企业邮箱）

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

FastMailでは、2段階認証が有効になっていなくても、[アプリパスワード](https://www.fastmail.help/hc/en-us/articles/360058752854-App-passwords)が必要です。

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

### GMXメール {#gmx-mail}

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

### easyDNS（送信メール） {#easydns-outbound-mail}

[コントロールパネル](https://cp.easydns.com/manage/domains/mail/outbound/)で利用可能/有効になっているかどうかと、設定設定を確認します。

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

[AWS Workmailドキュメント](https://docs.aws.amazon.com/workmail/latest/userguide/using_IMAP.html)から:

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

[Uberspace Wiki](https://manual.uberspace.de/)から:

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

[SMTPインターフェース](https://docs.nifcloud.com/ess/spec/smtp.htm)。

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

[ダッシュボード](https://docs.nifcloud.com/ess/help/dashboard.htm)から、SMTPユーザー名とSMTPユーザー名のパスワードを確認してください。`gitlab_email_from`と`gitlab_email_reply_to`は、ESS認証済みの送信者のメールアドレスである必要があります。

### Sinaメール {#sina-mail}

ユーザーは、最初にWebメールインターフェースを介してメールボックス設定からSMTPを有効にし、認証コードを取得する必要があります。詳細については、Sinaメールの[ヘルプページ](http://help.sina.com.cn/comquestiondetail/view/1566/)を参照してください。

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

### Feishuメール {#feishu-mail}

詳細については、Feishuメールの[ヘルプページ](https://www.feishu.cn/hc/en-US/articles/360049068017-admin-allow-members-to-access-feishu-mail-using-third-party-email-clients)を参照してください。

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

Hostpointメールの詳細については、[ヘルプページ](https://support.hostpoint.ch/en/technical/e-mail/frequently-asked-questions/e-mail-settings-at-a-glance#hp-section3)を参照してください

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

### Scaleway Transactionalメール {#scaleway-transactional-email}

[ScalewayのTransactionalメール](https://www.scaleway.com/en/docs/transactional-email/how-to/generate-api-keys-for-tem-with-iam/)の詳細をご覧ください。

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.tem.scw.cloud"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "transactional_email_user_name"
gitlab_rails['smtp_password'] = "secret_key_of_api_key"
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### Protonメール {#proton-mail}

Protonドキュメント: [SMTPをセットアップして、Protonメールでビジネスアプリケーションまたはデバイスを使用する方法](https://proton.me/support/smtp-submission)

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

Sendamaticの使用の詳細については、[Sendamatic Docs](https://docs.sendamatic.net)を参照してください。

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

### 例をさらに募集しています {#more-examples-are-welcome}

独自の構成例を理解した場合は、他のユーザーの時間を節約するためにマージリクエストを送信してください。

## SMTP設定のテスト {#testing-the-smtp-configuration}

Railsコンソールを使用して、GitLabがメールを正しく送信できることを確認できます。GitLabサーバーで、`gitlab-rails console`を実行してコンソールに入ります。次に、コンソールプロンプトに次のコマンドを入力して、GitLabにテストメールを送信させることができます:

```ruby
Notify.test_email('destination_email@address.com', 'Message Subject', 'Message Body').deliver_now
```

## SPF、DKIM、DMARCの設定 {#configuring-spf-dkim-and-dmarc}

GitLabインスタンスでSMTPを設定したら、可能な限り次のプロトコルを設定する必要があります:

- [送信者ポリシーフレームワーク（SPF）](https://en.wikipedia.org/wiki/Sender_Policy_Framework)。
- [DomainKeys Identified Mail（DKIM）](https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail)。
- [ドメインベースのメッセージ認証、レポート、および準拠（DMARC）](https://en.wikipedia.org/wiki/DMARC)。

これらのプロトコルは連携して、メール送信者の身元を確認し、メールスプーフィングを防止します。

DNSプロバイダーは、設定できるプロトコルとその設定方法を決定します。例として、DNSプロバイダーがCloudflareの場合、[Cloudflare用にこれらのプロトコルを設定する](https://www.cloudflare.com/en-au/learning/email-security/dmarc-dkim-spf/)ことがわかります。

詳細については、[SPF、DKIM、およびDMARCについてを参照してください: シンプルなガイド](https://github.com/nicanorflavier/spf-dkim-dmarc-simplified)。

## トラブルシューティング {#troubleshooting}

### 主要なクラウドプロバイダーでポート25への送信接続がブロックされている {#outgoing-connections-to-port-25-is-blocked-on-major-cloud-providers}

クラウドプロバイダーを使用してGitLabインスタンスをホストしており、SMTPサーバーにポート25を使用している場合、クラウドプロバイダーがポート25への送信接続をブロックしている可能性があります。これにより、GitLabは送信メールを送信できなくなります。次の手順に従って、クラウドプロバイダーに応じてこの問題を回避できます:

- AWS: [Amazon EC2インスタンスまたはAWS Lambda関数からポート25の制限を削除するにはどうすればよいですか？](https://repost.aws/knowledge-center/ec2-port-25-throttle)
- Azure: [Azureでの送信SMTP接続の問題のトラブルシューティング](https://learn.microsoft.com/en-us/azure/virtual-network/troubleshoot-outbound-smtp-connectivity)
- GCP: [インスタンスからのメールの送信](https://cloud.google.com/compute/docs/tutorials/sending-mail)

### SSL/TLSの使用時に誤ったバージョン番号 {#wrong-version-number-when-using-ssltls}

SMTPを設定すると、多くのユーザーが次のエラーに遭遇します:

```plaintext
OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=error: wrong version number)
```

このエラーは通常、設定が正しくないことが原因です:

- SMTPプロバイダーがポート25または587を使用している場合、SMTP接続は**暗号化されていない**状態で開始されますが、[STARTTLS](https://en.wikipedia.org/wiki/Opportunistic_TLS)を介してアップグレードできます。次の設定が設定されていることを確認してください:

  ```ruby
  gitlab_rails['smtp_enable_starttls_auto'] = true
  gitlab_rails['smtp_tls'] = false # This is the default and can be omitted
  gitlab_rails['smtp_ssl'] = false # This is the default and can be omitted
  ```

- SMTPプロバイダーがポート465を使用している場合、SMTP接続はTLS経由で**暗号化された**状態で開始されます。次の行が存在することを確認します:

  ```ruby
  gitlab_rails['smtp_tls'] = true
  ```

詳細については、[SMTPポート、TLS、およびSTARTTLSに関する混乱](https://www.fastmail.help/hc/en-us/articles/360058753834-SSL-TLS-and-STARTTLS)についてお読みください。

### 外部Sidekiqを使用している場合にメールが送信されない {#emails-not-sending-when-using-external-sidekiq}

お使いのインスタンスに[外部Sidekiq](https://docs.gitlab.com/administration/sidekiq/)が設定されている場合、SMTP設定は外部Sidekiqサーバー上の`/etc/gitlab/gitlab.rb`に存在する必要があります。SMTP設定が見つからない場合、多くのGitLabメールがSidekiq経由で送信されるため、メールがSMTP経由で送信されないことに気付くことがあります。

### Sidekiqルーティングルールを使用している場合にメールが送信されない {#emails-not-sending-when-using-sidekiq-routing-rules}

Sidekiqの[ルーティングルール](https://docs.gitlab.com/administration/sidekiq/processing_specific_job_classes/#routing-rules)を使用している場合、送信メールに必要な`mailers`キューが設定にない可能性があります。

詳細については、[設定例](https://docs.gitlab.com/administration/sidekiq/processing_specific_job_classes/#detailed-example)を確認してください。

### メールが送信されませんでした {#email-not-sent}

{{< alert type="warning" >}}

データを直接変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。念のため、インスタンスのバックアップを復元できるように準備し、Test環境で実行することを強くお勧めします。

{{< /alert >}}

メールサーバーが正しく設定されているにもかかわらず、メールが送信されない場合:

1. [Railsコンソール](https://docs.gitlab.com/administration/operations/rails_console/#starting-a-rails-console-session)を実行します。
1. `ActionMailer` `delivery_method`を確認してください。使用しているサーバーのタイプ（SMTPサーバーの場合は`:smtp`、Sendmailの場合は`:sendmail`）と一致している必要があります。SMTPを設定した場合は、`:smtp`と表示されるはずです。Sendmailを使用している場合は、`:sendmail`と表示されるはずです:

   ```ruby
   irb(main):001:0> ActionMailer::Base.delivery_method
   => :smtp
   ```

1. SMTPを使用している場合は、メールの設定を確認してください:

   ```ruby
   irb(main):002:0> ActionMailer::Base.smtp_settings
   => {:address=>"localhost", :port=>25, :domain=>"localhost.localdomain", :user_name=>nil, :password=>nil, :authentication=>nil, :enable_starttls_auto=>true}
   ```

   上記の例では、SMTPサーバーはローカルマシン用に設定されています。これが意図されている場合は、詳細について、ローカルマシンのメールログ（たとえば、`/var/log/mail.log`）を確認してください。

1. コンソールを使用してテストメッセージを送信します:

   ```ruby
   irb(main):003:0> Notify.test_email('youremail@email.com', 'Hello World', 'This is a test message').deliver_now
   ```

   メールを受信しない場合、またはエラーメッセージが表示される場合は、メールサーバーの設定を確認してください。

### STARTTLSおよびSMTP TLSを使用している場合にメールが送信されない {#email-not-sent-when-using-starttls-and-smtp-tls}

STARTTLSとSMTP TLSの両方が有効になっている場合、次のエラーが発生することがあります:

```plaintext
:enable_starttls and :tls are mutually exclusive. Set :tls if you're on an SMTPS connection. Set :enable_starttls if you're on an SMTP connection and using STARTTLS for secure TLS upgrade.
```

このエラーは、`gitlab_rails['smtp_enable_starttls_auto']`と`gitlab_rails['smtp_tls']`の両方が`true`に設定されている場合に発生します。SMTPSを使用している場合は、`gitlab_rails['smtp_enable_starttls_auto']`を`false`に設定します。STARTTLSでSMTPを使用している場合は、`gitlab_rails['smtp_tls']`を`false`に設定します。変更を有効にするには、`sudo gitlab-ctl reconfigure`を実行します。

## すべての送信メールを無効にする {#disable-all-outgoing-email}

{{< alert type="note" >}}

これにより、通知メール、ダイレクトメンション、パスワードリセットメールなどを含むがこれらに限定されない、GitLabインスタンスからの**すべて**の送信メールが無効になります。

{{< /alert >}}

**すべて**の送信メールを無効にするには、次の行を`/etc/gitlab/gitlab.rb`に編集または追加します:

```ruby
gitlab_rails['gitlab_email_enabled'] = false
```

変更を有効にするには、`sudo gitlab-ctl reconfigure`を実行します。
