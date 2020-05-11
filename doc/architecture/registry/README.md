# Architecture of GitLab Container Registry

The GitLab registry is what users use to store their own Docker images.
Because of that the Registry is client facing, meaning that we expose it directly
on the web server (or load balancers, LB for short).

![GitLab Registry diagram](gitlab-registry-architecture.png)

The flow described by the diagram above:

1. A user runs `docker login registry.gitlab.example` on their client. This reaches the web server (or LB) on port 443.
1. Web server connects to the Registry backend pool (by default, using port 5000). Since the user
   didn’t provide a valid token, the Registry returns a 401 HTTP code and the URL (`token_realm` from
   Registry configuration) where to get one. This points to the GitLab API.
1. The Docker client then connects to the GitLab API and obtains a token.
1. The API signs the token with the registry key and hands it to the Docker client
1. The Docker client now logs in again with the token received from the API. It can now push and pull Docker images.

Reference: <https://docs.docker.com/registry/spec/auth/token/>

## Communication between GitLab and Registry

Registry doesn’t have a way to authenticate users internally so it relies on
GitLab to validate credentials. The connection between Registry and GitLab is
TLS encrypted. The key is used by GitLab to sign the tokens while the certificate
is used by Registry to validate the signature. By default, a self-signed certificate key pair is generated
for all installations. This can be overridden as needed.

GitLab interacts with the Registry using the Registry private key. When a Registry
request goes out, a new short-living (10 minutes) namespace limited token is generated
and signed with the private key.
The Registry then verifies that the signature matches the registry certificate
specified in its configuration and allows the operation.
GitLab background jobs processing (through Sidekiq) also interacts with Registry.
These jobs talk directly to Registry in order to handle image deletion.

## Configuring GitLab and Registry to run on separate nodes

By default, package assumes that both services are running on the same node.
In order to get GitLab and Registry to run on a separate nodes, separate configuration
is necessary for Registry and GitLab.

### Configuring Registry

Below you will find configuration options you should set in `/etc/gitlab/gitlab.rb`,
for Registry to run separately from GitLab:

- `registry['registry_http_addr']`, default [set programmatically](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/10-3-stable/files/gitlab-cookbooks/gitlab/libraries/registry.rb#L50). Needs to be reachable by web server (or LB).
- `registry['token_realm']`, default [set programmatically](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/10-3-stable/files/gitlab-cookbooks/gitlab/libraries/registry.rb#L53). Specifies the endpoint to use to perform authentication, usually the GitLab URL.
  This endpoint needs to be reachable by user.
- `registry['http_secret']`, [random string](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/10-3-stable/files/gitlab-cookbooks/gitlab/libraries/registry.rb#L32). A random piece of data used to sign state that may be stored with the client to protect against tampering.
- `registry['internal_key']`, default [automatically generated](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/10-3-stable/files/gitlab-cookbooks/gitlab/recipes/gitlab-rails.rb#L113-119). Contents of the key that GitLab uses to sign the tokens. They key gets created on the Registry server, but it won't be used there.
- `gitlab_rails['registry_key_path']`, default [set programmatically](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/10-3-stable/files/gitlab-cookbooks/gitlab/recipes/gitlab-rails.rb#L35). This is the path where `internal_key` contents will be written to disk.
- `registry['internal_certificate']`, default [automatically generated](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/10-3-stable/files/gitlab-cookbooks/registry/recipes/enable.rb#L60-66). Contents of the certificate that GitLab uses to sign the tokens.
- `registry['rootcertbundle']`, default [set programmatically](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/10-3-stable/files/gitlab-cookbooks/registry/recipes/enable.rb#L60). Path to certificate. This is the path where `internal_certificate`
  contents will be written to disk.
- `registry['health_storagedriver_enabled']`, default [set programmatically](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/10-7-stable/files/gitlab-cookbooks/gitlab/libraries/registry.rb#L88). Configure whether health checks on the configured storage driver are enabled.
- `gitlab_rails['registry_issuer']`, [default value](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/10-3-stable/files/gitlab-cookbooks/gitlab/attributes/default.rb#L153). This setting needs to be set the same between Registry and GitLab.

### Configuring GitLab

Below you will find configuration options you should set in `/etc/gitlab/gitlab.rb`,
for GitLab to run separately from Registry:

- `gitlab_rails['registry_enabled']`, must be set to `true`. This setting will
  signal to GitLab that it should allow Registry API requests.
- `gitlab_rails['registry_api_url']`, default [set programmatically](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/10-3-stable/files/gitlab-cookbooks/gitlab/libraries/registry.rb#L52). This is the Registry URL used internally that users do not need to interact with, `registry['registry_http_addr']` with scheme.
- `gitlab_rails['registry_host']`, eg. `registry.gitlab.example`. Registry endpoint without the scheme, the address that gets shown to the end user.
- `gitlab_rails['registry_port']`. Registry endpoint port, visible to the end user.
- `gitlab_rails['registry_issuer']` must match the issuer in the Registry configuration.
- `gitlab_rails['registry_key_path']`, path to the key that matches the certificate on the
  Registry side.
- `gitlab_rails['internal_key']`, contents of the key that GitLab uses to sign the tokens.
