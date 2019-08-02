class RepmgrHelper < BaseHelper
  attr_accessor :node

  def pg_hba_entries
    results = []
    replication_user = node['repmgr']['username']
    %W(replication #{node['repmgr']['database']}).each do |db|
      results.push(
        *[
          {
            type: 'local',
            database: db,
            user: replication_user,
            method: 'trust'
          },
          {
            type: 'host',
            database: db,
            user: replication_user,
            cidr: '127.0.0.1/32',
            method: 'trust'
          }
        ]
      )

      node['repmgr']['trust_auth_cidr_addresses'].each do |addr|
        results.push(
          {
            type: 'host',
            database: db,
            user: replication_user,
            cidr: addr,
            method: 'trust'
          }
        )
      end
    end
    results
  end

  # node number needs to be unique (to the cluster) positive 32 bit integer.
  # If the user doesn't provide one, generate one ourselves.
  def generate_node_number
    seed_data = if node['fqdn'].nil?
                  "#{node['ipaddress']}#{node['macaddress']}#{node['ip6address']}"
                else
                  node['fqdn']
                end
    Digest::MD5.hexdigest(seed_data).unpack1('L')
  end

  def public_attributes
    {
      'repmgr' => node['repmgr'].select do |key, value|
                    %w(username database node_name).include?(key)
                  end
    }
  end
end
