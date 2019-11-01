default['consul']['services'] = []
default['consul']['service_config'] = {
  'postgresql' => {
    'service' => {
      'name' => "postgresql",
      'address' => '',
      'port' => 5432,
      'check' => {
        'id': 'service:postgresql',
        'args' => ['/opt/gitlab/bin/gitlab-ctl', 'repmgr-check-master'],
        'interval' => "10s",
        'status': 'failing'
      }
    },
    'watches': [
      {
        'type': 'keyprefix',
        'prefix': 'gitlab/ha/postgresql/failed_masters/',
        'args': ['/opt/gitlab/bin/gitlab-ctl', 'consul', 'watchers', 'handle-failed-master']
      }
    ]
  }
}
