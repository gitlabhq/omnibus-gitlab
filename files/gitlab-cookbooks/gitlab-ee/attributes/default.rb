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
default['gitlab']['sentinel']['quorum'] = 1
default['gitlab']['sentinel']['announce_ip'] = nil
default['gitlab']['sentinel']['announce_port'] = nil
default['gitlab']['sentinel']['down_after_milliseconds'] = 10000
default['gitlab']['sentinel']['failover_timeout'] = 60000
default['gitlab']['sentinel']['myid'] = nil

####
# Sidekiq Cluster
####
default['gitlab']['sidekiq-cluster']['enable'] = false
default['gitlab']['sidekiq-cluster']['ha'] = false
default['gitlab']['sidekiq-cluster']['log_directory'] = "/var/log/gitlab/sidekiq-cluster"
default['gitlab']['sidekiq-cluster']['interval'] = nil
default['gitlab']['sidekiq-cluster']['max_concurrency'] = nil
default['gitlab']['sidekiq-cluster']['min_concurrency'] = nil
default['gitlab']['sidekiq-cluster']['queue_groups'] = []
default['gitlab']['sidekiq-cluster']['negate'] = false
default['gitlab']['sidekiq-cluster']['experimental_queue_selector'] = false

###
# Geo: Common (primary or secondary) node configuration
###
default['gitlab']['gitlab-rails']['geo_node_name'] = nil
default['gitlab']['gitlab-rails']['geo_registry_replication_enabled'] = false
default['gitlab']['gitlab-rails']['geo_registry_replication_primary_api_url'] = nil

###
# Geo: Secondary node configuration
###
default['gitlab']['geo-secondary']['enable'] = false
default['gitlab']['geo-secondary']['auto_migrate'] = true
default['gitlab']['geo-secondary']['db_adapter'] = "postgresql"
default['gitlab']['geo-secondary']['db_encoding'] = "unicode"
default['gitlab']['geo-secondary']['db_collation'] = nil
default['gitlab']['geo-secondary']['db_database'] = "gitlabhq_geo_production"
default['gitlab']['geo-secondary']['db_pool'] = 1
default['gitlab']['geo-secondary']['db_username'] = "gitlab_geo"
default['gitlab']['geo-secondary']['db_password'] = nil
default['gitlab']['geo-secondary']['db_load_balancing'] = { 'hosts' => [] }
# Path to postgresql socket directory
default['gitlab']['geo-secondary']['db_host'] = "/var/opt/gitlab/geo-postgresql"
default['gitlab']['geo-secondary']['db_port'] = 5431
default['gitlab']['geo-secondary']['db_socket'] = nil
default['gitlab']['geo-secondary']['db_sslmode'] = nil
default['gitlab']['geo-secondary']['db_sslcompression'] = 0
default['gitlab']['geo-secondary']['db_sslrootcert'] = nil
default['gitlab']['geo-secondary']['db_sslca'] = nil
default['gitlab']['geo-secondary']['db_fdw'] = true

###
# Geo: PostgreSQL (Tracking database)
###

default['gitlab']['geo-postgresql'] = default['postgresql'].dup
# We are inheriting default attributes from postgresql and changing below what should be different
default['gitlab']['geo-postgresql']['enable'] = false
default['gitlab']['geo-postgresql']['dir'] = '/var/opt/gitlab/geo-postgresql'
default['gitlab']['geo-postgresql']['data_dir'] = nil
default['gitlab']['geo-postgresql']['log_directory'] = '/var/log/gitlab/geo-postgresql'
default['gitlab']['geo-postgresql']['unix_socket_directory'] = nil
default['gitlab']['geo-postgresql']['ssl'] = 'off'
# Postgres User's Environment Path
default['gitlab']['geo-postgresql']['sql_user'] = 'gitlab_geo'
default['gitlab']['geo-postgresql']['sql_mattermost_user'] = nil
default['gitlab']['geo-postgresql']['port'] = 5431
# PostgreSQL Foreign Data Wrapper (FDW)
# The following is needed to make FDW work with pgbouncer. You need
# a separate login for the FDW connection to prevent schema path issues.
default['gitlab']['geo-postgresql']['fdw_external_user'] = default['gitlab']['gitlab-rails']['db_username']
default['gitlab']['geo-postgresql']['fdw_external_password'] = default['gitlab']['gitlab-rails']['db_password']

