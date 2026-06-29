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
      :user,
      :password,
      :host,
      :port,
      :path,
      :query
    ].freeze

    # Include this class as the handler for 'redis' and 'rediss' schemes
    # This allows URI('redis://') or URI('rediss://') to delegate to this class
    %w(REDIS REDISS).each do |scheme|
      # https://github.com/ruby/uri/pull/26 modified how schemes are registered.
      if Gem::Version.new(URI::VERSION) >= Gem::Version.new('0.11.0')
        ::URI.register_scheme scheme, Redis
      else
        @@schemes[scheme] = Redis
      end
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

    # Builds the authentication part of a Redis URL (RFC 3986) from the given
    # user and password components:
    # - user + password -> "user:password"
    # - password only   -> ":password"
    # - neither         -> nil (no @ divider rendered)
    #
    # A username without a password is not a valid Redis ACL configuration, so
    # it is treated as "no credentials" (returns nil).
    #
    # Callers are responsible for percent-encoding the components beforehand
    # (see RedisHelper.encode_redis_credential).
    def self.build_userinfo(user, password)
      if user && password
        "#{user}:#{password}"
      elsif password
        ":#{password}"
      end
    end

    # Outputs the authentication part of the URL. Delegates to .build_userinfo
    # so the rendering logic lives in a single place (also used by callers that
    # assign userinfo directly, such as the Unix socket path in base.rb).
    def userinfo
      self.class.build_userinfo(@user, @password)
    end

    protected

    # Override the stdlib setter so that assigning a user does not wipe an
    # already-set password. URI::Generic#set_user delegates to
    # set_userinfo(v, nil), which resets @password to nil. Because
    # build_redis_url sets the password before the username, we must preserve
    # @password here.
    #
    # An empty user is normalized to nil so that a parsed password-only URL
    # (e.g. "redis://:password@host", where the stdlib parser yields user "")
    # compares equal to a programmatically built URL that has no user (nil).
    # Without this, adding :user to CUSTOM_COMPONENT would break URI equality
    # comparisons that existing code relies on.
    def set_user(value)
      @user = normalize_user(value)
    end

    # Override the stdlib protected setter used during parsing
    # (URI.parse -> set_userinfo). It splits "user:password" and assigns both
    # components at once. We normalize an empty user to nil here so that a
    # parsed password-only URL is equivalent to a built one (see set_user).
    def set_userinfo(user, password = nil)
      user, password = split_userinfo(user) unless password
      @user     = normalize_user(user)
      @password = password

      [@user, @password]
    end

    # Override the stdlib setter so that assigning a password does not require
    # a user component to already be present (the stdlib check_password raises
    # "password component depends user component" otherwise). A Redis URL may
    # legitimately carry only a password (":password@host").
    def set_password(value)
      @password = value
    end

    def check_user(value)
      return true if value.nil? || value.empty?

      return true if parser.regexp[:USERINFO].match?(value)

      raise InvalidComponentError, "bad user component"
    end

    def check_password(value)
      return true if value.nil? || value.empty?

      # check the password component for RFC2396 compliance
      # and against the URI::Parser Regexp for :USERINFO
      return true if parser.regexp[:USERINFO].match?(value)

      raise InvalidComponentError, "bad password component"
    end

    private

    # Treat a nil or empty user component as "no user". This keeps a parsed
    # password-only URL ("redis://:pass@host", parsed as user "") equivalent
    # to a built one (user nil), which matters because :user is part of
    # CUSTOM_COMPONENT and therefore participates in URI equality.
    def normalize_user(value)
      value.nil? || value.empty? ? nil : value
    end
  end
end
