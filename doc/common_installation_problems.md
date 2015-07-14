# Common installation problems

Below you can find the most common issues users encounter when installing omnibus-gitlab packages.


### Using self signed certificate or custom certificate authorities

Omnibus-gitlab is shipped with the official [CAcert.org][] collection of trusted root certification authorities which are used to verify certificate authenticity.

If you are installing GitLab in an isolated network with custom certificate authorities or using self signed certificate make sure that the certificate can be reached by GitLab. Not doing so will cause errors like:

```bash
Faraday::SSLError (SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed)
```

when GitLab tries to connect with the internal services like gitlab-shell or GitLab CI.

To install individual certificates you need to:

1. Place your certificate in `/opt/gitlab/embedded/ssl/certs/` directory; For example, `/opt/gitlab/embedded/ssl/certs/customcacert.pem`
1. Create the hash-based symlink to the newly created `customcacert.pem`. For example, You can use [certificate link shell script][], [script source][] . *NOTE* If you end up using the script, make sure the script is executable with `chmod +x certlink.sh`. After making it executable you can do: `certlink.sh customcacert.pem` while in `/opt/gitlab/embedded/ssl/certs/`.

After the custom certificate is symlinked the errors should be gone and your custom certificate preserved on GitLab upgrades.

Make sure to have the backup of the certificate as GitLab is not backing up `/opt/gitlab/` contents.

If you are using self-signed certificate do not forget to set `self_signed_cert: true` for gitlab-shell, see [gitlab.rb.template][] for more details.

[CAcert.org]: http://www.cacert.org/
[certificate link shell script]: https://gitlab.com/snippets/6285
[script source]: https://www.madboa.com/geek/openssl/#verify-new
[gitlab.rb.template]: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template
