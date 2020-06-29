class PatroniHelper < BaseHelper
  include ShellOutHelper

  DCS_ATTRIBUTES ||= %w(loop_wait ttl retry_timeout maximum_lag_on_failover max_timelines_history master_start_timeout).freeze
  DCS_POSTGRESQL_ATTRIBUTES ||= %w(use_pg_rewind use_slots).freeze

  attr_reader :node

  def ctl_command
    "#{node['package']['install-dir']}/embedded/bin/patronictl"
  end

  def service_name
    'patroni'
  end

  def running?
    OmnibusHelper.new(node).service_up?(service_name)
  end

  def bootstrapped?
    File.exist?(File.join(node['postgresql']['data_dir'], 'patroni.dynamic.json'))
  end

  def scope
    node['patroni']['scope']
  end

  def node_status
    return 'not running' unless running?

    cmd = "#{ctl_command} -c #{node['patroni']['dir']}/patroni.yaml list | grep #{node.name} | cut -d '|' -f 6"
    do_shell_out(cmd).stdout.chomp.strip
  end

  def repmgr_data_present?
    cmd = "/opt/gitlab/embedded/bin/repmgr -f #{node['postgresql']['dir']}/repmgr.conf cluster show"
    status = do_shell_out(cmd, node['postgresql']['username'])
    status.exitstatus.zero?
  end

  def dynamic_settings
    dcs = {
      'postgresql' => {
        'parameters' => {}
      }
    }
    DCS_ATTRIBUTES.each do |key|
      dcs[key] = node['patroni'][key]
    end
    DCS_POSTGRESQL_ATTRIBUTES.each do |key|
      dcs['postgresql'][key] = node['patroni'][key]
    end
    node['patroni']['postgresql'].each do |key, value|
      dcs['postgresql']['parameters'][key] = value
    end
    dcs
  end

  def public_attributes
    return {} unless Gitlab['patroni']['enable']

    {
      'patroni' => {
        'config_dir' => node['patroni']['dir'],
        'data_dir' => node['patroni']['data_dir'],
        'log_dir' => node['patroni']['log_directory'],
        'api_address' => "#{node['patroni']['listen_address'] || '127.0.0.1'}:#{node['patroni']['port']}"
      }
    }
  end
end
