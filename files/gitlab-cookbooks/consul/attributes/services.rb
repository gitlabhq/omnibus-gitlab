default['consul']['services'] = []
default['consul']['service_config'] = {
  'postgresql' => {
    'service' => {
      'name' => "postgresql",
      'address' => '',
      'port' => 5432,
      'checks' => [
        {
          'script' => '/opt/gitlab/bin/gitlab-ctl repmgr-check-master',
          'interval' => "10s"
        }
      ]
    },
    'watches': [
      {
        'type': 'keyprefix',
        'prefix': 'gitlab/ha/postgresql/failed_masters/',
        'handler': '/opt/gitlab/bin/gitlab-ctl consul watchers handle-failed-master'
      }
    ]
  }
}
