require_relative 'redis_uri.rb'

class RedisHelper
  def initialize(node)
    @node = node
  end

  def redis_url
    gitlab_rails = @node['gitlab']['gitlab-rails']

    if gitlab_rails['redis_socket']
      uri = URI('unix:/')
      uri.path = gitlab_rails['redis_socket']
    else
      uri = URI::Redis.parse('redis:/')
      uri.host = gitlab_rails['redis_host']
      uri.port = gitlab_rails['redis_port']
      uri.password = gitlab_rails['redis_password']
      uri.path = "/#{gitlab_rails['redis_database']}"
    end

    uri
  end
end
