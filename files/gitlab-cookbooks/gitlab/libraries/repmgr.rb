module Repmgr
  class << self
    def parse_variables
      Gitlab['repmgr']['username'] ||= Gitlab['repmgr']['user']
    end
  end
end
