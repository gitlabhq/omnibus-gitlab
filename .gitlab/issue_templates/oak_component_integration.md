## OAK Component Integration: <Component Name>

**Component:** <!-- e.g. MyComponent -->
**Team / Group:** <!-- e.g. group::secrets manager application -->
**Epic / tracking issue:** <!-- link -->

---

### Overview

<!-- One paragraph describing what this component does and why it needs OAK integration. -->

### Setups in scope

All setups must work with the same `gitlab.rb` configuration surface
(see [ADR-004](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/omnibus_adjacent_kubernetes/decisions/004_multi_node_omnibus_support/)).
Their end-to-end verification is tracked in the [Definition of done](#definition-of-done):

- Colocated (component Kubernetes cluster on the same host as a single-node Omnibus)
- External cluster (component in a customer-provided cluster on separate infrastructure)
- Multi-node Omnibus (settings applied on every consuming node; Helm values generated on the Rails node)

---

## Step 1 — `gitlab.rb` attributes

> Reference: [omnibus-gitlab!9289](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9289)
> Guide: [doc/development/oak_component_integration.md § Step 1](../../doc/development/oak_component_integration.md#step-1-add-gitlabrb-attributes)

- [ ] Add `oak['components']['<component>']` defaults to `files/gitlab-cookbooks/oak/attributes/default.rb`
- [ ] Document every new attribute in `files/gitlab-config-template/gitlab.rb.template`

**Attributes to add:**

| Attribute | Type | Default | Description |
|---|---|---|---|
| `oak['components']['<component>']['enable']` | Boolean | `false` | Enable the component integration |
| `oak['components']['<component>']['internal_url']` | String | `nil` | URL Omnibus NGINX proxies to |
| `oak['components']['<component>']['external_url']` | String | `nil` | Public-facing URL / FQDN |
| <!-- add more --> | | | |

---

## Step 2 — NGINX reverse proxy

> Reference: [omnibus-gitlab!9289](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9289) (HTTP), [omnibus-gitlab!9331](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9331) (HTTPS + LE)
> Guide: [doc/development/oak_component_integration.md § Step 2](../../doc/development/oak_component_integration.md#step-2-add-the-nginx-reverse-proxy)

The component team owns this NGINX configuration. It must not affect other components.

- [ ] Create `files/gitlab-cookbooks/oak/libraries/<component>.rb` with `parse_variables` (derives `fqdn`, `listen_port`, and `https` from `external_url`)
- [ ] Call `Oak::<Component>.parse_variables` from `Oak.parse_variables` in `files/gitlab-cookbooks/oak/libraries/oak.rb`
- [ ] Create `files/gitlab-cookbooks/oak/templates/default/nginx-gitlab-<component>.conf.erb` (HTTP + HTTPS + LE + redirect is the OpenBao pattern; adjust to the component's own protocol and ports)
- [ ] Extend the `case` statement in `files/gitlab-cookbooks/oak/recipes/enable.rb` with the component's template variables
- [ ] Extend the ChefSpec tests in `spec/chef/cookbooks/oak/recipes/enable_spec.rb`
  - [ ] Component disabled → config file absent
  - [ ] HTTP → correct `listen`, `server_name`, `proxy_pass`
  - [ ] HTTPS → `listen 443 ssl`, cert paths
  - [ ] Let's Encrypt → ACME path in redirect block

**OAK integration settings (for PREP checklist):**

- [ ] `gitlab.rb` settings are added and documented
- [ ] Reverse proxy and TLS settings are implemented when the component is exposed through Omnibus' NGINX

---

## Step 3 — Helm values file generation (if applicable)

> Reference: [omnibus-gitlab!9290](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9290)
> Guide: [doc/development/oak_component_integration.md § Step 3](../../doc/development/oak_component_integration.md#step-3-add-the-helm-values-file-optional-but-recommended)

- [ ] Create `files/gitlab-cookbooks/oak/templates/default/<component>-helm-values.yaml.erb`
- [ ] Auto-fill connection details from Omnibus attributes
- [ ] Write/delete the file at `oak['components']['<component>']['helm_values_path']` on reconfigure
- [ ] Document which fields are auto-filled vs operator-supplied

**Auto-filled fields:**

| Helm field | Source |
|---|---|
| <!-- e.g. `config.storage.postgresql.connection.host` --> | <!-- e.g. `oak['network_address']` --> |

---

## Step 4 — Component database (if applicable)

> Reference: [omnibus-gitlab!9440](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9440)
> Guide: [doc/development/oak_component_integration.md § Step 4](../../doc/development/oak_component_integration.md#step-4-document-the-component-database-if-needed)

**No omnibus-gitlab code changes are needed.** The framework is generic, and per
[ADR-006](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/omnibus_adjacent_kubernetes/decisions/006_no_automated_database_preparation/)
the operator configures the database explicitly. This step is documentation and verification only.

**Eligibility check:** The component's schema must support PostgreSQL WAL-based replication. ✅ / ❌

- [ ] Confirm WAL replication eligibility
- [ ] Document the copy-pasteable `postgresql['component_databases']` entry in the component's operator documentation
- [ ] Verify PgBouncer pool auto-merge works (single-node and HA)
- [ ] Verify Patroni failover propagation via `gitlab-ctl pgb-notify`
- [ ] Test `extra_config_command` secret fetching (if applicable)

**Minimum operator config:**

```ruby
postgresql['component_databases'] = {
  '<component>' => {
    'enable'   => true,
    'user'     => '<component>',
    'password' => 'changeme',
  }
}
```

---

## Step 5 — CI job

> Reference: [omnibus-gitlab!9359](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9359), [omnibus-gitlab!9370](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9370)
> Guide: [doc/development/oak_component_integration.md § Step 5](../../doc/development/oak_component_integration.md#step-5-add-a-ci-job)

- [ ] Add a `.bats` test under `oak-tests/` covering:
  - [ ] Component disabled → NGINX config absent
  - [ ] Component enabled → NGINX config present with correct `server_name` and `proxy_pass`
  - [ ] (If HTTPS) `listen 443 ssl` present
  - [ ] (If database) database role and database exist after reconfigure
  - [ ] (If Helm values) values file generated at expected path
- [ ] Register the new file in the `bats` invocation in `oak-tests/test`
- [ ] Verify the `OAK:smoke-test` job passes in CI

---

## Step 6 — Operator documentation

> Reference: [gitlab-org/gitlab!241878](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241878)
> Guide: [doc/development/oak_component_integration.md § Step 6](../../doc/development/oak_component_integration.md#step-6-write-operator-documentation)

- [ ] Create/update the component's installation page on docs.gitlab.com
- [ ] Cover colocated and external-cluster setups
- [ ] Document which nodes need the settings in multi-node Omnibus deployments
- [ ] Include minimum `gitlab.rb` configuration for each setup
- [ ] Document Helm values file usage (if applicable)
- [ ] Document component database configuration (if applicable)
- [ ] Document TLS / Let's Encrypt configuration
- [ ] Include verification steps

**Docs MR:** <!-- link to gitlab-org/gitlab MR -->

---

## Definition of done

- [ ] Colocated and external-cluster setups verified end-to-end (including multi-node Omnibus where applicable)
- [ ] ChefSpec tests pass
- [ ] CI job passes
- [ ] Operator documentation published
- [ ] PREP checklist items completed (see [PREP template](https://gitlab.com/gitlab-org/architecture/readiness/-/blob/main/templates/installation_configuration/omnibus_adjacent_kubernetes.md))

/label ~"type::feature"
/label ~group::
