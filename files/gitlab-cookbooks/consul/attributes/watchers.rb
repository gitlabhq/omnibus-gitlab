default['consul']['watchers'] = []
default['consul']['watcher_config'] = {
  'postgresql' => {
    'handler' => 'failover_pgbouncer'
  }
}