# Mininum of 1/8 of total memory and Maximum of 1024MB as sane defaults
default['gitlab']['geo-postgresql']['shared_buffers'] = "#{[(node['memory']['total'].to_i / 8) / 1024, 1024].max}MB"

default['gitlab']['geo-postgresql']['work_mem'] = '16MB'
default['gitlab']['geo-postgresql']['maintenance_work_mem'] = '16MB'
default['gitlab']['geo-postgresql']['effective_cache_size'] = "#{[(node['memory']['total'].to_i / 8) / 1024, 2048].max}MB" # double of shared_buffers estimation
default['gitlab']['geo-postgresql']['log_min_duration_statement'] = -1 # Disable slow query logging by default
default['gitlab']['geo-postgresql']['checkpoint_segments'] = 10
default['gitlab']['geo-postgresql']['min_wal_size'] = '80MB'
default['gitlab']['geo-postgresql']['max_wal_size'] = '1GB'
default['gitlab']['geo-postgresql']['checkpoint_timeout'] = '5min'
default['gitlab']['geo-postgresql']['checkpoint_completion_target'] = 0.9
default['gitlab']['geo-postgresql']['checkpoint_warning'] = '30s'
default['gitlab']['geo-postgresql']['wal_buffers'] = '-1'
default['gitlab']['geo-postgresql']['autovacuum'] = 'on'
default['gitlab']['geo-postgresql']['log_autovacuum_min_duration'] = '-1'
default['gitlab']['geo-postgresql']['autovacuum_max_workers'] = '3'
default['gitlab']['geo-postgresql']['autovacuum_naptime'] = '1min'
default['gitlab']['geo-postgresql']['autovacuum_vacuum_threshold'] = '50'
default['gitlab']['geo-postgresql']['autovacuum_analyze_threshold'] = '50'
default['gitlab']['geo-postgresql']['autovacuum_vacuum_scale_factor'] = '0.02' # 10x lower than PG defaults
default['gitlab']['geo-postgresql']['autovacuum_analyze_scale_factor'] = '0.01' # 10x lower than PG defaults
default['gitlab']['geo-postgresql']['autovacuum_freeze_max_age'] = '200000000'
default['gitlab']['geo-postgresql']['autovacuum_vacuum_cost_delay'] = '20ms'
default['gitlab']['geo-postgresql']['autovacuum_vacuum_cost_limit'] = '-1'
default['gitlab']['geo-postgresql']['statement_timeout'] = '60000'
default['gitlab']['geo-postgresql']['idle_in_transaction_session_timeout'] = '60000'
default['gitlab']['geo-postgresql']['log_line_prefix'] = nil
default['gitlab']['geo-postgresql']['track_activity_query_size'] = '1024'
default['gitlab']['geo-postgresql']['effective_io_concurrency'] = 1
default['gitlab']['geo-postgresql']['max_worker_processes'] = 8
default['gitlab']['geo-postgresql']['max_parallel_workers_per_gather'] = 0
default['gitlab']['geo-postgresql']['log_lock_waits'] = 1
default['gitlab']['geo-postgresql']['deadlock_timeout'] = '5s'
default['gitlab']['geo-postgresql']['track_io_timing'] = 'off'
default['gitlab']['geo-postgresql']['custom_pg_hba_entries'] = {}
default['gitlab']['geo-postgresql']['default_statistics_target'] = 1000

# Replication settings
default['gitlab']['geo-postgresql']['wal_level'] = 'minimal'
default['gitlab']['geo-postgresql']['max_wal_senders'] = 0
default['gitlab']['geo-postgresql']['wal_keep_segments'] = 10
default['gitlab']['geo-postgresql']['hot_standby'] = 'off'
default['gitlab']['geo-postgresql']['max_standby_archive_delay'] = '30s'
default['gitlab']['geo-postgresql']['max_standby_streaming_delay'] = '30s'
default['gitlab']['geo-postgresql']['max_replication_slots'] = 0
default['gitlab']['geo-postgresql']['synchronous_commit'] = 'on'
default['gitlab']['geo-postgresql']['synchronous_standby_names'] = ''
default['gitlab']['geo-postgresql']['hot_standby_feedback'] = 'off'

