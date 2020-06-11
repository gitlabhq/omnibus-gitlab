default['consul']['services'] = []
default['consul']['service_config'] = nil

default['consul']['internal']['postgresql_service_name'] = 'postgresql'
default['consul']['internal']['postgresql_service_check_interval'] = '10s'
default['consul']['internal']['postgresql_service_check_status'] = 'failing'
default['consul']['internal']['postgresql_service_check_args_repmgr'] = ['/opt/gitlab/bin/gitlab-ctl', 'repmgr-check-master']
default['consul']['internal']['postgresql_service_check_args_patroni'] = ['/opt/gitlab/bin/gitlab-ctl', 'patroni', 'check-leader']
default['consul']['internal']['postgresql_watches_repmgr'] = [
  {
    'type': 'keyprefix',
    'prefix': 'gitlab/ha/postgresql/failed_masters/',
    'args': ['/opt/gitlab/bin/gitlab-ctl', 'consul', 'watchers', 'handle-failed-master']
  }
]
