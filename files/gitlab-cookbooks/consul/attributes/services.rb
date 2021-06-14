default['consul']['services'] = []
default['consul']['service_config'] = nil

default['consul']['internal']['postgresql_service_name'] = 'postgresql'
default['consul']['internal']['postgresql_service_check_interval'] = '10s'
default['consul']['internal']['postgresql_service_check_status'] = 'failing'
default['consul']['internal']['postgresql_service_check_args_patroni'] = ['/opt/gitlab/bin/gitlab-ctl', 'patroni', 'check-leader']
default['consul']['internal']['postgresql_service_check_args_patroni_standby_cluster'] = ['/opt/gitlab/bin/gitlab-ctl', 'patroni', 'check-standby-leader']
