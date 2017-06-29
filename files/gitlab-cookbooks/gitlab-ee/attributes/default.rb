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
default['gitlab']['sidekiq-cluster']['queue_groups'] = []

###
# Geo: Secondary node configuration
###
default['gitlab']['geo-secondary']['auto_migrate'] = true
default['gitlab']['geo-secondary']['db_adapter'] = "postgresql"
default['gitlab']['geo-secondary']['db_encoding'] = "unicode"
default['gitlab']['geo-secondary']['db_collation'] = nil
default['gitlab']['geo-secondary']['db_database'] = "gitlabhq_geo_production"
default['gitlab']['geo-secondary']['db_pool'] = 10
default['gitlab']['geo-secondary']['db_username'] = "gitlab_geo"
default['gitlab']['geo-secondary']['db_password'] = nil
default['gitlab']['geo-secondary']['db_load_balancing'] = { 'hosts' => [] }
# Path to postgresql socket directory
default['gitlab']['geo-secondary']['db_host'] = "/var/opt/gitlab/geo-postgresql"
default['gitlab']['geo-secondary']['db_port'] = 5431
default['gitlab']['geo-secondary']['db_socket'] = nil
default['gitlab']['geo-secondary']['db_sslmode'] = nil
default['gitlab']['geo-secondary']['db_sslrootcert'] = nil
default['gitlab']['geo-secondary']['db_sslca'] = nil

###
# Geo: PostgreSQL (Tracking database)
###
default['gitlab']['geo-postgresql']['enable'] = false
default['gitlab']['geo-postgresql']['ha'] = false
default['gitlab']['geo-postgresql']['dir'] = '/var/opt/gitlab/geo-postgresql'
default['gitlab']['geo-postgresql']['data_dir'] = '/var/opt/gitlab/geo-postgresql/data'
default['gitlab']['geo-postgresql']['log_directory'] = '/var/log/gitlab/geo-postgresql'
default['gitlab']['geo-postgresql']['unix_socket_directory'] = '/var/opt/gitlab/geo-postgresql'
# Postgres User's Environment Path
# defaults to /opt/gitlab/embedded/bin:/opt/gitlab/bin/$PATH. The install-dir path is set at build time
default['gitlab']['geo-postgresql']['sql_user'] = 'gitlab_geo'
default['gitlab']['geo-postgresql']['port'] = 5431
# Postgres allow multi listen_address, comma-separated values.
# If used, first address from the list will be use for connection
default['gitlab']['geo-postgresql']['listen_address'] = nil
default['gitlab']['geo-postgresql']['max_connections'] = 200
default['gitlab']['geo-postgresql']['md5_auth_cidr_addresses'] = []
default['gitlab']['geo-postgresql']['trust_auth_cidr_addresses'] = []

# Mininum of 1/8 of total memory and Maximum of 1024MB as sane defaults
default['gitlab']['geo-postgresql']['shared_buffers'] = "#{[(node['memory']['total'].to_i / 8) / 1024, 1024].max}MB"

default['gitlab']['geo-postgresql']['work_mem'] = '8MB'
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
default['gitlab']['geo-postgresql']['statement_timeout'] = '0'
default['gitlab']['geo-postgresql']['log_line_prefix'] = nil
default['gitlab']['geo-postgresql']['track_activity_query_size'] = '1024'
default['gitlab']['geo-postgresql']['shared_preload_libraries'] = nil
default['gitlab']['geo-postgresql']['custom_pg_hba_entries'] = {}

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
default['gitlab']['geo-postgresql']['archive_timeout'] = '60'

####
# Pgbouncer
####

default['gitlab']['postgresql']['pgbouncer_user'] = 'pgbouncer'
default['gitlab']['postgresql']['pgbouncer_user_password'] = nil
default['gitlab']['pgbouncer']['enable'] = false
default['gitlab']['pgbouncer']['log_directory'] = '/var/log/gitlab/pgbouncer'
default['gitlab']['pgbouncer']['data_directory'] = '/var/opt/gitlab/pgbouncer'
default['gitlab']['pgbouncer']['listen_addr'] = '0.0.0.0'
default['gitlab']['pgbouncer']['listen_port'] = 6432
default['gitlab']['pgbouncer']['pool_mode'] = 'session'
default['gitlab']['pgbouncer']['server_reset_query'] = 'DISCARD ALL'
default['gitlab']['pgbouncer']['max_client_conn'] = 100
default['gitlab']['pgbouncer']['default_pool_size'] = 20
default['gitlab']['pgbouncer']['min_pool_size'] = 0
default['gitlab']['pgbouncer']['reserve_pool_size'] = 0
default['gitlab']['pgbouncer']['reserve_pool_timeout'] = '5.0'
default['gitlab']['pgbouncer']['server_round_robin'] = 0
default['gitlab']['pgbouncer']['log_connections'] = 0
default['gitlab']['pgbouncer']['server_idle_timeout'] = '600.0'
default['gitlab']['pgbouncer']['dns_max_ttl'] = '15.0'
default['gitlab']['pgbouncer']['dns_zone_check_period'] = 0
default['gitlab']['pgbouncer']['dns_nxdomain_ttl'] = '15.0'
default['gitlab']['pgbouncer']['admin_users'] = %w(gitlab-psql postgres pgbouncer)
default['gitlab']['pgbouncer']['stats_users'] = %w(gitlab-psql postgres pgbouncer)
default['gitlab']['pgbouncer']['ignore_startup_parameters'] = 'extra_float_digits'
default['gitlab']['pgbouncer']['databases'] = {
  gitlabhq_production: {
    host: '127.0.0.1',
    port: 5432,
    user: 'pgbouncer',
    # generate password with md5(password + username)
    password: nil
  }
}
default['gitlab']['pgbouncer']['auth_type'] = 'md5'
default['gitlab']['pgbouncer']['auth_hba_file'] = nil
default['gitlab']['pgbouncer']['auth_query'] = 'SELECT username, password FROM public.pg_shadow_lookup($1)'
