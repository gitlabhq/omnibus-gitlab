require 'cgi'
require_relative '../../../gitlab/libraries/redis_uri'

module NewRedisHelper
  class << self
    def build_redis_url(ssl:, host:, port:, path:, password:)
      scheme = ssl ? 'rediss:/' : 'redis:/'
      uri = URI(scheme)
      uri.host = host if host
      uri.port = port if port
      uri.path = path if path
      # In case the password has non-alphanumeric passwords, be sure to encode it
      uri.password = CGI.escape(password) if password

      uri
    end

    def build_sentinels_urls(sentinels:, password:)
      return [] if sentinels.nil? || sentinels.empty?

      sentinels.map do |sentinel|
        build_redis_url(
          ssl: sentinel['ssl'],
          host: sentinel['host'],
          port: sentinel['port'],
          path: '',
          password: password
        )
      end
    end
  end
end
