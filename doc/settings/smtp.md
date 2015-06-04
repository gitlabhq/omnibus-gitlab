# SMTP settings

If you would rather send application email via an SMTP server instead of via
Sendmail, add the following configuration information to
`/etc/gitlab/gitlab.rb` and run `gitlab-ctl reconfigure`.
There are [example configurations](#examples) at the end of this page.

```ruby
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
gitlab_rails['gitlab_email_reply_to'] = 'noreply@example.com'
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
### SMTP on localhost
This configuration, which simply enables SMTP and otherwise uses the default settings, can be used for an MTA running on localhost that does not provide a `sendmail` interface or that provides a `sendmail` interface that is incompatible with GitLab, such as Exim.

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_ci['smtp_enable'] = true
```

### Gmail

```ruby
gitlab_rails['gitlab_email_from'] = 'my.email@gmail.com'
gitlab_rails['gitlab_email_reply_to'] = 'my.email@gmail.com'

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

### Mailgun

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.mailgun.org"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_user_name'] = "postmaster@mg.gitlab.com"
gitlab_rails['smtp_password'] = "8b6ffrmle180"
gitlab_rails['smtp_domain'] = "mg.gitlab.com"
```

### More examples are welcome

If you have figured out an example configuration yourself please send a merge request to save other people time.
