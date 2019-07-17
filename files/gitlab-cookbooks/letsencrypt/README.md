# letsencrypt cookbook

Configures Let's Encrypt certificates for use in an omnibus-gitlab instance

## Resources

### letsencrypt_certificate

Fetches or renews a Let's Encrypt certificate

#### properties

* `cn`: The Common Name of the certificate. Name property
* `crt`: The path to the certificate file. Required
* `key`: The path to the key file. Required
* `chain`: The path to the certificate chain
* `contact`: Contact information for the certificate
* `owner`: The filesystem owner of the files that will be created
* `group`: The filesystem group owner of the files that will be created
* `wwwroot`: The root directory that the acme client will use for http authorization
* `alt_names`: An array of alt names to add to the certificate
* `key_size`: The private key size to use

#### example

```ruby
letsencrypt_certificate 'fakehost.example.com' do
  crt '/etc/gitlab/ssl/fakehost.example.com.crt'
  key '/etc/gitlab/ssl/fakehost.example.com.key'
  chain '/etc/gitlab/ssl/fakehost.example.com.chain'
  contact ['mailto:me@example.com']
end
```
