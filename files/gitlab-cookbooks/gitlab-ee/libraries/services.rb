class EEServices < BaseServices
  core_services(
    'sentinel' =>         svc(groups: ['redis']),
    'sidekiq_cluster' =>  svc,
    'geo_postgresql' =>   svc,
    'pgbouncer' =>        svc,
  )
end
