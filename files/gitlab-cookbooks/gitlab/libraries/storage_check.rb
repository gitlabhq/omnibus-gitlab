module StorageCheck
  class << self
    def parse_variables
      parse_unicorn_socket
    end

    def parse_unicorn_socket
      unicorn_socket = Gitlab['unicorn']['socket'] || Gitlab['node']['gitlab']['unicorn']['socket']
      Gitlab['storage_check']['target'] ||= "unix://#{unicorn_socket}"
    end
  end
end
