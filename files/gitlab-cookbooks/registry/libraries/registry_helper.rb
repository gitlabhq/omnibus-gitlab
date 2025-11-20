class RegistryHelper < BaseHelper
  attr_reader :node

  def redis_enabled?
    !!node.dig('registry', 'redis', 'loadbalancing', 'enabled')
  end

  def public_attributes
    {
      'registry' => {
        'dir' => node['registry']['dir'],
        'username' => node['registry']['username'],
        'group' => node['registry']['group']
      }
    }
  end
end
