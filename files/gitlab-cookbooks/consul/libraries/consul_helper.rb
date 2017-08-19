class ConsulHelper
  attr_reader :node, :default_configuration

  def initialize(node)
    @node = node
    @default_configuration = {
      'client_addr' => nil,
      'datacenter' => 'gitlab_consul',
      'disable_update_check' => true,
      'enable_script_checks' => true,
      'node_name' => node['fqdn'],
      'rejoin_after_leave' => true,
      'server' => false
    }
  end

  def watcher_config(watcher)
    {
      watches: [
        {
          type: 'service',
          service: watcher,
          handler: "#{node['consul']['script_directory']}/#{node['consul']['watcher_config'][watcher]['handler']}"
        }
      ]
    }
  end

  def configuration
    Chef::Mixin::DeepMerge.merge(
      default_configuration,
      node['consul']['configuration']
    ).select { |k, v| !v.nil? }.to_json
  end
end
