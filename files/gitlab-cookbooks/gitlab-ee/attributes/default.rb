#
# Copyright:: Copyright (c) 2016 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default['gitlab']['sentinel']['enable'] = false
default['gitlab']['sentinel']['bind'] = '0.0.0.0'
default['gitlab']['sentinel']['dir'] = '/var/opt/gitlab/sentinel'
default['gitlab']['sentinel']['log_directory'] = '/var/log/gitlab/sentinel'
default['gitlab']['sentinel']['ha'] = false
default['gitlab']['sentinel']['port'] = 26379
default['gitlab']['sentinel']['password'] = nil
default['gitlab']['sentinel']['quorum'] = 1
default['gitlab']['sentinel']['announce_ip'] = nil
default['gitlab']['sentinel']['announce_port'] = nil
default['gitlab']['sentinel']['down_after_milliseconds'] = 10000
default['gitlab']['sentinel']['failover_timeout'] = 60000
default['gitlab']['sentinel']['myid'] = nil
default['gitlab']['sentinel']['tls_port'] = nil
default['gitlab']['sentinel']['tls_cert_file'] = nil
default['gitlab']['sentinel']['tls_key_file'] = nil
default['gitlab']['sentinel']['tls_dh_params_file'] = nil
default['gitlab']['sentinel']['tls_ca_cert_file'] = "#{node['package']['install-dir']}/embedded/ssl/certs/cacert.pem"
default['gitlab']['sentinel']['tls_ca_cert_dir'] = "#{node['package']['install-dir']}/embedded/ssl/certs/"
default['gitlab']['sentinel']['tls_auth_clients'] = 'optional'
default['gitlab']['sentinel']['tls_replication'] = nil
default['gitlab']['sentinel']['tls_cluster'] = nil
default['gitlab']['sentinel']['tls_protocols'] = nil
default['gitlab']['sentinel']['tls_ciphers'] = nil
default['gitlab']['sentinel']['tls_ciphersuites'] = nil
default['gitlab']['sentinel']['tls_prefer_server_ciphers'] = nil
default['gitlab']['sentinel']['tls_session_caching'] = nil
default['gitlab']['sentinel']['tls_session_cache_size'] = nil
default['gitlab']['sentinel']['tls_session_cache_timeout'] = nil
default['gitlab']['sentinel']['use_hostnames'] = nil

###
# Geo: Common (primary or secondary) node configuration
###
default['gitlab']['gitlab_rails']['geo_node_name'] = nil
default['gitlab']['gitlab_rails']['geo_registry_replication_enabled'] = false
default['gitlab']['gitlab_rails']['geo_registry_replication_primary_api_url'] = nil

###
# Geo: Secondary node configuration
###
default['gitlab']['geo_secondary']['enable'] = false
default['gitlab']['geo_secondary']['auto_migrate'] = true
default['gitlab']['geo_secondary']['db_adapter'] = "postgresql"
default['gitlab']['geo_secondary']['db_encoding'] = "unicode"
default['gitlab']['geo_secondary']['db_collation'] = nil
default['gitlab']['geo_secondary']['db_database'] = "gitlabhq_geo_production"
default['gitlab']['geo_secondary']['db_username'] = "gitlab_geo"
default['gitlab']['geo_secondary']['db_password'] = nil
default['gitlab']['geo_secondary']['db_load_balancing'] = { 'hosts' => [] }
# Path to postgresql socket directory
default['gitlab']['geo_secondary']['db_host'] = nil # when `nil` - value is set from geo_postgresql['dir']
default['gitlab']['geo_secondary']['db_port'] = 5431
default['gitlab']['geo_secondary']['db_socket'] = nil
default['gitlab']['geo_secondary']['db_sslmode'] = nil
default['gitlab']['geo_secondary']['db_sslcompression'] = 0
default['gitlab']['geo_secondary']['db_sslrootcert'] = nil
default['gitlab']['geo_secondary']['db_sslca'] = nil
default['gitlab']['geo_secondary']['db_prepared_statements'] = false
default['gitlab']['geo_secondary']['db_database_tasks'] = true

###
# Geo: PostgreSQL (Tracking database)
###

default['gitlab']['geo_postgresql'] = default['postgresql'].dup
# We are inheriting default attributes from postgresql and changing below what should be different
default['gitlab']['geo_postgresql']['enable'] = false
default['gitlab']['geo_postgresql']['dir'] = '/var/opt/gitlab/geo-postgresql'
default['gitlab']['geo_postgresql']['log_directory'] = '/var/log/gitlab/geo-postgresql'
default['gitlab']['geo_postgresql']['unix_socket_directory'] = nil
default['gitlab']['geo_postgresql']['ssl'] = 'off'
# Postgres User's Environment Path
default['gitlab']['geo_postgresql']['sql_user'] = 'gitlab_geo'
default['gitlab']['geo_postgresql']['sql_mattermost_user'] = nil
default['gitlab']['geo_postgresql']['port'] = 5431

# Mininum of 1/8 of total memory and Maximum of 1024MB as sane defaults
default['gitlab']['geo_postgresql']['shared_buffers'] = "#{[(node['memory']['total'].to_i / 8) / 1024, 1024].max}MB"

