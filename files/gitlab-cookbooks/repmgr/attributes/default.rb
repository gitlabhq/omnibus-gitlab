default['repmgr']['enable'] = false
default['repmgr']['cluster'] = 'gitlab_cluster'
default['repmgr']['database'] = 'gitlab_repmgr'
default['repmgr']['failover'] = 'automatic'
default['repmgr']['host'] = nil
default['repmgr']['log_directory'] = '/var/log/gitlab/repmgrd'
default['repmgr']['node_name'] = nil
default['repmgr']['node_number'] = nil
default['repmgr']['port'] = 5432
default['repmgr']['trust_auth_cidr_addresses'] = []
default['repmgr']['username'] = 'gitlab_repmgr'
default['repmgr']['sslmode'] = 'prefer'
default['repmgr']['sslcompression'] = 0
default['repmgr']['pg_bindir'] = '/opt/gitlab/embedded/bin'
default['repmgr']['daemon'] = true
default['repmgrd']['enable'] = true
default['repmgr']['service_start_command'] = '/opt/gitlab/bin/gitlab-ctl start postgresql'
default['repmgr']['service_stop_command'] = '/opt/gitlab/bin/gitlab-ctl stop postgresql'
default['repmgr']['service_reload_command'] = '/opt/gitlab/bin/gitlab-ctl hup postgresql'
default['repmgr']['service_restart_command'] = '/opt/gitlab/bin/gitlab-ctl restart postgresql'
default['repmgr']['service_promote_command'] = nil
default['repmgr']['promote_command'] = '/opt/gitlab/embedded/bin/repmgr standby promote -f /var/opt/gitlab/postgresql/repmgr.conf'
default['repmgr']['follow_command'] = '/opt/gitlab/embedded/bin/repmgr standby follow -f /var/opt/gitlab/postgresql/repmgr.conf'

default['repmgr']['upstream_node'] = nil
default['repmgr']['use_replication_slots'] = false
default['repmgr']['loglevel'] = 'INFO'
default['repmgr']['logfacility'] = 'STDERR'
default['repmgr']['logfile'] = nil

default['repmgr']['event_notification_command'] = %(gitlab-ctl repmgr-event-handler  %n %e %s "%t" "%d")
default['repmgr']['event_notifications'] = nil

default['repmgr']['rsync_options'] = nil
default['repmgr']['ssh_options'] = nil
default['repmgr']['priority'] = nil

default['repmgr']['retry_promote_interval_secs'] = 300
default['repmgr']['witness_repl_nodes_sync_interval_secs'] = 15
default['repmgr']['reconnect_attempts'] = 6
default['repmgr']['reconnect_interval'] = 10
default['repmgr']['monitor_interval_secs'] = 2
default['repmgr']['master_response_timeout'] = 60

# HA setting to specify if a node should attempt to be master on initialization
default['repmgr']['master_on_initialization'] = true
