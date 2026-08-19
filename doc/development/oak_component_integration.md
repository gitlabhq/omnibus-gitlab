---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OAK component integration guide
---

Integrate a new **advanced component** with **OAK (Omnibus Adjacent
Kubernetes)** by following these steps, whether you are a feature team adding
a new component or an AI agent scaffolding the integration.

OAK supports two setup models for each component, following the
[OAK design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/omnibus_adjacent_kubernetes/):

| Setup | Description |
|---|---|
| **Colocated** | The component's Kubernetes cluster runs on the same host as a single-node Omnibus GitLab instance. |
| **External cluster (non-colocated)** | The component runs in a customer-provided Kubernetes cluster on separate infrastructure. |

Both setups must work with the same `gitlab.rb` configuration surface.
Multi-node Omnibus deployments are supported with an external cluster, as
described in
[ADR-004](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/omnibus_adjacent_kubernetes/decisions/004_multi_node_omnibus_support/).
In multi-node deployments, the settings must be present on every node that
runs a consuming service, and the Rails node is the authoritative source for
Helm values generation. Network configuration and service exposure are the
customer's responsibility. Omnibus only automates its own host; it does
not orchestrate the Kubernetes cluster or the component's Helm
deployment.

## Worked example: OpenBao

The OpenBao integration is the canonical reference for all steps below.
Study these MRs before implementing a new component:

| Step | MR | What it covers |
|---|---|---|
| OAK cookbook base | [!9235](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9235) | `oak` cookbook, core library, NGINX network binding |
| NGINX reverse proxy + URL inference | [!9289](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9289) | Component NGINX server block, `parse_variables`, `parse_external_url` |
| HTTPS + Let's Encrypt | [!9331](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9331) | TLS listener, HTTP→HTTPS redirect, ACME challenge path |
| Helm values generation | [!9290](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9290) | `openbao-helm-values.yaml.erb` template, enable/disable recipes |
| Component database framework | [!9440](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9440) | `postgresql['component_databases']`, PgBouncer pool, Patroni failover |
| CI job | [!9359](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9359) | BATS-based end-to-end CI test |
| Documentation | [GitLab MR !241878](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241878) | Operator install guide on `docs.gitlab.com` |

## Step 1: Add `gitlab.rb` attributes

Add your component's configuration namespace under `oak['components']['<component>']`
in `files/gitlab-cookbooks/oak/attributes/default.rb`:

```ruby
# oak['components']['mycomponent'] defaults
default['oak']['components']['mycomponent']['enable']       = false
default['oak']['components']['mycomponent']['internal_url'] = nil   # URL Omnibus NGINX proxies to
default['oak']['components']['mycomponent']['external_url'] = nil   # public-facing URL (FQDN)
```

Top-level `oak['enable']` and `oak['network_address']` are shared across all
components and are already defined by the OAK cookbook base
([!9235](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9235)).

Document every new attribute in `files/gitlab-config-template/gitlab.rb.template`
with a comment block explaining its purpose and accepted values.

### `gitlab.rb` attributes table (template for your documentation)

| Attribute | Type | Default | Description |
|---|---|---|---|
| `oak['components']['<component>']['enable']` | Boolean | `false` | Enable the component integration |
| `oak['components']['<component>']['internal_url']` | String | `nil` | URL Omnibus NGINX proxies to (LoadBalancer / NodePort / ClusterIP) |
| `oak['components']['<component>']['external_url']` | String | `nil` | Public-facing URL; determines NGINX `server_name` and TLS SAN |

## Step 2: Add the NGINX reverse proxy

The component team owns the NGINX configuration for their component.
It must not affect other components' NGINX blocks.

### Parse variables at compile time (priority 19)

Create `files/gitlab-cookbooks/oak/libraries/<component>.rb` following the
pattern in `files/gitlab-cookbooks/oak/libraries/openbao.rb`
([!9289](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9289)):

```ruby
module Oak
  module MyComponent
    class << self
      def parse_variables
        return unless Oak.enabled?
        return unless component_enabled?

        # Validate required attributes, then derive fqdn, listen_port, and
        # https from external_url. Auto-infer gitlab_rails settings from OAK
        # config, respecting operator overrides.
      end

      def component_enabled?
        !!Gitlab['oak']['components']&.dig('mycomponent', 'enable')
      end
    end
  end
end
```

