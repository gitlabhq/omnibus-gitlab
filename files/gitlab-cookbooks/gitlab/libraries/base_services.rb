class BaseServices
  SYSTEM_GROUP = 'system'.freeze
  DEFAULT_GROUP = 'default'.freeze
  SERVICE_CONFIG_TEMPLATE = { groups: [] }.freeze

  class << self
    def svc(config = {})
      SERVICE_CONFIG_TEMPLATE.dup.merge(config)
    end

    def service_list
      @service_list = [core_services.dup, *(other_services.dup.values)].inject(&:merge)
    end

    def include_services(cookbook, services)
      other_services[cookbook] = services
    end

    def reset_list
      @other_services = nil
    end

    private

    def core_services(value=nil)
      @core_services = value if value
      @core_services ||= {}
    end

    def other_services(value=nil)
      @other_services = value if value
      @other_services ||= {}
    end
  end
end unless defined?(BaseServices) # Prevent reloading during converge, so we can test
