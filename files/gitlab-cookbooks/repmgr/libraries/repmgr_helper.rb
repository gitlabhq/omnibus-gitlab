class RepmgrHelper
  def initialize(node)
    @node = node
  end

  def pg_hba_entries
    results = []
    replication_user = @node['repmgr']['user']
    %W(replication #{@node['repmgr']['database']}).each do |db|
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

      @node['repmgr']['trust_auth_cidr_addresses'].each do |addr|
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
end
