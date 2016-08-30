require 'uri'

module URI
  class Redis < URI::Generic
    DEFAULT_PORT ||= 6379
    CUSTOM_COMPONENT ||= [
      :scheme,
      :password,
      :host,
      :port,
      :path,
      :query
    ].freeze

    @@schemes['REDIS'] = Redis

    def self.build(args)
      super(Util::make_components_hash(self, args))
    end

    def self.component
      CUSTOM_COMPONENT
    end

    def userinfo
      @password.nil? ? nil : ':' + @password
    end

    protected

     def check_password(value)
      value.nil? || !value.empty?
    end
  end
end
