require 'socket'

module Patroni
  class << self
    def parse_variables
      return unless Services.enabled?('patroni')

      Gitlab['patroni']['connect_address'] ||= private_ipv4 || Gitlab['node']['ipaddress']
      Gitlab['patroni']['connect_port'] ||= Gitlab['patroni']['port'] || Gitlab['node']['patroni']['port']
    end

    def private_ipv4
      Socket.getifaddrs.select { |ifaddr| ifaddr.addr.ipv4_private? }.first&.addr&.ip_address
    end
  end
end
