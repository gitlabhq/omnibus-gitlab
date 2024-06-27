require 'erb'
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
      uri.password = encode_redis_password(password) if password

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

    # RFC 3986 says that the userinfo value should be percent-encoded:
    # https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.1.
    # Note that CGI.escape and URI.encode_www_form_component encodes
    # a space as "+" instead of "%20". While this appears to be handled with
    # the Ruby client, the Go client doesn't work with "+".
    def encode_redis_password(password)
      ERB::Util.url_encode(password)
    end
  end
end
