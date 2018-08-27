###
# PostgreSQL
###
default['gitlab']['postgresql']['enable'] = false
default['gitlab']['postgresql']['ha'] = false
default['gitlab']['postgresql']['dir'] = "/var/opt/gitlab/postgresql"
default['gitlab']['postgresql']['data_dir'] = nil
default['gitlab']['postgresql']['log_directory'] = "/var/log/gitlab/postgresql"
default['gitlab']['postgresql']['unix_socket_directory'] = nil
default['gitlab']['postgresql']['username'] = "gitlab-psql"
default['gitlab']['postgresql']['group'] = "gitlab-psql"
default['gitlab']['postgresql']['uid'] = nil
default['gitlab']['postgresql']['gid'] = nil
default['gitlab']['postgresql']['shell'] = "/bin/sh"
default['gitlab']['postgresql']['home'] = nil
# Postgres User's Environment Path
# defaults to /opt/gitlab/embedded/bin:/opt/gitlab/bin/$PATH. The install-dir path is set at build time
default['gitlab']['postgresql']['user_path'] = "#{node['package']['install-dir']}/embedded/bin:#{node['package']['install-dir']}/bin:$PATH"
default['gitlab']['postgresql']['sql_user'] = "gitlab"
default['gitlab']['postgresql']['sql_user_password'] = nil
default['gitlab']['postgresql']['sql_mattermost_user'] = "gitlab_mattermost"
default['gitlab']['postgresql']['port'] = 5432
# Postgres allow multi listen_address, comma-separated values.
# If used, first address from the list will be use for connection
default['gitlab']['postgresql']['listen_address'] = nil
default['gitlab']['postgresql']['max_connections'] = 200
default['gitlab']['postgresql']['md5_auth_cidr_addresses'] = []
default['gitlab']['postgresql']['trust_auth_cidr_addresses'] = []

default['gitlab']['postgresql']['ssl'] = 'on'
default['gitlab']['postgresql']['ssl_ciphers'] = 'HIGH:MEDIUM:+3DES:!aNULL:!SSLv3:!TLSv1'
default['gitlab']['postgresql']['ssl_cert_file'] = 'server.crt'
default['gitlab']['postgresql']['ssl_key_file'] = 'server.key'
default['gitlab']['postgresql']['ssl_ca_file'] = "#{node['package']['install-dir']}/embedded/ssl/certs/cacert.pem"
default['gitlab']['postgresql']['ssl_crl_file'] = nil

default['gitlab']['postgresql']['shmmax'] = /x86_64/.match?(node['kernel']['machine']) ? 17179869184 : 4294967295
default['gitlab']['postgresql']['shmall'] = /x86_64/.match?(node['kernel']['machine']) ? 4194304 : 1048575
default['gitlab']['postgresql']['semmsl'] = 250
default['gitlab']['postgresql']['semmns'] = 32000
default['gitlab']['postgresql']['semopm'] = 32
default['gitlab']['postgresql']['semmni'] = ((node['gitlab']['postgresql']['max_connections'].to_i / 16) + 250)

# Resolves CHEF-3889
default['gitlab']['postgresql']['shared_buffers'] = if (node['memory']['total'].to_i / 4) > ((node['gitlab']['postgresql']['shmmax'].to_i / 1024) - 2097152)
                                                      # guard against setting shared_buffers > shmmax on hosts with installed RAM > 64GB
                                                      # use 2GB less than shmmax as the default for these large memory machines
                                                      "14336MB"
                                                    else
                                                      "#{(node['memory']['total'].to_i / 4) / 1024}MB"
                                                    end

