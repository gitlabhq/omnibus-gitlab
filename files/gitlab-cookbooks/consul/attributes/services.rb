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
    }
  }
}
