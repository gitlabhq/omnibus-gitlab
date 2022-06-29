require 'resolv'
require 'ipaddr'

module Sidekiq
  class << self
    include MetricsExporterHelper

    def parse_variables
      check_listen_address

      check_consistent_exporter_tls_settings('sidekiq')
    end

    def check_listen_address
      return unless metrics_enabled? && health_checks_enabled?

      listen_address = user_config_or_default('listen_address')
      listen_port = user_config_or_default('listen_port')
      health_checks_address = user_config_or_default('health_checks_listen_address')
      health_checks_port = user_config_or_default('health_checks_listen_port')

      return if listen_address.nil? || health_checks_address.nil?

      raise "The Sidekiq metrics and health checks servers are binding the same address and port. This is unsupported in GitLab 15.0 and newer. See https://docs.gitlab.com/ee/administration/sidekiq.html for up-to-date instructions." if same_address?(listen_address, health_checks_address) && listen_port == health_checks_port
    end

    private

    def default_config
      Gitlab['node']['gitlab']['sidekiq']
    end

    def user_config
      Gitlab['sidekiq']
    end

    def metrics_enabled?
      user_config_or_default('metrics_enabled')
    end

    def health_checks_enabled?
      user_config_or_default('health_checks_enabled')
    end

    def same_address?(address1, address2)
      addr1 = IPAddr.new(Resolv.getaddress(address1))
      addr2 = IPAddr.new(Resolv.getaddress(address2))

      addr1.loopback? == addr2.loopback? || addr1 == addr2
    end
  end
end