default['gitlab']['geo_postgresql']['work_mem'] = '16MB'
default['gitlab']['geo_postgresql']['maintenance_work_mem'] = '16MB'
default['gitlab']['geo_postgresql']['effective_cache_size'] = "#{[(node['memory']['total'].to_i / 8) / 1024, 2048].max}MB" # double of shared_buffers estimation
default['gitlab']['geo_postgresql']['log_min_duration_statement'] = -1 # Disable slow query logging by default
default['gitlab']['geo_postgresql']['min_wal_size'] = '80MB'
default['gitlab']['geo_postgresql']['max_wal_size'] = '1GB'
default['gitlab']['geo_postgresql']['checkpoint_timeout'] = '5min'
default['gitlab']['geo_postgresql']['checkpoint_completion_target'] = 0.9
default['gitlab']['geo_postgresql']['checkpoint_warning'] = '30s'
default['gitlab']['geo_postgresql']['wal_buffers'] = '-1'
default['gitlab']['geo_postgresql']['autovacuum'] = 'on'
default['gitlab']['geo_postgresql']['log_autovacuum_min_duration'] = '-1'
default['gitlab']['geo_postgresql']['autovacuum_max_workers'] = '3'
default['gitlab']['geo_postgresql']['autovacuum_naptime'] = '1min'
default['gitlab']['geo_postgresql']['autovacuum_vacuum_threshold'] = '50'
default['gitlab']['geo_postgresql']['autovacuum_analyze_threshold'] = '50'
default['gitlab']['geo_postgresql']['autovacuum_vacuum_scale_factor'] = '0.02' # 10x lower than PG defaults
default['gitlab']['geo_postgresql']['autovacuum_analyze_scale_factor'] = '0.01' # 10x lower than PG defaults
default['gitlab']['geo_postgresql']['autovacuum_freeze_max_age'] = '200000000'
default['gitlab']['geo_postgresql']['autovacuum_vacuum_cost_delay'] = '20ms'
default['gitlab']['geo_postgresql']['autovacuum_vacuum_cost_limit'] = '-1'
default['gitlab']['geo_postgresql']['statement_timeout'] = '60000'
default['gitlab']['geo_postgresql']['idle_in_transaction_session_timeout'] = '60000'
default['gitlab']['geo_postgresql']['log_line_prefix'] = nil
default['gitlab']['geo_postgresql']['track_activity_query_size'] = '1024'
default['gitlab']['geo_postgresql']['effective_io_concurrency'] = 1
default['gitlab']['geo_postgresql']['max_worker_processes'] = 8
default['gitlab']['geo_postgresql']['max_parallel_workers_per_gather'] = 0
default['gitlab']['geo_postgresql']['log_lock_waits'] = 1
default['gitlab']['geo_postgresql']['deadlock_timeout'] = '5s'
default['gitlab']['geo_postgresql']['track_io_timing'] = 'off'
default['gitlab']['geo_postgresql']['custom_pg_hba_entries'] = {}
default['gitlab']['geo_postgresql']['default_statistics_target'] = 1000

# Replication settings
default['gitlab']['geo_postgresql']['wal_level'] = 'minimal'
default['gitlab']['geo_postgresql']['wal_log_hints'] = 'off'
default['gitlab']['geo_postgresql']['max_wal_senders'] = 0
default['gitlab']['geo_postgresql']['wal_keep_segments'] = 10
default['gitlab']['geo_postgresql']['wal_keep_size'] = nil
default['gitlab']['geo_postgresql']['hot_standby'] = 'off'
default['gitlab']['geo_postgresql']['max_standby_archive_delay'] = '30s'
default['gitlab']['geo_postgresql']['max_standby_streaming_delay'] = '30s'
default['gitlab']['geo_postgresql']['max_replication_slots'] = 0
default['gitlab']['geo_postgresql']['synchronous_commit'] = 'on'
default['gitlab']['geo_postgresql']['synchronous_standby_names'] = ''
default['gitlab']['geo_postgresql']['hot_standby_feedback'] = 'off'

# Backup/Archive settings
default['gitlab']['geo_postgresql']['archive_mode'] = 'off'
default['gitlab']['geo_postgresql']['archive_command'] = nil
default['gitlab']['geo_postgresql']['archive_timeout'] = '0'

# pgbouncer settings
default['gitlab']['geo_postgresql']['pgbouncer_user'] = 'pgbouncer'
default['gitlab']['geo_postgresql']['pgbouncer_user_password'] = nil

# Automatically restart on version changes
default['gitlab']['geo_postgresql']['auto_restart_on_version_change'] = true

###
# Geo: LogCursor (replication)
###

default['gitlab']['geo_logcursor']['ha'] = false
default['gitlab']['geo_logcursor']['log_directory'] = '/var/log/gitlab/geo-logcursor'
default['gitlab']['geo_logcursor']['env_directory'] = '/opt/gitlab/etc/geo-logcursor/env'

default['gitlab']['suggested-reviewers'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['suggested_reviewers'].to_h }, "node['gitlab']['suggested-reviewers']", "node['gitlab']['suggested_reviewers']")
default['gitlab']['geo-secondary'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['geo_secondary'].to_h }, "node['gitlab']['geo-secondary']", "node['gitlab']['geo_secondary']")
default['gitlab']['geo-logcursor'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['geo_logcursor'].to_h }, "node['gitlab']['geo-logcursor']", "node['gitlab']['geo_logcursor']")
default['gitlab']['geo-postgresql'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['geo_postgresql'].to_h }, "node['gitlab']['geo-postgresql']", "node['gitlab']['geo_postgresql']")
