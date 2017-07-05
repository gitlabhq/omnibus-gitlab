## Reopens the class from the GitLab cookbook
module EEServices
  def service_list
    @ee_service_list ||= super.merge(
      {
        'sentinel' =>         { groups: [] },
        'sidekiq-cluster' =>  { groups: [] },
        'geo-postgresql' =>   { groups: [] },
        'pgbouncer' =>        { groups: [] },
      }
    )
  end
end

## Reopens the Services Class from the GitLab cookbook and adds our EE services
class Services
  class << self
    prepend EEServices
  end
end