# Backup/Archive settings
default['gitlab']['geo-postgresql']['archive_mode'] = 'off'
default['gitlab']['geo-postgresql']['archive_command'] = nil
default['gitlab']['geo-postgresql']['archive_timeout'] = '0'

# pgbouncer settings
default['gitlab']['geo-postgresql']['pgbouncer_user'] = 'pgbouncer'
default['gitlab']['geo-postgresql']['pgbouncer_user_password'] = nil

###
# Geo: LogCursor (replication)
###

default['gitlab']['geo-logcursor']['ha'] = false
default['gitlab']['geo-logcursor']['log_directory'] = '/var/log/gitlab/geo-logcursor'
default['gitlab']['geo-logcursor']['env_directory'] = '/opt/gitlab/etc/geo-logcursor/env'

####
# Pgbouncer
####

default['postgresql']['pgbouncer_user'] = 'pgbouncer'
default['postgresql']['pgbouncer_user_password'] = nil
default['gitlab']['pgbouncer']['env_directory'] = '/opt/gitlab/etc/pgbouncer/env'
default['gitlab']['pgbouncer']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['gitlab']['pgbouncer']['enable'] = false
default['gitlab']['pgbouncer']['log_directory'] = '/var/log/gitlab/pgbouncer'
default['gitlab']['pgbouncer']['data_directory'] = '/var/opt/gitlab/pgbouncer'
default['gitlab']['pgbouncer']['listen_addr'] = '0.0.0.0'
default['gitlab']['pgbouncer']['listen_port'] = 6432
default['gitlab']['pgbouncer']['pool_mode'] = 'transaction'
default['gitlab']['pgbouncer']['server_reset_query'] = 'DISCARD ALL'
default['gitlab']['pgbouncer']['max_client_conn'] = 2048
default['gitlab']['pgbouncer']['application_name_add_host'] = 1
default['gitlab']['pgbouncer']['default_pool_size'] = 100
default['gitlab']['pgbouncer']['min_pool_size'] = 0
default['gitlab']['pgbouncer']['reserve_pool_size'] = 5
default['gitlab']['pgbouncer']['reserve_pool_timeout'] = '5.0'
default['gitlab']['pgbouncer']['server_round_robin'] = 0
default['gitlab']['pgbouncer']['log_connections'] = 0
default['gitlab']['pgbouncer']['server_idle_timeout'] = '30.0'
default['gitlab']['pgbouncer']['dns_max_ttl'] = '15.0'
default['gitlab']['pgbouncer']['dns_zone_check_period'] = 0
default['gitlab']['pgbouncer']['dns_nxdomain_ttl'] = '15.0'
default['gitlab']['pgbouncer']['admin_users'] = %w(gitlab-psql postgres pgbouncer)
default['gitlab']['pgbouncer']['stats_users'] = %w(gitlab-psql postgres pgbouncer)
default['gitlab']['pgbouncer']['ignore_startup_parameters'] = 'extra_float_digits'
default['gitlab']['pgbouncer']['databases_ini'] = '/var/opt/gitlab/pgbouncer/databases.ini'
default['gitlab']['pgbouncer']['databases_ini_user'] = 'root'
default['gitlab']['pgbouncer']['databases_json'] = '/var/opt/gitlab/pgbouncer/databases.json'
default['gitlab']['pgbouncer']['databases'] = {}
default['gitlab']['pgbouncer']['logfile'] = nil
default['gitlab']['pgbouncer']['unix_socket_dir'] = nil
default['gitlab']['pgbouncer']['unix_socket_mode'] = '0777'
default['gitlab']['pgbouncer']['unix_socket_group'] = nil

