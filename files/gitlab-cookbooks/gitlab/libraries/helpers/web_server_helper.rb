class WebServerHelper
  class << self
    def enabled?
      Services.enabled?('puma') || Services.enabled?('unicorn')
    end

    def service_name
      # We are defaulting to Puma here if unicorn isn't explicitly enabled
      if Services.enabled?('unicorn')
        'unicorn'
      else
        'puma'
      end
    end
  end
end
