# Whether OAK (Omnibus-to-Kubernetes bridge) integration is enabled.
default['oak']['enable'] = false

# Network address of the OAK cluster entry point (e.g. K8s load-balancer or
# ingress host:port). Must be set explicitly when enabled is true.
default['oak']['network_address'] = nil

# Per-component configuration hash. Each key is a component name (e.g.
# 'openbao') and the value is a hash with:
#   enable   - whether this component is active
#   internal_url  - full URL where the component is reachable from this host
#   requires - array of Omnibus services this component needs (e.g. ['postgresql', 'redis'])
# Component-specific keys (e.g. external_url, helm_values_path) are also kept
# here so all per-component config lives in one place.
default['oak']['components'] = {}

##
# OAK OpenBao component settings (all under oak['components']['openbao']).
##

# External URL for the OpenBao service. Must be set when the openbao component
# is enabled. Parsed to derive the nginx server_name and listen port, following
# the same convention as registry_external_url.
default['oak']['components']['openbao']['external_url'] = nil
