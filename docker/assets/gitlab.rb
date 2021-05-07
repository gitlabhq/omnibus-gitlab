# Initialize the env config for each service in case we need to add them in via the wrapper
unless ENV['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'].nil?
  [gitlab_workhorse['env'], gitlab_pages['env'], registry['env'], gitlab_rails['env']].each do |new_env|
    new_env['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'] = ENV['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI']
    new_env['AWS_REGION'] = ENV['AWS_REGION']
    new_env['ECS_CONTAINER_METADATA_URI_V4'] = ENV['ECS_CONTAINER_METADATA_URI_V4'] unless ENV['ECS_CONTAINER_METADATA_URI_V4'].nil?
    new_env['ECS_CONTAINER_METADATA_URI'] = ENV['ECS_CONTAINER_METADATA_URI']
  end
end

# Docker options
## Prevent Postgres from trying to allocate 25% of total memory
postgresql['shared_buffers'] = '1MB'

# Disable Prometheus node_exporter inside Docker.
node_exporter['enable'] = false

# Manage accounts with docker
manage_accounts['enable'] = false

# Get hostname from shell
host = `hostname`.strip
external_url "http://#{host}"

# Explicitly disable init detection since we are running on a container
package['detect_init'] = false

# Explicitly disable attempt to update kernel parameters
package['modify_kernel_parameters'] = false

# Load custom config from environment variable: GITLAB_OMNIBUS_CONFIG
# Disabling the cop since rubocop considers using eval to be security risk but
# we don't have an easy way out, atleast yet.
eval ENV["GITLAB_OMNIBUS_CONFIG"].to_s # rubocop:disable Security/Eval

# Load configuration stored in /etc/gitlab/gitlab.rb
from_file("/etc/gitlab/gitlab.rb")
