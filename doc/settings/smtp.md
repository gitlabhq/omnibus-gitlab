# SMTP settings

If you would rather send application email via an SMTP server instead of via
Sendmail, add the following configuration information to
`/etc/gitlab/gitlab.rb` and run `gitlab-ctl reconfigure`.

```
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.server"
gitlab_rails['smtp_port'] = 456
gitlab_rails['smtp_user_name'] = "smtp user"
gitlab_rails['smtp_password'] = "smtp password"
gitlab_rails['smtp_domain'] = "example.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

# If your SMTP server does not like the default 'From: gitlab@localhost' you
# can change the 'From' with this setting.
gitlab_rails['gitlab_email_from'] = 'gitlab@example.com'
```

## GitLab CI

To change GitLab CI email configuration (e.g. use SMTP), use `gitlab_ci` instead
of `gitlab_rails`.

```ruby
# in /etc/gitlab/gitlab.rb
gitlab_ci['gitlab_ci_email_from'] = 'gitlab-ci@example.com'
gitlab_ci['smtp_enable'] = true
gitlab_ci['smtp_address'] = "smtp.server"
# etc.
```

## Example configuration

### GMail

```
gitlab_rails['gitlab_email_from'] = 'my.email@gmail.com'

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

_Don't forget to change my.email@gmail.com to your email address and my-gmail-password to your own password._
