resource_name :rails_migration
provides :rails_migration

unified_mode true

property :name, name_property: true
property :logfile_prefix, String, required: true
property :rake_task, String, required: true
property :helper, required: true, sensitive: true
property :environment, sensitive: true
property :dependent_services, Array, default: []

default_action :run

action :run do
  account_helper = AccountHelper.new(node)

  bash "migrate #{new_resource.name} database" do
    code <<-EOH
    set -e
    log_file="#{node['gitlab']['gitlab-rails']['log_directory']}/#{new_resource.logfile_prefix}-$(date +%Y-%m-%d-%H-%M-%S).log"
    umask 077
    /opt/gitlab/bin/gitlab-rake #{new_resource.rake_task} 2>& 1 | tee ${log_file}
    STATUS=${PIPESTATUS[0]}
    chown #{account_helper.gitlab_user}:#{account_helper.gitlab_group} ${log_file}
    echo $STATUS > #{new_resource.helper.db_migrate_status_file}
    exit $STATUS
    EOH

    environment new_resource.environment if new_resource.property_is_set?(:environment)
    new_resource.dependent_services.each do |svc|
      notifies :restart, svc, :immediately
    end

    not_if { new_resource.helper.migrated? }
    sensitive true
  end
end
