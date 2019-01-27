require 'uri'

module URI
  # Extends stdlib URI to include 'Redis' as a valid scheme with the correct behaviour
  # The API is a little weird and doesn't follow our styleguide
  #
  # A snipet on how to create custom URIs can be found here:
  # https://github.com/ruby/ruby/blob/trunk/lib/uri.rb
  #
  # All the methods in this class overrides methods from:
  # https://github.com/ruby/ruby/blob/trunk/lib/uri/generic.rb
  class Redis < URI::Generic
    # Default port for Redis (when defined or empty will make URL not include it)
    DEFAULT_PORT ||= 6379

    # Components definition that are part of this URI type
    CUSTOM_COMPONENT ||= [
      :scheme,
      :password,
      :host,
      :port,
      :path,
      :query
    ].freeze

    # Include this class as the handler for 'redis' and 'rediss' schemes
    # This allows URI('redis://') or URI('rediss://') to delegate to this class
    %w(REDIS REDISS).each do |scheme|
      @@schemes[scheme] = Redis
    end

    def self.build(args)
      super(Util.make_components_hash(self, args))
    end

    # We are overriding this class to point to CUSTOM_COMPONENT instead of COMPONENT
    # to prevent CONSTANT modification warning.
    def self.component
      CUSTOM_COMPONENT
    end

    # Syntax suggar so we can call `URI::Redis.parse()` instead of just `URI()`
    def self.parse(value)
      URI.parse(value)
    end

    # Outputs the authentication part of the URL: `:password` followed by `@` divider
    # (added by the URL builder)
    def userinfo
      @password.nil? ? nil : ':' + @password
    end

    protected

    def check_password(value)
      return true if value.nil? || value.empty?

      # check the password component for RFC2396 compliance
      # and against the URI::Parser Regexp for :USERINFO
      return true if parser.regexp[:USERINFO].match?(value)

      raise InvalidComponentError, "bad password component"
    end
  end
end
