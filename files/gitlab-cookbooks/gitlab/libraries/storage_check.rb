module StorageCheck
  class << self
    def parse_variables
      parse_webserver_socket
    end

    def parse_webserver_socket
      service = WebServerHelper.service_name
      service_socket = Gitlab[service]['socket'] || Gitlab['node']['gitlab'][service]['socket']
      Gitlab['storage_check']['target'] ||= "unix://#{service_socket}"
    end
  end
end
