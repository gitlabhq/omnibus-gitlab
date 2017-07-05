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
  # We do this in a method instead of on file eval so that we can test in isolation
  # Our tests load all libraries from all cookbooks, and we would not be able to
  # discern the EE services from the Non EE
  def self.prepend_ee_services
    class << self
      prepend EEServices
    end
  end
end