Wire the new module into `Oak.parse_variables` in
`files/gitlab-cookbooks/oak/libraries/oak.rb`: add a `require_relative` for the
new file and call `Oak::MyComponent.parse_variables` from `Oak.parse_variables`.
The `oak` attribute block is already registered at compile time (priority 19)
in `files/gitlab-cookbooks/package/libraries/config/gitlab.rb`, so no
additional registration is needed.

### NGINX server block template

Create `files/gitlab-cookbooks/oak/templates/default/nginx-gitlab-mycomponent.conf.erb`
following `nginx-gitlab-openbao.conf.erb`
([!9289](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9289),
[!9331](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9331)).
The `nginx_configuration` resource derives the template name
`nginx-gitlab-<component>.conf.erb` from the component name, so the
`nginx-gitlab-` prefix is required. The OpenBao template handles:

- HTTP-only (`listen 80`)
- HTTPS with operator-supplied cert (`listen 443 ssl`)
- HTTPS with Let's Encrypt (shared SAN on the main GitLab cert)
- HTTP→HTTPS redirect block (when `redirect_http_to_https` is true or LE is enabled)
- ACME `/.well-known/acme-challenge/` path in both redirect and main blocks

This list reflects the OpenBao worked example, which is proxied over plain
HTTP/HTTPS. Do not copy it verbatim. A component that speaks a different
protocol (for example, gRPC or WebSockets) or listens on non-standard ports
needs a server block matched to its own protocol, ports, and TLS
requirements.

### Render the configuration from the `oak::enable` recipe

`files/gitlab-cookbooks/oak/recipes/enable.rb` already iterates
`oak['components']` and uses the `nginx_configuration` resource to:

1. Render the template to `/var/opt/gitlab/nginx/conf/gitlab-mycomponent.conf`
   when both NGINX and the component are enabled.
1. Delete the file when the component is disabled.
1. Notify the NGINX service to restart.

Extend the `case` statement in that recipe to pass your component's template
variables. The recipe is included from
`files/gitlab-cookbooks/gitlab/recipes/default.rb` when `oak['enable']` is set,
so no NGINX include changes are needed.

### Unit tests

Extend the ChefSpec tests in
`spec/chef/cookbooks/oak/recipes/enable_spec.rb` covering:

- Component disabled → configuration file absent.
- Component enabled, HTTP → correct `listen`, `server_name`, `proxy_pass`.
- Component enabled, HTTPS → `listen 443 ssl`, cert paths.
- Let's Encrypt enabled → ACME path present in redirect block.

## Step 3: Add the Helm values file (optional but recommended)

If your component is deployed by using Helm, generate a ready-to-use values
file at reconfigure time following
[!9290](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9290):

1. Create `files/gitlab-cookbooks/oak/templates/default/mycomponent-helm-values.yaml.erb`.
   The `oak::enable` recipe infers the template name from the component name
   (`<component>-helm-values.yaml.erb`), so the naming convention is required.
1. Add a `helm_values_path` default (for example
   `/etc/gitlab/mycomponent-helm-values.yaml`) to the component attributes.
   The `oak::enable` recipe writes the file when the component is enabled and
   deletes it when disabled.
1. Auto-fill connection details from Omnibus attributes (`oak['network_address']`,
   PostgreSQL port, `gitlab['external_url']`, and so on) by extending the
   template variables in `files/gitlab-cookbooks/oak/recipes/enable.rb`.

Document which fields are auto-filled and which the operator must supply in
their own values file.

## Step 4: Document the component database (if needed)

If your component needs its own PostgreSQL database on the GitLab-managed
PostgreSQL cluster, use the `postgresql['component_databases']` framework
introduced in
[!9440](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9440).

The framework is fully generic: a new component requires no `omnibus-gitlab`
code changes. Following
[ADR-006](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/omnibus_adjacent_kubernetes/decisions/006_no_automated_database_preparation/),
Omnibus does not provision the database automatically when the component is
enabled: the operator must add the entry to `gitlab.rb` explicitly. Your work
in this step is to check eligibility, document the exact entry in the
component's setup guide, and verify the behavior end to end.

