require 'erb'
require_relative '../redis_uri'

module RedisHelper
  class << self
    def build_redis_url(ssl:, host:, port:, path:, password:, username: nil)
      scheme = ssl ? 'rediss:/' : 'redis:/'
      uri = URI(scheme)
      uri.host = host if host
      uri.port = port if port
      uri.path = path if path
      # In case the password has non-alphanumeric characters, be sure to encode it
      uri.password = encode_redis_credential(password) if password
      # In case the username has non-alphanumeric characters, be sure to encode it
      uri.user = encode_redis_credential(username) if username

      uri
    end

    def build_sentinels_urls(sentinels:, password:, ssl:)
      return [] if sentinels.nil? || sentinels.empty?

      sentinels.map do |sentinel|
        build_redis_url(
          ssl: ssl || sentinel['ssl'],
          host: sentinel['host'],
          port: sentinel['port'],
          path: '',
          password: password
          # No username: Sentinel authentication uses SentinelUsername in Go,
          # not the main Redis username. A dedicated Sentinel username
          # (redis_sentinels_username) is passed separately via the
          # SentinelUsername config field instead of the URL.
        )
      end
    end

    # RFC 3986 says that the userinfo value should be percent-encoded:
    # https://datatracker.ietf.org/doc/html/rfc3986#section-3.2.1.
    # Note that CGI.escape and URI.encode_www_form_component encodes
    # a space as "+" instead of "%20". While this appears to be handled with
    # the Ruby client, the Go client doesn't work with "+".
    # This method is used for both username and password encoding.
    def encode_redis_credential(credential)
      ERB::Util.url_encode(credential)
    end
  end
end
