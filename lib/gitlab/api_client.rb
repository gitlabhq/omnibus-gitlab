require_relative 'build/info/ci'
require_relative 'build/info/secrets'

require 'gitlab'

module Gitlab
  class APIClient
    def initialize(endpoint = Build::Info::CI.api_v4_url, token = Build::Info::Secrets.api_token)
      @client = ::Gitlab::Client.new(endpoint: endpoint, private_token: token)
    end
  end
end