default['gitlab']['pgbouncer']['client_tls_sslmode'] = 'disable'
default['gitlab']['pgbouncer']['client_tls_ca_file'] = nil
default['gitlab']['pgbouncer']['client_tls_key_file'] = nil
default['gitlab']['pgbouncer']['client_tls_cert_file'] = nil
default['gitlab']['pgbouncer']['client_tls_protocols'] = 'all'
default['gitlab']['pgbouncer']['client_tls_dheparams'] = 'auto'
default['gitlab']['pgbouncer']['client_tls_ecdhcurve'] = 'auto'
default['gitlab']['pgbouncer']['server_tls_sslmode'] = 'disable'
default['gitlab']['pgbouncer']['server_tls_ca_file'] = nil
default['gitlab']['pgbouncer']['server_tls_key_file'] = nil
default['gitlab']['pgbouncer']['server_tls_cert_file'] = nil
default['gitlab']['pgbouncer']['server_tls_protocols'] = 'all'
default['gitlab']['pgbouncer']['server_tls_ciphers'] = 'fast'
default['gitlab']['pgbouncer']['server_reset_query_always'] = 0
default['gitlab']['pgbouncer']['server_check_query'] = 'select 1'
default['gitlab']['pgbouncer']['server_check_delay'] = 30
default['gitlab']['pgbouncer']['max_db_connections'] = nil
default['gitlab']['pgbouncer']['max_user_connections'] = nil
default['gitlab']['pgbouncer']['syslog'] = 0
default['gitlab']['pgbouncer']['syslog_facility'] = 'daemon'
default['gitlab']['pgbouncer']['syslog_ident'] = 'pgbouncer'
default['gitlab']['pgbouncer']['log_disconnections'] = 1
default['gitlab']['pgbouncer']['log_pooler_errors'] = 1
default['gitlab']['pgbouncer']['stats_period'] = 60
default['gitlab']['pgbouncer']['verbose'] = 0
default['gitlab']['pgbouncer']['server_lifetime'] = 3600
default['gitlab']['pgbouncer']['server_connect_timeout'] = 15
default['gitlab']['pgbouncer']['server_login_retry'] = 15
default['gitlab']['pgbouncer']['query_timeout'] = 0
default['gitlab']['pgbouncer']['query_wait_timeout'] = 120
default['gitlab']['pgbouncer']['client_idle_timeout'] = 0
default['gitlab']['pgbouncer']['client_login_timeout'] = 60
default['gitlab']['pgbouncer']['autodb_idle_timeout'] = 3600
default['gitlab']['pgbouncer']['suspend_timeout'] = 10
default['gitlab']['pgbouncer']['idle_transaction_timeout'] = 0
default['gitlab']['pgbouncer']['pkt_buf'] = 4096
default['gitlab']['pgbouncer']['listen_backlog'] = 128
default['gitlab']['pgbouncer']['sbuf_loopcnt'] = 5
default['gitlab']['pgbouncer']['max_packet_size'] = 2147483647
default['gitlab']['pgbouncer']['tcp_defer_accept'] = 0
default['gitlab']['pgbouncer']['tcp_socket_buffer'] = 0
default['gitlab']['pgbouncer']['tcp_keepalive'] = 1
default['gitlab']['pgbouncer']['tcp_keepcnt'] = 0
default['gitlab']['pgbouncer']['tcp_keepidle'] = 0
default['gitlab']['pgbouncer']['tcp_keepintvl'] = 0
default['gitlab']['pgbouncer']['disable_pqexec'] = 0

default['gitlab']['pgbouncer']['auth_type'] = 'md5'
default['gitlab']['pgbouncer']['auth_hba_file'] = nil
default['gitlab']['pgbouncer']['auth_query'] = 'SELECT username, password FROM public.pg_shadow_lookup($1)'
default['gitlab']['pgbouncer']['users'] = {}

####
# PgBouncer exporter
###
default['gitlab']['pgbouncer-exporter']['enable'] = false
default['gitlab']['pgbouncer-exporter']['log_directory'] = "/var/log/gitlab/pgbouncer-exporter"
default['gitlab']['pgbouncer-exporter']['listen_address'] = 'localhost:9188'
default['gitlab']['pgbouncer-exporter']['env_directory'] = '/opt/gitlab/etc/pgbouncer-exporter/env'
default['gitlab']['pgbouncer-exporter']['env'] = {
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
