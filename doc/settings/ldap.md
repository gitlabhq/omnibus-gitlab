---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Setting up LDAP sign-in

If you have an LDAP directory service such as Active Directory, you can
configure GitLab so that your users can sign in with their LDAP credentials.
Add the following to `/etc/gitlab/gitlab.rb`, edited for your server.

For GitLab Community Edition:

```ruby
# These settings are documented in more detail at
# https://gitlab.com/gitlab-org/gitlab-foss/blob/a0a826ebdcb783c660dd40d8cb217db28a9d4998/config/gitlab.yml.example#L136
# Be careful not to break the identation in the ldap_servers block. It is in
# yaml format and the spaces must be retained. Using tabs will not work.

gitlab_rails['ldap_enabled'] = true
gitlab_rails['prevent_ldap_sign_in'] = false
gitlab_rails['ldap_servers'] = YAML.load <<-EOS # remember to close this block with 'EOS' below
main: # 'main' is the GitLab 'provider ID' of this LDAP server
  ## label
  #
  # A human-friendly name for your LDAP server. It is OK to change the label later,
  # for instance if you find out it is too large to fit on the web page.
  #
  # Example: 'Paris' or 'Acme, Ltd.'
  label: 'LDAP'

  host: '_your_ldap_server'
  port: 389 # or 636
  uid: 'sAMAccountName'
  encryption: 'plain' # "start_tls" or "simple_tls" or "plain"
  bind_dn: '_the_full_dn_of_the_user_you_will_bind_with'
  password: '_the_password_of_the_bind_user'

  # Enable smartcard authentication against the LDAP server. Valid values
  # are "false", "optional", and "required".
  smartcard_auth: false

  # This setting specifies if LDAP server is Active Directory LDAP server.
  # For non AD servers it skips the AD specific queries.
  # If your LDAP server is not AD, set this to false.
  active_directory: true

  # If allow_username_or_email_login is enabled, GitLab will ignore everything
  # after the first '@' in the LDAP username submitted by the user on login.
  #
  # Example:
  # - the user enters 'jane.doe@example.com' and 'p@ssw0rd' as LDAP credentials;
  # - GitLab queries the LDAP server with 'jane.doe' and 'p@ssw0rd'.
  #
  # If you are using "uid: 'userPrincipalName'" on ActiveDirectory you need to
  # disable this setting, because the userPrincipalName contains an '@'.
  allow_username_or_email_login: false

  # If lowercase_usernames is enabled, GitLab will lower case the username.
  lowercase_usernames: false

  # Base where we can search for users
  #
  #   Ex. ou=People,dc=gitlab,dc=example
  #
  base: ''

  # Filter LDAP users
  #
  #   Format: RFC 4515 http://tools.ietf.org/search/rfc4515
  #   Ex. (employeeType=developer)
  #
  #   Note: GitLab does not support omniauth-ldap's custom filter syntax.
  #
  user_filter: ''
EOS

```

If you are installing GitLab Enterprise edition package you can use multiple LDAP servers:

```ruby
gitlab_rails['ldap_enabled'] = true
gitlab_rails['prevent_ldap_sign_in'] = false
gitlab_rails['ldap_servers'] = YAML.load <<-EOS # remember to close this block with 'EOS' below
main: # 'main' is the GitLab 'provider ID' of this LDAP server
  label: 'LDAP'
  host: '_your_ldap_server'
  port: 389
  uid: 'sAMAccountName'
  encryption: 'plain' # "start_tls" or "simple_tls" or "plain"
  bind_dn: '_the_full_dn_of_the_user_you_will_bind_with'
  password: '_the_password_of_the_bind_user'
  smartcard_auth: false
  active_directory: true
  allow_username_or_email_login: false
  lowercase_usernames: false
  block_auto_created_users: false
  base: ''
  user_filter: ''
  ## EE only
  group_base: ''
  admin_group: ''
  sync_ssh_keys: false

secondary: # 'secondary' is the GitLab 'provider ID' of second LDAP server
  label: 'LDAP'
  host: '_your_ldap_server'
  port: 389
  uid: 'sAMAccountName'
  encryption: 'plain' # "start_tls" or "simple_tls" or "plain"
  bind_dn: '_the_full_dn_of_the_user_you_will_bind_with'
  password: '_the_password_of_the_bind_user'
  smartcard_auth: false
  active_directory: true
  allow_username_or_email_login: false
  lowercase_usernames: false
  block_auto_created_users: false
  base: ''
  user_filter: ''
  ## EE only
  group_base: ''
  admin_group: ''
  sync_ssh_keys: false
EOS

```

Run `sudo gitlab-ctl reconfigure` for the LDAP settings to take effect.

For more information on LDAP Integration, check:

- [LDAP documentation](https://docs.gitlab.com/ee/administration/auth/ldap.html).
- [EE-specific](https://docs.gitlab.com/ee/administration/auth/ldap-ee.html) LDAP documentation.

*Note*: If you are using pre GitLab 7.4 [configuration syntax like described in the old version README LDAP section](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/e65f026839594d54ad46a31a672d735b9caa16f0/README.md#setting-up-ldap-sign-in) be advised that it is deprecated.
