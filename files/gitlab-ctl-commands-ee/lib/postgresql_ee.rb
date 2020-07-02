require 'resolv'

module GitlabCtl
  class PostgreSQL
    def initialize(attributes)
      @attributes = attributes
    end

    def get_primary
      consul_enable = @attributes.dig('consul', 'enable')
      postgresql_service_name = @attributes.dig('consul', 'internal', 'postgresql_service_name')

      raise 'Consul agent is not enabled on this node' unless consul_enable

      raise 'PostgreSQL service name is not defined' if postgresql_service_name.nil? || postgresql_service_name.empty?

      Resolv::DNS.open(nameserver_port: [['127.0.0.1', 8600]]) do |dns|
        dns.getresources("#{postgresql_service_name}.service", Resolv::DNS::Resource::IN::SRV).map do |srv|
          "#{dns.getaddress(srv.target)}:#{srv.port}"
        end
      end
    end
  end
end
