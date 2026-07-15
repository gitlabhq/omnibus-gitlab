---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test plan for `krb5` component upgrade
---

Copy the following test plan to a comment of the merge request that upgrades the component.

````markdown
## Test plan

- [ ] Check the [`krb5` release notes](https://web.mit.edu/kerberos/krb5-latest/index.html) for potential breaking changes.
- [ ] Green pipeline with `Trigger:ee-package` and `build-package-on-all-os`.
- [ ] Check the version of krb5 embedded in GitLab:

  ```shell
  /opt/gitlab/embedded/bin/klist -V
  ls -l /opt/gitlab/embedded/bin/{kinit,klist,kvno}
  ```

- [ ] Perform Kerberos-specific configuration. Your GitLab installation must already be up and running.
  Run `gitlab-ctl reconfigure` at least once before continuing.

  1. Set a stable hostname/realm mapping. The GitLab SPN host must match the URL you clone from:

     ```shell
     echo "127.0.0.1 www.krb5testing.com" >> /etc/hosts
     ```

  2. Install the KDC + admin server + client tools (system krb5, used by the KDC and for realm config).
  For example, on Debian you could run:

     ```shell
     export DEBIAN_FRONTEND=noninteractive
     apt-get update
     apt-get install -y krb5-kdc krb5-admin-server krb5-user git curl ca-certificates
     ```

  3. Configure the Kerberos client:

     ```shell
     cat > /etc/krb5.conf <<'EOF'
     [libdefaults]
         default_realm = KRB5TESTING.COM
         dns_lookup_realm = false
         dns_lookup_kdc = false
         rdns = false

     [realms]
         KRB5TESTING.COM = {
             kdc = www.krb5testing.com
             admin_server = www.krb5testing.com
         }

     [domain_realm]
         .krb5testing.com = KRB5TESTING.COM
         krb5testing.com = KRB5TESTING.COM
     EOF
     ```

     KDC config:

     ```shell
     cat > /etc/krb5kdc/kdc.conf <<'EOF'
     [kdcdefaults]
         kdc_ports = 88
         kdc_tcp_ports = 88

     [realms]
         KRB5TESTING.COM = {
             database_name = /var/lib/krb5kdc/principal
             admin_keytab = FILE:/etc/krb5kdc/kadm5.keytab
             acl_file = /etc/krb5kdc/kadm5.acl
             key_stash_file = /etc/krb5kdc/stash
             max_life = 10h 0m 0s
             max_renewable_life = 7d 0h 0m 0s
             supported_enctypes = aes256-cts-hmac-sha1-96:normal aes128-cts-hmac-sha1-96:normal
         }
     EOF
     ```

     Admin ACL:

     ```shell
     echo "*/admin@KRB5TESTING.COM    *" > /etc/krb5kdc/kadm5.acl
     ```

  4. Create the KDC database (use a master password, e.g. "krbmaster"):

     ```shell
     kdb5_util create -s -r KRB5TESTING.COM -P krbmaster
     ```

  5. Start the KDC and admin server:

     ```shell
     service krb5-kdc start
     service krb5-admin-server start
     ```

  6. Set principals and file permissions:

     ```shell
     # Admin principal (for kadmin)
     kadmin.local -q "addprinc -pw adminpass admin/admin"

     # User principal that will log into GitLab (set a password, e.g. "userpass")
     kadmin.local -q "addprinc -pw userpass testkrb5"

     # GitLab HTTP service principal (host must match the clone URL host)
     kadmin.local -q "addprinc -randkey HTTP/www.krb5testing.com"

     # Export the service key into the keytab GitLab will read
     kadmin.local -q "ktadd -k /etc/http.keytab HTTP/www.krb5testing.com"

     # Lock down the keytab so the GitLab user can read it
     chown git /etc/http.keytab
     chmod 0600 /etc/http.keytab

     # verify
     klist -k /etc/http.keytab
     ```

- [ ] Configure GitLab for Kerberos (dedicated port 8443, plain HTTP):

  ```shell
  cat >> /etc/gitlab/gitlab.rb <<'EOF'
  external_url 'http://www.krb5testing.com'

  gitlab_rails['omniauth_enabled'] = true
  gitlab_rails['omniauth_allow_single_sign_on'] = ['kerberos']

  gitlab_rails['kerberos_enabled'] = true
  gitlab_rails['kerberos_keytab'] = "/etc/http.keytab"
  gitlab_rails['kerberos_use_dedicated_port'] = true
  gitlab_rails['kerberos_port'] = 8443
  gitlab_rails['kerberos_https'] = false
  EOF

  gitlab-ctl reconfigure
  gitlab-ctl restart
  ```

  Link a Kerberos identity to root and create the test project (with a README so clone has content).
  gitlab-rails will take some time to accept input, so this will take a few minutes.

  ```shell
  gitlab-rails console <<'RUBY'
  root = User.find_by(username: 'root')
  Identity.find_or_create_by!(user: root, provider: 'kerberos', extern_uid: 'testkrb5@KRB5TESTING.COM')
  p = Projects::CreateService.new(
    root,
    name: 'test_krb5',
    namespace_id: root.namespace.id,
    visibility_level: 0,
    initialize_with_readme: true
  ).execute
  puts p.persisted? ? "project ready: #{p.full_path}" : p.errors.full_messages.join(', ')
  RUBY
  ```

- [ ] Test a passwordless git clone using only a service ticket, use the password set above (e.g. "userpass"):

  ```shell
  # Get a TGT as the user
  kinit testkrb5@KRB5TESTING.COM

  # Confirm the ticket
  klist

  KRB5_TRACE=/tmp/krb5_trace.log git clone http://:@www.krb5testing.com:8443/root/test_krb5.git
  cat /tmp/krb5_trace.log
  ```

- [ ] Optional. You can also attempt a web login at this point.

  Make sure the host from where you're running Firefox resolves www.krb5testing.com to the IP of
  your installed GitLab instance. You can try something like:

  ```shell
  GITLAB_HOST_IP=_REPLACE_THIS_IP_
  echo "${GITLAB_HOST_IP} krb5testing.com kdc.krb5testing.com www.krb5testing.com" >> /etc/hosts
  ```

  If you're running your browser on another host, you need to get a ticket just like before

  ```shell
  kinit testkrb5@KRB5TESTING.COM
  ```

  Configure Firefox to enable Kerberos:

  1. Navigate to about:config.
  2. Set network.negotiate-auth.trusted-uris=.krb5testing.com.
  3. Set network.negotiate-auth.allow-non-fqdn=true.
  4. Open <http://www.krb5testing.com> and click the Kerberos sign-in button, you should be signed in.
````
