---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# SMTP settings **(FREE SELF)**

If you would rather send application email via an SMTP server instead of via
Sendmail, add the following configuration information to
`/etc/gitlab/gitlab.rb` and run `gitlab-ctl reconfigure`.

WARNING:
Your `smtp_password` should not contain any String delimiters used in
Ruby or YAML (f.e. `'`) to avoid unexpected behavior during the processing of
config settings.

There are [example configurations](#example-configurations) at the end of this page.

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

# If your SMTP server is using self signed certificates you can specify a custom ca file
gitlab_rails['smtp_ca_file'] = '/path/to/your/cacert.pem'
```

## SMTP connection pooling

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/230717) in GitLab 13.5.

You can enable SMTP connection pooling with the following setting:

```ruby
gitlab_rails['smtp_pool'] = true
```

This allows Sidekiq workers to reuse SMTP connections for multiple jobs. The maximum number of connections in the pool follows the [maximum concurrency configuration for Sidekiq](https://docs.gitlab.com/ee/administration/operations/extra_sidekiq_processes.html#manage-concurrency).

## Using encrypted credentials

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6276) in GitLab 14.3.

Instead of storing the SMTP credentials in the configuration files as plain text, you can optionally
use an encrypted file for the SMTP credentials. To use this feature, you first need to enable
[GitLab encrypted configuration](https://docs.gitlab.com/ee/administration/encrypted_configuration.html).

The encrypted configuration for SMTP exists in an encrypted YAML file. By default the file will be created at
`/var/opt/gitlab/gitlab-rails/shared/encrypted_configuration/smtp.yaml.enc`. This location is configurable in the GitLab configuration.

The unencrypted contents of the file should be a subset of the settings from your `smtp_*'` settings in the `gitlab_rails`
configuration block.

The supported configuration items for the encrypted file are:

- `user_name`
- `password`

The encrypted contents can be configured with the [SMTP secret edit Rake command](https://docs.gitlab.com/ee/administration/raketasks/smtp.html).

**Configuration**

If initially your SMTP configuration looked like:

1. In `/etc/gitlab/gitlab.rb`:

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

1. Edit the encrypted secret:

   ```shell
   sudo gitlab-rake gitlab:smtp:secret:edit EDITOR=vim
   ```

1. The unencrypted contents of the SMTP secret should be entered like:

   ```yaml
   user_name: 'smtp user'
   password: 'smtp password'
   ```

1. Edit `/etc/gitlab/gitlab.rb` and remove the settings for `smtp_user_name` and `smtp_password`.
1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Example configurations

### SMTP on localhost

This configuration, which simply enables SMTP and otherwise uses the default settings, can be used for an MTA running on localhost that does not provide a `sendmail` interface or that provides a `sendmail` interface that is incompatible with GitLab, such as Exim.

```ruby
gitlab_rails['smtp_enable'] = true
```

### SMTP without SSL

By default SSL is enabled for SMTP. If your SMTP server do not support communication over SSL use following settings:

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

### Gmail

NOTE:
Gmail has [strict sending limits](https://support.google.com/a/answer/166852)
that can impair functionality as your organization grows. We strongly recommend using a
transactional service like [SendGrid](https://sendgrid.com/) or [Mailgun](https://www.mailgun.com/)
for teams using SMTP configuration.

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

_Don't forget to change `my.email@gmail.com` to your email address and `my-gmail-password` to your own password._

_If you encounter authentication errors, ensure you have [allowed less secure apps to access the account](https://support.google.com/accounts/answer/6010255)
 or try [turning on 2-step validation](https://support.google.com/accounts/answer/185839)
 and using [an application password](https://support.google.com/mail/answer/185833)._

### Mailgun

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

### Amazon Simple Email System (AWS SES)

- Using STARTTLS

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

Make sure to permit egress through port 587 in your ACL and security group.

- Using TLS Wrapper

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

Make sure to permit egress through port 465 in your ACL and security group.

### Mandrill

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.mandrillapp.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "MandrillUsername"
gitlab_rails['smtp_password'] = "MandrillApiKey" # https://mandrillapp.com/settings
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### SparkPost

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.sparkpostmail.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "SMTP_Injection"
gitlab_rails['smtp_password'] = "SparkPost_API_KEY" # https://app.sparkpost.com/account/credentials
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### Gandi

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.gandi.net"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_user_name'] = "your.email@domain.com"
gitlab_rails['smtp_password'] = "your.password"
gitlab_rails['smtp_domain'] = "domain.com"
```

### Zoho Mail

This configuration was tested on Zoho Mail with a custom domain.

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

### SiteAge, LLC Zimbra Mail

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = 'mail.siteage.net'
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = 'gitlab@domain.com'
gitlab_rails['smtp_password'] = 'password'
gitlab_rails['smtp_authentication'] = 'login'
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['gitlab_email_from'] = "gitlab@domain.com"
gitlab_rails['smtp_tls'] = true
```

### OVH

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "ssl0.ovh.net"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "ssl0.ovh.net"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### Outlook

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

### Office365

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

### Office365 relay

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "your mx endpoint"
gitlab_rails['smtp_port'] = 25
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_domain'] = "yourdomain.com"
gitlab_rails['gitlab_email_from'] = 'username@yourdomain.com'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@yourdomain.com'
```

### Online.net

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtpauth.online.net"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "online.net"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### Amen.fr / Securemail.pro

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp-fr.securemail.pro"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_tls'] = true
```

### 1&1

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

### yahoo

```ruby
gitlab_rails['gitlab_email_from'] = 'user@yahoo.com'
gitlab_rails['gitlab_email_reply_to'] = 'user@yahoo.com'

gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.mail.yahoo.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "user@yahoo.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
```

### QQ exmail

QQ exmail (腾讯企业邮箱)

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.exmail.qq.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "xxxx@xx.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['gitlab_email_from'] = 'xxxx@xx.com'
gitlab_rails['smtp_domain'] = "exmail.qq.com"
```

### NetEase Free Enterprise Email

NetEase Free Enterprise Email (网易免费企业邮)

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.ym.163.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "xxxx@xx.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['gitlab_email_from'] = 'xxxx@xx.com'
gitlab_rails['smtp_domain'] = "smtp.ym.163.com"
```

### SendGrid with username/password authentication

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

### SendGrid with API Key authentication

If you don't want to supply a username/password, you can use an [API key](https://docs.sendgrid.com/for-developers/sending-email/getting-started-smtp):

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

Note that `smtp_user_name` must literally be set to `"apikey"`.
The API Key you created must be entered in `smtp_password`.

### Sendinblue

This configuration was tested with Sendinblue's [SMTP relay service](https://www.sendinblue.com/free-smtp-server/). To grab the relevant account credentials via the URLs commented into this example, [log in to your Sendinblue account](https://app.sendinblue.com/account/login). For further details, refer to Sendinblue's [help page](https://help.sendinblue.com/hc/en-us/articles/209462765-What-is-Sendinblue-SMTP-).

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp-relay.sendinblue.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "<username@example.com>" # https://account.sendinblue.com/advanced/api
gitlab_rails['smtp_password'] = "<password>"              # https://account.sendinblue.com/advanced/api
gitlab_rails['smtp_domain'] = "<example.com>"             # https://account.sendinblue.com/senders
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['gitlab_email_from'] = '<gitlab@example.com>'
gitlab_rails['gitlab_email_reply_to'] = '<noreply@example.com>'
```

### Yandex

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
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
```

### UD Media

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

### Microsoft Exchange (No authentication)

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "example.com"
gitlab_rails['smtp_port'] = 25
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### Microsoft Exchange (with authentication)

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

### Strato.de

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.strato.de"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@stratodomain.de"
gitlab_rails['smtp_password'] = "strato_email_password"
gitlab_rails['smtp_domain'] = "stratodomain.de"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### Rackspace

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "secure.emailsrvr.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "domain.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

gitlab_rails['gitlab_email_from'] = 'username@domain.com'
gitlab_rails['gitlab_email_reply_to'] = 'username@domain.com'
```

### DomainFactory (df.eu)

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "sslout.df.eu"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "domain.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### Infomaniak (infomaniak.com)

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.infomaniak.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "username"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "mail.infomaniak.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### GoDaddy (TLS)

- European servers: smtpout.europe.secureserver.net
- Asian servers: smtpout.asia.secureserver.net
- Global (US) servers: smtpout.secureserver.net

```ruby
gitlab_rails['gitlab_email_from'] = 'username@domain.com'

gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtpout.secureserver.net"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@domain.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "domain.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
```

### GoDaddy (No TLS)

See GoDaddy (TLS) entry above for mail server list.

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

### OpenSRS (hostedemail.com)

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

### Aruba (aruba.it)

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

### Aliyun Direct Mail

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

### Aliyun Enterprise Mail with TLS

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

### FastMail

FastMail requires an
[App Password](https://www.fastmail.help/hc/en-us/articles/360058752854)
even when two-step verification is not enabled.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.fastmail.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "account@fastmail.com"
gitlab_rails['smtp_password'] = "app-specific-password"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
```

### Dinahosting

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

### Office 365

``` ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.office365.com"
gitlab_rails['smtp_port'] = 25
gitlab_rails['smtp_user_name'] = "user.name@company.com"
gitlab_rails['smtp_password'] = "secret"
gitlab_rails['smtp_domain'] = "company.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
```

### GMX Mail

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mail.gmx.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "my-gitlab@gmx.com"
gitlab_rails['smtp_password'] = "Pa5svv()rD"
gitlab_rails['smtp_domain'] = "mail.gmx.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

### Email Settings
gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = 'my-gitlab@gmx.com'
gitlab_rails['gitlab_email_display_name'] = 'My GitLab'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@gmx.com'
```

### Hetzner

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

### Snel.com

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

### JangoSMTP

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

### Mailjet

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "in.mailjet.com"
gitlab_rails['smtp_port'] = 2525
gitlab_rails['smtp_user_name'] = "your.username"
gitlab_rails['smtp_password'] = "your.password"
gitlab_rails['smtp_domain'] = "in.mailjet.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['gitlab_email_from'] = 'gitlab@domain.com'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@domain.com'
```

### Mailcow

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

### ALL-INKL.COM

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

### webgo.de

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

### mxhichina.com

```ruby
gitlab_rails['gitlab_email_from'] = "username@company.com"
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.mxhichina.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@company.com"
gitlab_rails['smtp_password'] = "password"
gitlab_rails['smtp_domain'] = "mxhichina.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
```

### Postmark

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

### easyDNS (outbound mail)

Check if it's available/enabled and configuration settings in the [control panel](https://cp.easydns.com/manage/domains/mail/outbound/).

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

### Campaign Monitor

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

### Freehostia

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "mbox.freehostia.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@example.com"
gitlab_rails['smtp_password'] = "password_you_set"
gitlab_rails['smtp_domain'] = "mbox.freehostia.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### Mailbox.org

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.mailbox.org"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "username@example.com"
gitlab_rails['smtp_password'] = "password_you_set"
gitlab_rails['smtp_domain'] = "smtp.mailbox.org"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
```

### Mittwald CM Service (mittwald.de)

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

### Unitymedia (.de)

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

### united-domains AG (united-domains.de)

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.udag.de"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "example-com-0001"
gitlab_rails['smtp_password'] = "smtppassword"
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
gitlab_rails['gitlab_email_display_name'] = 'GitLab - my company'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@example.com'
```

### IONOS by 1&1 (ionos.de)

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

### AWS Workmail

From the [AWS workmail documentation](https://docs.aws.amazon.com/workmail/latest/userguide/using_IMAP_client.html):

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

### Open Telekom Cloud

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

### Uberspace 6

From the [Uberspace Wiki](https://wiki.uberspace.de/mail#tldr):

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

### Tipimail

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = 'smtp.tipimail.com'
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = 'username'
gitlab_rails['smtp_password'] = 'password'
gitlab_rails['smtp_authentication'] = 'login'
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### Netcup

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

### Mail-in-a-Box

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

### NIFCLOUD ESS

[SMTP Interface](https://pfs.nifcloud.com/spec/ess/smtp.htm).

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

Check the SMTP user name and SMTP user password from the ESS [dashboard](https://pfs.nifcloud.com/help/ess/dashboard.htm).
`gitlab_email_from` and `gitlab_email_reply_to` must be ESS authenticated sender email addresses.

### Sina mail

User needs first to enabled SMTP through the mailbox settings via web mail interface and get the authenitication code. Check out more details in the [help page](http://help.sina.com.cn/comquestiondetail/view/1566/) of Sina mail.

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

### Feishu mail

Check out more details in the [help page](https://www.feishu.cn/hc/articles/360049068017) of Feishu mail.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.feishu.cn"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "your-user@your-domain"
gitlab_rails['gitlab_email_from'] = "username@yourdomain.com"
gitlab_rails['smtp_domain'] = "yourdomain.com"
gitlab_rails['smtp_password'] = "authentication code"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
```

### More examples are welcome

If you have figured out an example configuration yourself please send a Merge
Request to save other people time.

## Testing the SMTP configuration

You can verify that GitLab can send emails properly using the Rails console.
On the GitLab server, execute `gitlab-rails console` to enter the console. Then,
you can enter the following command at the console prompt to cause GitLab to
send a test email:

```ruby
Notify.test_email('destination_email@address.com', 'Message Subject', 'Message Body').deliver_now
```

## Troubleshooting

### Outgoing connections to port 25 is blocked on major cloud providers

If you are using a cloud provider to host your GitLab instance and you are using port 25 for your
SMTP server, it is possible that your cloud provider is blocking outgoing connections to port 25.
This prevents GitLab from sending any outgoing mail. You can follow the instructions below to work
around this depending on your cloud provider:

- AWS: [How do I remove the restriction on port 25 from my Amazon EC2 instance or AWS Lambda function?](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-port-25-throttle/)
- Azure: [Troubleshoot outbound SMTP connectivity problems in Azure](https://docs.microsoft.com/en-us/azure/virtual-network/troubleshoot-outbound-smtp-connectivity)
- GCP: [Sending email from an instance](https://cloud.google.com/compute/docs/tutorials/sending-mail)

### Wrong version number when using SSL/TLS

Many users run into the following error after configuring SMTP:

```plaintext
OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=error: wrong version number)
```

This error is usually due to incorrect settings:

- If your SMTP provider is using port 25 or 587, SMTP connections start
**unencrypted** but can be upgraded via
[STARTTLS](https://en.wikipedia.org/wiki/Opportunistic_TLS). Be sure the
following settings are set:

  ```ruby
  gitlab_rails['smtp_enable_starttls_auto'] = true
  gitlab_rails['smtp_tls'] = false # This is the default and can be omitted
  gitlab_rails['smtp_ssl'] = false # This is the default and can be omitted
  ```

- If your SMTP provider is using port 465, SMTP connections start
**encrypted** over TLS. Ensure the following line is present:

  ```ruby
  gitlab_rails['smtp_tls'] = true
  ```

For more details, read [about the confusion over SMTP ports, TLS, and STARTTLS](https://www.fastmail.help/hc/en-us/articles/360058753834).

## Disable all outgoing email

NOTE:
This will disable **all** outgoing email from your GitLab instance, including but not limited to notification emails, direct mentions, and password reset emails.

In order to disable **all** outgoing email, you can edit or add the following line to `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['gitlab_email_enabled'] = false
```

Run `sudo gitlab-ctl reconfigure` for the change to take effect.
