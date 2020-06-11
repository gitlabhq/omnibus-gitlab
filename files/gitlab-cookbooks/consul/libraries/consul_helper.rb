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

  def postgresql_service_config
    return node['consul']['service_config']['postgresql'] || {} unless node['consul']['service_config'].nil?

    ha_solution = Gitlab['patroni']['enable'] ? 'patroni' : 'repmgr'
    cfg = {
      'service' => {
        'name' => node['consul']['internal']['postgresql_service_name'],
        'address' => '',
        'port' => node['postgresql']['port'],
        'check' => {
          'id': "service:#{node['consul']['internal']['postgresql_service_name']}",
          'interval' => node['consul']['internal']['postgresql_service_check_interval'],
          'status': node['consul']['internal']['postgresql_service_check_status'],
          'args': node['consul']['internal']["postgresql_service_check_args_#{ha_solution}"]
        }
      }
    }

    cfg['watches'] = node['consul']['internal']['postgresql_watches_repmgr'] if ha_solution == 'repmgr'

    cfg
  end
end
