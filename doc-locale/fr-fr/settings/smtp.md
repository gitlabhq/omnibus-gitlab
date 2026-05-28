---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Paramètres SMTP
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si vous préférez envoyer les e-mails de l'application via un serveur SMTP plutôt que via Sendmail ou Postfix, ajoutez les informations de configuration suivantes dans `/etc/gitlab/gitlab.rb` et exécutez `gitlab-ctl reconfigure`.

> [!warning]
> Votre `smtp_password` ne doit contenir aucun délimiteur de chaîne utilisé en Ruby ou YAML (par exemple `'`) afin d'éviter tout comportement inattendu lors du traitement des paramètres de configuration.

Des [exemples de configuration](#example-configurations) sont disponibles à la fin de cette page.

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

## Mise en pool de connexions SMTP {#smtp-connection-pooling}

Vous pouvez activer la mise en pool de connexions SMTP avec le paramètre suivant :

```ruby
gitlab_rails['smtp_pool'] = true
```

Cela permet aux workers Sidekiq de réutiliser les connexions SMTP pour plusieurs jobs. Le nombre maximum de connexions dans le pool suit la [configuration de concurrence maximale pour Sidekiq](https://docs.gitlab.com/administration/sidekiq/extra_sidekiq_processes/#concurrency).

## Utilisation des identifiants chiffrés {#using-encrypted-credentials}

Au lieu de stocker les identifiants SMTP dans les fichiers de configuration en texte clair, vous pouvez éventuellement utiliser un fichier chiffré pour les identifiants SMTP. Pour utiliser cette fonctionnalité, vous devez d'abord activer la [configuration chiffrée de GitLab](https://docs.gitlab.com/administration/encrypted_configuration/).

La configuration chiffrée pour SMTP existe dans un fichier YAML chiffré. Par défaut, le fichier sera créé à l'emplacement `/var/opt/gitlab/gitlab-rails/shared/encrypted_settings/smtp.yaml.enc`. Cet emplacement est configurable dans la configuration de GitLab.

Le contenu non chiffré du fichier doit être un sous-ensemble des paramètres de vos réglages `smtp_*'` dans le bloc de configuration `gitlab_rails`.

Les éléments de configuration pris en charge pour le fichier chiffré sont :

- `user_name`
- `password`

Le contenu chiffré peut être configuré avec la [commande Rake d'édition du secret SMTP](https://docs.gitlab.com/administration/raketasks/smtp/).

Par exemple, si votre configuration SMTP dans `/etc/gitlab/gitlab.rb` est :

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

Pour reconfigurer :

1. Modifiez le secret chiffré :

   ```shell
   sudo gitlab-rake gitlab:smtp:secret:edit EDITOR=vim
   ```

1. Le contenu non chiffré du secret SMTP doit être saisi comme suit :

   ```yaml
   user_name: 'smtp user'
   password: 'smtp password'
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et supprimez les paramètres pour `smtp_user_name` et `smtp_password`.
1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Exemples de configuration {#example-configurations}

### SMTP sur localhost {#smtp-on-localhost}

Cette configuration, qui active simplement SMTP et utilise par ailleurs les paramètres par défaut, peut être utilisée pour un MTA s'exécutant sur localhost qui ne fournit pas d'interface `sendmail` ou qui fournit une interface `sendmail` incompatible avec GitLab, comme Exim.

```ruby
gitlab_rails['smtp_enable'] = true
```

### SMTP sans SSL {#smtp-without-ssl}

Par défaut, SSL est activé pour SMTP. Si votre serveur SMTP ne prend pas en charge la communication via SSL, utilisez les paramètres suivants :

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

Prérequis :

- [Vérification en 2 étapes activée](https://support.google.com/accounts/answer/185839).
- Un [mot de passe d'application](https://support.google.com/mail/answer/185833).

> [!note]
> Gmail a des [limites d'envoi strictes](https://support.google.com/a/answer/166852) qui peuvent nuire aux fonctionnalités à mesure que votre organisation se développe. Nous vous recommandons vivement d'utiliser un service transactionnel comme [SendGrid](https://sendgrid.com/en-us) ou [Mailgun](https://www.mailgun.com/) pour les équipes utilisant la configuration SMTP.

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

_N'oubliez pas de remplacer `my.email@gmail.com` par votre adresse e-mail et `my-gmail-password` par votre propre mot de passe._

### Relais SMTP Google {#google-smtp-relay}

Vous pouvez acheminer les messages sortants non-Gmail via Google [en utilisant le service de relais SMTP Google](https://support.google.com/a/answer/2956491?hl=en).

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

- Utilisation de STARTTLS

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

Assurez-vous d'autoriser le trafic sortant via le port 587 dans votre ACL et votre groupe de sécurité.

- Utilisation du wrapper TLS

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

Assurez-vous d'autoriser le trafic sortant via le port 465 dans votre ACL et votre groupe de sécurité.

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

Vous pouvez utiliser le service de messagerie [SMTP.com](https://www.smtp.com/). [Récupérez votre identifiant et mot de passe d'expéditeur](https://knowledge.smtp.com/s/article/My-Account) depuis votre compte.

Pour améliorer la délivrabilité en autorisant `SMTP.com` à envoyer des e-mails au nom de votre domaine, vous devez :

- Spécifiez les adresses `from` et `reply_to` en utilisant le nom de domaine de votre GitLab.
- [Configurer SPF et DKIM pour le domaine](https://knowledge.smtp.com/s/article/Email-authentication-SPF-DKIM-DMARC).

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

Consultez la [base de connaissances SMTP.com](https://knowledge.smtp.com/s/) pour obtenir de l'aide supplémentaire.

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

Cette configuration a été testée sur Zoho Mail avec un domaine personnalisé.

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

### Relais Office365 {#office365-relay}

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

Vous pouvez utiliser le service [outMail](https://www.prolateral.com/email-services/outmail-outgoing-smtp/outmail-outgoing-smtp-server.html) de Prolateral.

Pour améliorer la délivrabilité en autorisant outMail à envoyer des e-mails au nom de votre domaine, vous devez :

- Spécifiez des adresses from et reply_to valides en utilisant le nom de domaine de votre GitLab.
- Configurez un enregistrement [SPF (Sender Policy Framework)](https://www.prolateral.com/help/kb/dns-engine/457-what-is-a-spf-record.html) valide pour inclure outMail.
- Activez outMail pour [DKIM (DomainKeys Identified Mail)](https://www.prolateral.com/help/kb/outmail/643-how-do-i-enable-dkim-signing-of-emails-through-outmail.html) signer vos e-mails GitLab.

En tant qu'expéditeur responsable d'e-mails pour votre nom de domaine, vous devriez également envisager d'ajouter une politique [DMARC (Domain-based Message Authentication, Reporting, and Conformance)](https://www.prolateral.com/help/kb/outmail/647-what-is-dmarc-what-is-its-purpose-and-why-it-is-important.html).

Pour accéder aux détails de votre service outMail, connectez-vous au portail de gestion Prolateral, accédez à vos paramètres de service outMail, et configurez GitLab avec les valeurs appropriées comme suit :

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

Si vous utilisez le port TCP 465, modifiez les lignes concernées comme suit :

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

### SendGrid avec authentification par nom d'utilisateur/mot de passe {#sendgrid-with-usernamepassword-authentication}

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

### SendGrid avec authentification par clé API {#sendgrid-with-api-key-authentication}

Si vous ne souhaitez pas fournir de nom d'utilisateur/mot de passe, vous pouvez utiliser une [clé API](https://www.twilio.com/docs/sendgrid/for-developers/sending-email/getting-started-smtp) :

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

Notez que `smtp_user_name` doit littéralement être défini sur `"apikey"`. La clé API que vous avez créée doit être saisie dans `smtp_password`.

### Brevo {#brevo}

Cette configuration a été testée avec le [service de relais SMTP](https://www.brevo.com/free-smtp-server/) de Brevo. Pour récupérer les identifiants de compte pertinents via les URL commentées dans cet exemple, [connectez-vous à votre compte Brevo](https://login.brevo.com).

Pour plus de détails, consultez la [page d'aide](https://help.brevo.com/hc/en-us/articles/209462765-What-is-Brevo-SMTP) de Brevo.

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

Cette configuration a été testée avec [SMTP2GO](https://www.smtp2go.com/). Pour obtenir les identifiants de compte pertinents en utilisant les URL commentées dans cet exemple, [connectez-vous à votre compte SMTP2GO](https://app.smtp2go.com/login/).

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

### Microsoft Exchange (sans authentification) {#microsoft-exchange-no-authentication}

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "example.com"
gitlab_rails['smtp_port'] = 25
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_enable_starttls_auto'] = true
```

### Microsoft Exchange (avec authentification) {#microsoft-exchange-with-authentication}

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

- Serveurs européens : smtpout.europe.secureserver.net
- Serveurs asiatiques : smtpout.asia.secureserver.net
- Serveurs mondiaux (États-Unis) : smtpout.secureserver.net

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

### GoDaddy (sans TLS) {#godaddy-no-tls}

Consultez l'entrée GoDaddy (TLS) ci-dessus pour la liste des serveurs de messagerie.

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

### Alibaba Cloud Direct Mail (sans TLS) {#alibaba-cloud-direct-mail-no-tls}

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

### Aliyun Enterprise Mail avec TLS {#aliyun-enterprise-mail-with-tls}

Aliyun Enterprise Mail avec TLS (阿里企业邮箱)

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

FastMail nécessite un [mot de passe d'application](https://www.fastmail.help/hc/en-us/articles/360058752854-App-passwords) même lorsque la vérification en deux étapes n'est pas activée.

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

### easyDNS (courrier sortant) {#easydns-outbound-mail}

Vérifiez la disponibilité/l'activation et les paramètres de configuration dans le [panneau de contrôle](https://cp.easydns.com/manage/domains/mail/outbound/).

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

D'après la [documentation AWS workmail](https://docs.aws.amazon.com/workmail/latest/userguide/using_IMAP.html) :

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

D'après le [wiki Uberspace](https://manual.uberspace.de/) :

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

[Interface SMTP](https://docs.nifcloud.com/ess/spec/smtp.htm).

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

Vérifiez le nom d'utilisateur SMTP et le mot de passe SMTP depuis le [tableau de bord](https://docs.nifcloud.com/ess/help/dashboard.htm) ESS. `gitlab_email_from` et `gitlab_email_reply_to` doivent être des adresses e-mail d'expéditeur authentifiées par ESS.

### Sina mail {#sina-mail}

L'utilisateur doit d'abord activer SMTP via les paramètres de la boîte aux lettres dans l'interface de messagerie Web et obtenir le code d'authentification. Consultez plus de détails sur la [page d'aide](http://help.sina.com.cn/comquestiondetail/view/1566/) de Sina mail.

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

Consultez plus de détails sur la [page d'aide](https://www.feishu.cn/hc/en-US/articles/360049068017-admin-allow-members-to-access-feishu-mail-using-third-party-email-clients) de Feishu mail.

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

Pour plus d'informations sur la messagerie Hostpoint, consultez leur [page d'aide](https://support.hostpoint.ch/en/technical/e-mail/frequently-asked-questions/e-mail-settings-at-a-glance#hp-section3)

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

En savoir plus sur [l'e-mail transactionnel de Scaleway](https://www.scaleway.com/en/docs/transactional-email/how-to/generate-api-keys-for-tem-with-iam/).

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

Documentation Proton : [Comment configurer SMTP pour utiliser des applications ou des appareils professionnels avec Proton Mail](https://proton.me/support/smtp-submission)

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

Pour plus d'informations sur l'utilisation de Sendamatic, consultez la [documentation Sendamatic](https://docs.sendamatic.net).

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

### D'autres exemples sont les bienvenus {#more-examples-are-welcome}

Si vous avez trouvé un exemple de configuration par vous-même, veuillez envoyer une merge request pour faire gagner du temps aux autres utilisateurs.

## Tester la configuration SMTP {#testing-the-smtp-configuration}

Vous pouvez vérifier que GitLab peut envoyer des e-mails correctement en utilisant la console Rails. Sur le serveur GitLab, exécutez `gitlab-rails console` pour entrer dans la console. Ensuite, vous pouvez entrer la commande suivante dans l'invite de la console pour que GitLab envoie un e-mail de test :

```ruby
Notify.test_email('destination_email@address.com', 'Message Subject', 'Message Body').deliver_now
```

## Configurer SPF, DKIM et DMARC {#configuring-spf-dkim-and-dmarc}

Après avoir configuré SMTP sur votre instance GitLab, vous devriez configurer autant de protocoles parmi les suivants que possible :

- [Sender Policy Framework (SPF)](https://en.wikipedia.org/wiki/Sender_Policy_Framework).
- [DomainKeys Identified Mail (DKIM)](https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail).
- [Domain-based Message Authentication, Reporting and Conformance (DMARC)](https://en.wikipedia.org/wiki/DMARC).

Ces protocoles fonctionnent ensemble pour vérifier l'identité de l'expéditeur d'e-mails et prévenir l'usurpation d'e-mails.

Votre fournisseur DNS détermine quels protocoles vous pouvez configurer et comment les configurer. À titre d'exemple, vous pouvez voir comment vous [configureriez ces protocoles pour Cloudflare](https://www.cloudflare.com/en-au/learning/email-security/dmarc-dkim-spf/) si Cloudflare était votre fournisseur DNS.

Pour plus d'informations, consultez [Understanding SPF, DKIM, and DMARC : A Simple Guide](https://github.com/nicanorflavier/spf-dkim-dmarc-simplified).

## Résolution des problèmes {#troubleshooting}

### Les connexions sortantes vers le port 25 sont bloquées chez les principaux fournisseurs cloud {#outgoing-connections-to-port-25-is-blocked-on-major-cloud-providers}

Si vous utilisez un fournisseur cloud pour héberger votre instance GitLab et que vous utilisez le port 25 pour votre serveur SMTP, il est possible que votre fournisseur cloud bloque les connexions sortantes vers le port 25. Cela empêche GitLab d'envoyer tout courrier sortant. Vous pouvez suivre les instructions ci-dessous pour contourner ce problème en fonction de votre fournisseur cloud :

- AWS : [Comment supprimer la restriction sur le port 25 de mon instance Amazon EC2 ou de ma fonction AWS Lambda ?](https://repost.aws/knowledge-center/ec2-port-25-throttle)
- Azure : [Résoudre les problèmes de connectivité SMTP sortante dans Azure](https://learn.microsoft.com/en-us/azure/virtual-network/troubleshoot-outbound-smtp-connectivity)
- GCP : [Envoi d'e-mails depuis une instance](https://cloud.google.com/compute/docs/tutorials/sending-mail)

### Numéro de version incorrect lors de l'utilisation de SSL/TLS {#wrong-version-number-when-using-ssltls}

De nombreux utilisateurs rencontrent l'erreur suivante après avoir configuré SMTP :

```plaintext
OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=error: wrong version number)
```

Cette erreur est généralement due à des paramètres incorrects :

- Si votre fournisseur SMTP utilise le port 25 ou 587, les connexions SMTP démarrent **non chiffrées** mais peuvent être mises à niveau via [STARTTLS](https://en.wikipedia.org/wiki/Opportunistic_TLS). Assurez-vous que les paramètres suivants sont définis :

  ```ruby
  gitlab_rails['smtp_enable_starttls_auto'] = true
  gitlab_rails['smtp_tls'] = false # This is the default and can be omitted
  gitlab_rails['smtp_ssl'] = false # This is the default and can be omitted
  ```

- Si votre fournisseur SMTP utilise le port 465, les connexions SMTP démarrent **chiffrées** via TLS. Assurez-vous que la ligne suivante est présente :

  ```ruby
  gitlab_rails['smtp_tls'] = true
  ```

Pour plus de détails, consultez [les explications sur la confusion entre les ports SMTP, TLS et STARTTLS](https://www.fastmail.help/hc/en-us/articles/360058753834-SSL-TLS-and-STARTTLS).

### E-mails non envoyés lors de l'utilisation d'un Sidekiq externe {#emails-not-sending-when-using-external-sidekiq}

Si votre instance a [un Sidekiq externe](https://docs.gitlab.com/administration/sidekiq/) configuré, la configuration SMTP doit être présente dans `/etc/gitlab/gitlab.rb` sur le serveur Sidekiq externe. Si la configuration SMTP est manquante, vous remarquerez peut-être que les e-mails ne sont pas envoyés via SMTP, car de nombreux e-mails GitLab sont envoyés via Sidekiq.

### E-mails non envoyés lors de l'utilisation des règles de routage Sidekiq {#emails-not-sending-when-using-sidekiq-routing-rules}

Si vous utilisez les [règles de routage](https://docs.gitlab.com/administration/sidekiq/processing_specific_job_classes/#routing-rules) Sidekiq, votre configuration pourrait ne pas inclure la file d'attente `mailers` requise pour le courrier sortant.

Pour plus de détails, consultez l'[exemple de configuration](https://docs.gitlab.com/administration/sidekiq/processing_specific_job_classes/#detailed-example).

### E-mail non envoyé {#email-not-sent}

> [!warning]
> Toute commande qui modifie des données directement peut être dommageable si elle n'est pas exécutée correctement ou dans les bonnes conditions. Nous vous recommandons vivement de les exécuter dans un environnement de test avec une sauvegarde de l'instance prête à être restaurée, au cas où.

Si vous avez correctement configuré un serveur de messagerie, mais que l'e-mail n'est pas envoyé :

1. Exécutez une [console Rails](https://docs.gitlab.com/administration/operations/rails_console/#starting-a-rails-console-session).
1. Vérifiez le `ActionMailer` `delivery_method`. Il doit correspondre au type de serveur que vous utilisez, soit `:smtp` pour un serveur SMTP, soit `:sendmail` pour Sendmail : prévu. Si vous avez configuré SMTP, il devrait indiquer `:smtp`. Si vous utilisez Sendmail, il devrait indiquer `:sendmail` :

   ```ruby
   irb(main):001:0> ActionMailer::Base.delivery_method
   => :smtp
   ```

1. Si vous utilisez SMTP, vérifiez les paramètres de messagerie :

   ```ruby
   irb(main):002:0> ActionMailer::Base.smtp_settings
   => {:address=>"localhost", :port=>25, :domain=>"localhost.localdomain", :user_name=>nil, :password=>nil, :authentication=>nil, :enable_starttls_auto=>true}
   ```

   Dans l'exemple ci-dessus, le serveur SMTP est configuré pour la machine locale. Si c'est intentionnel, consultez vos journaux de messagerie locaux (par exemple, `/var/log/mail.log`) pour plus de détails.

1. Envoyez un message de test en utilisant la console :

   ```ruby
   irb(main):003:0> Notify.test_email('youremail@email.com', 'Hello World', 'This is a test message').deliver_now
   ```

   Si vous ne recevez pas d'e-mail ou si vous voyez un message d'erreur, vérifiez les paramètres de votre serveur de messagerie.

### E-mail non envoyé lors de l'utilisation de STARTTLS et SMTP TLS {#email-not-sent-when-using-starttls-and-smtp-tls}

Vous pouvez rencontrer l'erreur suivante si STARTTLS et SMTP TLS sont tous les deux activés :

```plaintext
:enable_starttls and :tls are mutually exclusive. Set :tls if you're on an SMTPS connection. Set :enable_starttls if you're on an SMTP connection and using STARTTLS for secure TLS upgrade.
```

Cette erreur se produit lorsque `gitlab_rails['smtp_enable_starttls_auto']` et `gitlab_rails['smtp_tls']` sont tous les deux définis sur `true`. Si vous utilisez SMTPS, définissez `gitlab_rails['smtp_enable_starttls_auto']` sur `false`. Si vous utilisez SMTP avec STARTTLS, définissez `gitlab_rails['smtp_tls']` sur `false`. Exécutez `sudo gitlab-ctl reconfigure` pour que la modification prenne effet.

## Désactiver tous les e-mails sortants {#disable-all-outgoing-email}

> [!note]
> Cela désactivera **l'ensemble** des e-mails sortants de votre instance GitLab, y compris, mais sans s'y limiter, les e-mails de notification, les mentions directes et les e-mails de réinitialisation de mot de passe.

Pour désactiver **l'ensemble** des e-mails sortants, vous pouvez modifier ou ajouter la ligne suivante dans `/etc/gitlab/gitlab.rb` :

```ruby
gitlab_rails['gitlab_email_enabled'] = false
```

Exécutez `sudo gitlab-ctl reconfigure` pour que la modification prenne effet.
