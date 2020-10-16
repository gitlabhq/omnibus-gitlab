default['patroni']['enable'] = false
default['patroni']['dir'] = '/var/opt/gitlab/patroni'
default['patroni']['data_dir'] = '/var/opt/gitlab/patroni/data'

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
default['patroni']['use_pg_rewind'] = false
default['patroni']['use_slots'] = true
default['patroni']['replication_password'] = nil
default['patroni']['replication_slots'] = {}

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

# PostgreSQL specific settings
default['patroni']['postgresql']['wal_level'] = 'replica'
default['patroni']['postgresql']['hot_standby'] = 'on'
default['patroni']['postgresql']['wal_keep_segments'] = 8
default['patroni']['postgresql']['max_wal_senders'] = 5
default['patroni']['postgresql']['max_replication_slots'] = 5
default['patroni']['postgresql']['checkpoint_timeout'] = 30

# Rest API settings
default['patroni']['listen_address'] = nil
default['patroni']['connect_address'] = nil
default['patroni']['port'] = '8008'
default['patroni']['connect_port'] = nil
