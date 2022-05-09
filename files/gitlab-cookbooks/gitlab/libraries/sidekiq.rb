require 'resolv'
require 'ipaddr'

module Sidekiq
  class << self
    def parse_variables
      check_listen_address
    end

    def check_listen_address
      default_config = Gitlab['node']['gitlab']['sidekiq']
      user_config = Gitlab['sidekiq']

      metrics_enabled = user_config['metrics_enabled'].nil? ? default_config['metrics_enabled'] : user_config['metrics_enabled']
      health_checks_enabled = user_config['health_checks_enabled'].nil? ? default_config['health_checks_enabled'] : user_config['health_checks_enabled']
      return unless metrics_enabled && health_checks_enabled

      listen_address = user_config['listen_address'] || default_config['listen_address']
      health_checks_address = user_config['health_checks_listen_address'] || default_config['health_checks_listen_address']
      listen_port = user_config['listen_port'] || default_config['listen_port']
      health_checks_port = user_config['health_checks_listen_port'] || default_config['health_checks_listen_address']

      return if listen_address.nil? || health_checks_address.nil?

      raise "The Sidekiq metrics and health checks servers are binding the same address and port. This is unsupported in GitLab 15.0 and newer. See https://docs.gitlab.com/ee/administration/sidekiq.html for up-to-date instructions." if same_address?(listen_address, health_checks_address) && listen_port == health_checks_port
    end

    private

    def same_address?(address1, address2)
      addr1 = IPAddr.new(Resolv.getaddress(address1))
      addr2 = IPAddr.new(Resolv.getaddress(address2))

      addr1.loopback? == addr2.loopback? || addr1 == addr2
    end
  end
end
