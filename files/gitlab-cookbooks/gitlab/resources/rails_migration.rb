resource_name :rails_migration
provides :rails_migration

property :environment
property :dependent_services
property :migration_name, name_property: true

default_action :migrate

action :migrate do
  account_helper = AccountHelper.new(node)

  connection_attributes = %w(
    db_adapter
    db_database
    db_host
    db_port
    db_socket
  ).collect { |attribute| node['gitlab']['gitlab-rails'][attribute] }

  connection_digest = Digest::MD5.hexdigest(Marshal.dump(connection_attributes))
  revision_file = "/opt/gitlab/embedded/service/gitlab-rails/REVISION"
  revision = IO.read(revision_file).chomp if ::File.exist?(revision_file)
  upgrade_status_dir = ::File.join(node['gitlab']['gitlab-rails']['dir'], "upgrade-status")
  db_migrate_status_file = ::File.join(upgrade_status_dir, "db-migrate-#{connection_digest}-#{revision}")

  bash "migrate #{new_resource.migration_name} database" do
    code <<-EOH
    set -e
    log_file="#{node['gitlab']['gitlab-rails']['log_directory']}/gitlab-rails-db-migrate-$(date +%Y-%m-%d-%H-%M-%S).log"
    umask 077
    /opt/gitlab/bin/gitlab-rake gitlab:db:configure 2>& 1 | tee ${log_file}
    STATUS=${PIPESTATUS[0]}
    chown #{account_helper.gitlab_user}:#{account_helper.gitlab_group} ${log_file}
    echo $STATUS > #{db_migrate_status_file}
    exit $STATUS
    EOH

    environment new_resource.environment if property_is_set(:environment)

    notifies :run, "execute[clear the gitlab-rails cache]", :immediately
    notifies :run, "ruby_block[check remote PG version]", :immediately

    new_resource.dependent_services.each do |svc|
      notifies :restart, svc, :immediately
    end

    not_if "(test -f #{db_migrate_status_file}) && (cat #{db_migrate_status_file} | grep -Fx 0)"
    only_if { node['gitlab']['gitlab-rails']['auto_migrate'] }
  end
end
