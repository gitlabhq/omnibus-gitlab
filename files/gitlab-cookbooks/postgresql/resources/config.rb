property :name, String, name_property: true
property :username, default: lazy { node['postgresql']['username'] }
property :data_dir, default: lazy { node['postgresql']['data_dir'] }
property :pg_helper, default: lazy { PgHelper.new(node) }

action :create do
  postgresql_config = ::File.join(new_resource.data_dir, "postgresql.conf")
  postgresql_runtime_config = ::File.join(new_resource.data_dir, 'runtime.conf')
  postgresql_helper = new_resource.pg_helper

  template postgresql_config do
    source 'postgresql.conf.erb'
    owner new_resource.username
    mode '0644'
    helper(:pg_helper) { postgresql_helper }
    variables(node['postgresql'].to_hash)
  end

  template postgresql_runtime_config do
    source 'postgresql-runtime.conf.erb'
    owner new_resource.username
    mode '0644'
    helper(:pg_helper) { postgresql_helper }
    variables(node['postgresql'].to_hash)
  end

  pg_hba_config = ::File.join(new_resource.data_dir, "pg_hba.conf")

  template pg_hba_config do
    source 'pg_hba.conf.erb'
    owner new_resource.username
    mode "0644"
    variables(lazy { node['postgresql'].to_hash })
  end

  template ::File.join(new_resource.data_dir, 'pg_ident.conf') do
    owner new_resource.username
    mode "0644"
    variables(node['postgresql'].to_hash)
  end
end
