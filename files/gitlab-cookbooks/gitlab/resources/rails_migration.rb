resource_name :rails_migration
provides :rails_migration

property :migration_name, name_property: true
property :migration_logfile_prefix, String, required: true
property :migration_task, String, required: true
property :migration_helper, required: true
property :environment
property :dependent_services

default_action :run

action :run do
  account_helper = AccountHelper.new(node)

  bash "migrate #{new_resource.migration_name} database" do
    code <<-EOH
    set -e
    log_file="#{node['gitlab']['gitlab-rails']['log_directory']}/#{new_resource.migration_logfile_prefix}-$(date +%Y-%m-%d-%H-%M-%S).log"
    umask 077
    /opt/gitlab/bin/gitlab-rake #{new_resource.migration_task} 2>& 1 | tee ${log_file}
    STATUS=${PIPESTATUS[0]}
    chown #{account_helper.gitlab_user}:#{account_helper.gitlab_group} ${log_file}
    echo $STATUS > #{new_resource.migration_helper.db_migrate_status_file}
    exit $STATUS
    EOH

    environment new_resource.environment if property_is_set?(:environment)
    new_resource.dependent_services.each do |svc|
      notifies :restart, svc, :immediately
    end

    not_if { new_resource.migration_helper.migrated? }
    only_if { new_resource.migration_helper.attributes_node['auto_migrate'] }
  end
end
