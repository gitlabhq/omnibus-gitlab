class ConsulHelper
  attr_reader :node, :default_configuration, :default_server_configuration

  def initialize(node)
    @node = node
    @default_configuration = {
      'client_addr' => nil,
      'datacenter' => 'gitlab_consul',
      'disable_update_check' => true,
      'enable_script_checks' => true,
      'node_name' => node['consul']['node_name'] || node['fqdn'],
      'rejoin_after_leave' => true,
      'server' => false
    }
    @default_server_configuration = {
      'bootstrap_expect' => 3
    }
  end

  def watcher_config(watcher)
    {
      watches: [
        {
          type: 'service',
          service: watcher,
          args: ["#{node['consul']['script_directory']}/#{watcher_handler(watcher)}"]
        }
      ]
    }
  end

  def watcher_handler(watcher)
    node['consul']['watcher_config'][watcher]['handler']
  end

  def configuration
    config = Chef::Mixin::DeepMerge.merge(
      default_configuration,
      node['consul']['configuration']
    ).select { |k, v| !v.nil? }
    if config['server']
      return Chef::Mixin::DeepMerge.merge(
        default_server_configuration, config
      ).to_json
    end
    config.to_json
  end
end
