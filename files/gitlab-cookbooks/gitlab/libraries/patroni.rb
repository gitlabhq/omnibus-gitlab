require 'socket'

module Patroni
  class << self
    def parse_variables
      return unless Services.enabled?('patroni')

      Gitlab['patroni']['connect_address'] ||= private_ipv4 || Gitlab['node']['ipaddress']
      Gitlab['patroni']['connect_port'] ||= Gitlab['patroni']['port'] || Gitlab['node']['patroni']['port']

      parse_postgresql_overrides
      auto_detect_wal_log_hint
    end

    def private_ipv4
      Socket.getifaddrs.select { |ifaddr| ifaddr.addr&.ipv4_private? }.first&.addr&.ip_address
    end

    private

    def postgresql_setting(key)
      Gitlab['postgresql'][key] || Gitlab['node']['postgresql'][key]
    end

    # These attributes are the postgres settings that patroni manages through its DCS,
    # but that we also have existing settings for in our postgresql defaults.
    # DCS only config settings are documented here: https://patroni.readthedocs.io/en/latest/dynamic_configuration.html
    # We will use the existing `postgresql[]` setting for patroni DCS, if a patroni specific
    # one hasn't been specified in gitlab.rb
    def parse_postgresql_overrides
      Gitlab['patroni']['postgresql'] ||= {}
      %w(max_connections max_locks_per_transaction max_worker_processes).each do |key|
        Gitlab['patroni']['postgresql'][key] ||= postgresql_setting(key)
      end
    end

    # `wal_log_hints` must be `on` for `pg_rewind`
    def auto_detect_wal_log_hint
      return if Gitlab['patroni']['postgresql']['wal_log_hints']

      Gitlab['patroni']['postgresql']['wal_log_hints'] = Gitlab['patroni']['use_pg_rewind'] ? 'on' : postgresql_setting('wal_log_hints')
    end
  end
end
