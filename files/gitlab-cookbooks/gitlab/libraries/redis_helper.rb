require_relative 'redis_uri.rb'

class RedisHelper
  def initialize(node)
    @node = node
  end

  def redis_url
    if @node['gitlab']['redis']['unixsocket']
      uri = URI('unix:/')
      uri.path = @node['gitlab']['redis']['unixsocket']
    else
      uri = URI::Redis.parse('redis:/')
      uri.host = @node['gitlab']['gitlab_rails']['redis_host']
      uri.port = @node['gitlab']['gitlab_rails']['redis_port']
      uri.password = @node['gitlab']['gitlab_rails']['redis_password']
      uri.path = "/#{@node['gitlab']['gitlab_rails']['redis_database']}"
    end

    uri
  end
end
