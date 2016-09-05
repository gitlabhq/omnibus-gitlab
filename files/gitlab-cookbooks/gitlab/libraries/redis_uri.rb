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

    # Include this class as the handler for 'redis' scheme
    # This allows URI('redis://') to delegate to this class
    @@schemes['REDIS'] = Redis

    def self.build(args)
      super(Util::make_components_hash(self, args))
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
      value.nil? || !value.empty?
    end
  end
end
