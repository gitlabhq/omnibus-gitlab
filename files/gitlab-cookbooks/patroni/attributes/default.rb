default['patroni']['enable'] = false
default['patroni']['dir'] = '/var/opt/gitlab/patroni'

#
# Settings below are based on https://patroni.readthedocs.io/en/latest/SETTINGS.html#settings
#

# Patroni dynamic configuration settings
default['patroni']['loop_wait'] = 10
default['patroni']['ttl'] = 30
default['patroni']['retry_timeout'] = 10
default['patroni']['maximum_lag_on_failover'] = 1_048_576
default['patroni']['max_timelines_history'] = 0
default['patroni']['master_start_timeout'] = 300
default['patroni']['use_pg_rewind'] = true
default['patroni']['remove_data_directory_on_rewind_failure'] = false
default['patroni']['remove_data_directory_on_diverged_timelines'] = false
default['patroni']['use_slots'] = true
default['patroni']['replication_password'] = nil
default['patroni']['replication_slots'] = {}
default['patroni']['callbacks'] = {}
default['patroni']['recovery_conf'] = {}
default['patroni']['tags'] = {}

# Standby cluster replication settings
default['patroni']['standby_cluster']['enable'] = false
default['patroni']['standby_cluster']['host'] = nil
default['patroni']['standby_cluster']['port'] = 5432
default['patroni']['standby_cluster']['primary_slot_name'] = nil

# Global/Universal settings
default['patroni']['name'] = node.name
default['patroni']['scope'] = 'postgresql-ha'

# Log settings
default['patroni']['log_directory'] = '/var/log/gitlab/patroni'
default['patroni']['log_level'] = 'INFO'

# Consul specific settings
default['patroni']['consul']['url'] = 'http://127.0.0.1:8500'
default['patroni']['consul']['service_check_interval'] = '10s'
default['patroni']['consul']['register_service'] = true
default['patroni']['consul']['checks'] = []

# PostgreSQL configuration override
default['patroni']['postgresql']['wal_level'] = 'replica'
default['patroni']['postgresql']['hot_standby'] = 'on'
default['patroni']['postgresql']['wal_keep_segments'] = 10
default['patroni']['postgresql']['max_wal_senders'] = 5
default['patroni']['postgresql']['max_replication_slots'] = 5
default['patroni']['postgresql']['checkpoint_timeout'] = 30
default['patroni']['postgresql']['max_prepared_transactions'] = 0
default['patroni']['postgresql']['track_commit_timestamp'] = 'off'

# Rest API settings
default['patroni']['listen_address'] = nil
default['patroni']['connect_address'] = nil
default['patroni']['port'] = '8008'
default['patroni']['connect_port'] = nil
default['patroni']['username'] = nil
default['patroni']['password'] = nil
default['patroni']['allowlist'] = []
default['patroni']['allowlist_include_members'] = false
default['patroni']['tls_certificate_file'] = nil
default['patroni']['tls_key_file'] = nil
default['patroni']['tls_key_password'] = nil
default['patroni']['tls_ca_file'] = nil
default['patroni']['tls_ciphers'] = nil
default['patroni']['tls_client_mode'] = nil
default['patroni']['tls_client_certificate_file'] = nil
default['patroni']['tls_client_key_file'] = nil
default['patroni']['tls_verify'] = true
