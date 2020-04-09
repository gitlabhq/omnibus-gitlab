module Consul
  class << self
    def parse_variables
      Gitlab['consul']['username'] ||= Gitlab['consul']['user']
    end
  end
end
