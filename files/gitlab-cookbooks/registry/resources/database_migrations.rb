unified_mode true

property :name, name_property: true

default_action :nothing

action :run do
  account_helper = AccountHelper.new(node)
  logfiles_helper = LogfilesHelper.new(node)
  logging_settings = logfiles_helper.logging_settings('registry')

  # Determine if post-deployment migrations should be skipped
  skip_post_deployment = ENV['SKIP_POST_DEPLOYMENT_MIGRATIONS'].to_s.casecmp?('true')

  bash_hide_env "migrate registry database: #{new_resource.name}" do
    code <<-EOH
    set -e

    LOG_FILE="#{logging_settings[:log_directory]}/db-migrations-$(date +%Y-%m-%d-%H-%M-%S).log"

    umask 077
    gitlab-ctl registry-database migrate up \
      #{'--skip-post-deployment' if skip_post_deployment} \
      2>& 1 | tee ${LOG_FILE}

    STATUS=${PIPESTATUS[0]}
    chown #{account_helper.registry_user}:#{account_helper.registry_group} ${LOG_FILE}
    exit $STATUS
    EOH

    user account_helper.registry_user
    group account_helper.registry_group
  end
end
