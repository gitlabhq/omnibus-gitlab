# Whether OAK (Omnibus-to-Kubernetes bridge) integration is enabled.
default['oak']['enable'] = false

# Network address of the OAK cluster entry point (e.g. K8s load-balancer or
# ingress host:port). Must be set explicitly when enabled is true.
default['oak']['network_address'] = nil

# Per-component configuration hash. Each key is a component name (e.g.
# 'openbao') and the value is a hash with:
#   enabled  - whether this component is active
#   requires - array of Omnibus services this component needs (e.g. ['postgresql', 'redis'])
#   address  - address where the component is reachable
default['oak']['components'] = {}
