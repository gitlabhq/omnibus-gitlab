property :name, String, name_property: true
property :username, default: lazy { node['postgresql']['username'] }
property :pg_helper, default: lazy { PgHelper.new(node) }

action :create do
  postgresql_helper = new_resource.pg_helper

  template postgresql_helper.postgresql_config do
    geo_config = { geo_secondary_enabled: node.dig('gitlab', 'geo-secondary', 'enable') }
    source 'postgresql.conf.erb'
    owner new_resource.username
    mode '0644'
    helper(:pg_helper) { postgresql_helper }
    variables(node['postgresql'].to_hash.merge(geo_config))
  end

  template postgresql_helper.postgresql_runtime_config do
    source 'postgresql-runtime.conf.erb'
    owner new_resource.username
    mode '0644'
    helper(:pg_helper) { postgresql_helper }
    variables(node['postgresql'].to_hash)
  end

  template postgresql_helper.pg_hba_config do
    source 'pg_hba.conf.erb'
    owner new_resource.username
    mode "0644"
    variables(lazy { node['postgresql'].to_hash })
  end

  template postgresql_helper.pg_ident_config do
    source 'pg_ident.conf.erb'
    owner new_resource.username
    mode "0644"
    variables(node['postgresql'].to_hash)
  end
end