**Eligibility rule:** The component's schema must support PostgreSQL
WAL-based replication (the same replication GitLab Geo uses for Rails databases).

### Operator configuration

```ruby
postgresql['component_databases'] = {
  'mycomponent' => {
    'enable'     => true,
    'user'       => 'mycomponent',
    'password'   => 'changeme',          # or use extra_config_command
    'database'   => 'mycomponent_production',  # optional; defaults to the key
    'extensions' => ['pg_trgm'],         # optional
  }
}
```

### What the framework provides automatically

- Creates the PostgreSQL role, database, and extensions on `gitlab-ctl reconfigure`.
- When PgBouncer is enabled, adds a pool entry inheriting `host`/`port` from
  the Rails pool entry (HA-safe, no extra configuration needed).
- Propagates the new primary's address to the component database on Patroni
  failover through `gitlab-ctl pgb-notify`.

### Fetching secrets without putting them in `gitlab.rb`

```ruby
postgresql['component_databases'] = {
  'mycomponent' => {
    'enable'              => true,
    'user'                => 'mycomponent',
    'extra_config_command' => '/etc/gitlab/fetch-mycomponent-secret',
    # password is supplied by the script — no plaintext in gitlab.rb
  }
}
```

The script's stdout is parsed as YAML and merged into the entry at reconfigure
time. Stderr and exit code surface in error messages; stdout is never logged.

## Step 5: Add a CI job

Add a BATS-based end-to-end test following
[!9359](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9359) and
[!9370](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9370):

1. Add a `.bats` file under `oak-tests/` following `oak-tests/nginx-openbao.bats`.
   The test configures `gitlab.rb` with the component enabled, runs
   `gitlab-ctl reconfigure`, and asserts that the expected NGINX configuration file
   exists and contains the correct `server_name`, `proxy_pass`, and
   (if HTTPS) `listen 443 ssl` directives.
1. Register the new file in the `bats` invocation at the end of `oak-tests/test`.

The existing `OAK:smoke-test` job in `gitlab-ci-config/gitlab-com.yml` runs
`oak-tests/test` against the branch Docker image through
`bundle exec rake qa:test_oak`, so no new CI job is needed unless your
component requires a different test environment.

**Known gap:** As of 19.2, the CI job for OpenBao only covers the NGINX
proxy check. Extend your job to cover the database framework and Helm values
file if applicable.

## Step 6: Write operator documentation

Create or update the component's installation page on `docs.gitlab.com`
(in the `gitlab-org/gitlab` repository under `doc/administration/`).

The page must cover colocated and external-cluster setups and include:

- Prerequisites (Kubernetes cluster, Helm chart, network access).
- Minimum `gitlab.rb` configuration for each setup.
- Which nodes need the settings in multi-node Omnibus deployments.
- How to generate and use the Helm values file (if applicable).
- How to configure the component database (if applicable).
- TLS / Let's Encrypt configuration.
- Verification steps.

See [GitLab MR !241878](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241878)
for the OpenBao example.

## PREP checklist items

When filing a PREP item for your component, the following OAK-specific items
must be completed:

- [ ] `gitlab.rb` settings are added and documented (Step 1).
- [ ] NGINX reverse proxy configuration is implemented and tested (Step 2).
- [ ] Helm values file generation is implemented (Step 3, if applicable).
- [ ] Component database configuration is documented (Step 4, if applicable).
- [ ] CI job is added (Step 5).
- [ ] Operator documentation is published (Step 6).
- [ ] The component team has verified colocated and external-cluster setups,
      including multi-node Omnibus where applicable.

## Known gaps and open issues

- The `OAK:smoke-test` CI job only verifies the NGINX proxy configuration.
  The component database framework and the Helm values file are not yet
  covered by CI.
- `files/gitlab-cookbooks/oak/recipes/enable.rb` still hardcodes OpenBao
  template variables for the NGINX and Helm values templates. See the `TODO`
  comments in that recipe.