default['gitlab']['postgresql']['work_mem'] = "16MB"
default['gitlab']['postgresql']['maintenance_work_mem'] = "16MB"
default['gitlab']['postgresql']['effective_cache_size'] = "#{(node['memory']['total'].to_i / 2) / 1024}MB"
default['gitlab']['postgresql']['log_min_duration_statement'] = -1 # Disable slow query logging by default
default['gitlab']['postgresql']['checkpoint_segments'] = 10
default['gitlab']['postgresql']['min_wal_size'] = '80MB'
default['gitlab']['postgresql']['max_wal_size'] = '1GB'
default['gitlab']['postgresql']['checkpoint_timeout'] = "5min"
default['gitlab']['postgresql']['checkpoint_completion_target'] = 0.9
default['gitlab']['postgresql']['checkpoint_warning'] = "30s"
default['gitlab']['postgresql']['wal_buffers'] = "-1"
default['gitlab']['postgresql']['autovacuum'] = "on"
default['gitlab']['postgresql']['log_autovacuum_min_duration'] = "-1"
default['gitlab']['postgresql']['autovacuum_max_workers'] = "3"
default['gitlab']['postgresql']['autovacuum_naptime'] = "1min"
default['gitlab']['postgresql']['autovacuum_vacuum_threshold'] = "50"
default['gitlab']['postgresql']['autovacuum_analyze_threshold'] = "50"
default['gitlab']['postgresql']['autovacuum_vacuum_scale_factor'] = "0.02" # 10x lower than PG defaults
default['gitlab']['postgresql']['autovacuum_analyze_scale_factor'] = "0.01" # 10x lower than PG defaults
default['gitlab']['postgresql']['autovacuum_freeze_max_age'] = "200000000"
default['gitlab']['postgresql']['autovacuum_vacuum_cost_delay'] = "20ms"
default['gitlab']['postgresql']['autovacuum_vacuum_cost_limit'] = "-1"
default['gitlab']['postgresql']['statement_timeout'] = '60000'
default['gitlab']['postgresql']['idle_in_transaction_session_timeout'] = '60000'
default['gitlab']['postgresql']['log_line_prefix'] = nil
default['gitlab']['postgresql']['log_statement'] = nil
default['gitlab']['postgresql']['track_activity_query_size'] = "1024"
default['gitlab']['postgresql']['shared_preload_libraries'] = nil
default['gitlab']['postgresql']['dynamic_shared_memory_type'] = nil
default['gitlab']['postgresql']['random_page_cost'] = 2.0
default['gitlab']['postgresql']['max_locks_per_transaction'] = 128
default['gitlab']['postgresql']['log_temp_files'] = -1
default['gitlab']['postgresql']['log_checkpoints'] = 'off'
default['gitlab']['postgresql']['custom_pg_hba_entries'] = {}
default['gitlab']['postgresql']['effective_io_concurrency'] = 1
default['gitlab']['postgresql']['max_worker_processes'] = 8
default['gitlab']['postgresql']['max_parallel_workers_per_gather'] = 0
default['gitlab']['postgresql']['log_lock_waits'] = 1
default['gitlab']['postgresql']['deadlock_timeout'] = '5s'
default['gitlab']['postgresql']['track_io_timing'] = 'off'
default['gitlab']['postgresql']['default_statistics_target'] = 1000

# Replication settings
default['gitlab']['postgresql']['sql_replication_user'] = "gitlab_replicator"
default['gitlab']['postgresql']['wal_level'] = "minimal"
default['gitlab']['postgresql']['max_wal_senders'] = 0
default['gitlab']['postgresql']['wal_keep_segments'] = 10
default['gitlab']['postgresql']['hot_standby'] = "off"
default['gitlab']['postgresql']['max_standby_archive_delay'] = "30s"
default['gitlab']['postgresql']['max_standby_streaming_delay'] = "30s"
default['gitlab']['postgresql']['max_replication_slots'] = 0
default['gitlab']['postgresql']['synchronous_commit'] = 'on'
default['gitlab']['postgresql']['synchronous_standby_names'] = ''
default['gitlab']['postgresql']['hot_standby_feedback'] = 'off'

# Backup/Archive settings
default['gitlab']['postgresql']['archive_mode'] = "off"
default['gitlab']['postgresql']['archive_command'] = nil
default['gitlab']['postgresql']['archive_timeout'] = "0"
