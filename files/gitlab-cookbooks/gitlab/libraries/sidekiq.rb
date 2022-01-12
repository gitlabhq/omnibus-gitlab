module Sidekiq
  class << self
    def parse_variables
      check_listen_address
    end

    def check_listen_address
      # TODO: In %15.0 we want to change this deprecation log to raise an error instead
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/350148

      default_config = Gitlab['node']['gitlab']['sidekiq']
      user_config = Gitlab['sidekiq']

      listen_address = user_config['listen_address'] || default_config['listen_address']
      health_checks_address = user_config['health_checks_listen_address'] || default_config['health_checks_listen_address']
      listen_port = user_config['listen_port'] || default_config['listen_port']
      health_checks_port = user_config['health_checks_listen_port'] || default_config['health_checks_listen_address']

      return if listen_address.nil? || health_checks_address.nil?

      LoggingHelper.deprecation("Sidekiq exporter and health checks are set to the same address and port. This is deprecated and will result in an error in version 15.0. See https://docs.gitlab.com/ee/administration/sidekiq.html") if listen_address == health_checks_address && listen_port == health_checks_port
    end
  end
end
