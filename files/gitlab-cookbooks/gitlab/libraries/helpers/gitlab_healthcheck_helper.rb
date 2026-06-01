require_relative '../../../package/libraries/helpers/base_helper'

class GitlabHealthcheckHelper < BaseHelper
  attr_reader :node

  # A node qualifies as a "web node" when it serves the GitLab HTTP API
  # directly via nginx or via workhorse. Only web nodes get a rendered
  # healthcheck-rc file; the bash entrypoint exits 0 on other roles.
  def web_node?
    nginx_enabled? || workhorse_enabled?
  end

  # The URL the curl-based healthcheck should target. Each role check
  # returns its URL when matched; nil at the bottom catches any node we
  # don't yet know how to healthcheck. Add new role branches above the
  # trailing nil.
  def url
    return "#{schema}://#{host}#{relative_url}/help" if web_node?

    nil
  end

  # The flags array curl should be invoked with. Returns an empty array
  # on non-web nodes.
  def flags
    return nginx_enabled? ? nginx_flags : workhorse_flags if web_node?

    []
  end

  private

  def nginx_enabled?
    node['gitlab']['nginx']['enable']
  end

  def workhorse_enabled?
    node['gitlab']['gitlab_workhorse']['enable']
  end

  def workhorse_helper
    @workhorse_helper ||= GitlabWorkhorseHelper.new(node)
  end

  def schema
    return 'http' unless nginx_enabled?

    # Fallback to the setting derived from external_url when listen_https is unset
    listen_https = node['gitlab']['nginx']['listen_https']
    listen_https = node['gitlab']['gitlab_rails']['gitlab_https'] if listen_https.nil?
    listen_https ? 'https' : 'http'
  end

  def host
    if nginx_enabled?
      "localhost:#{node['gitlab']['nginx']['listen_port']}"
    elsif workhorse_helper.unix_socket?
      'localhost'
    else
      node['gitlab']['gitlab_workhorse']['listen_addr']
    end
  end

  def relative_url
    Gitlab['gitlab_rails']['gitlab_relative_url']
  end

  def nginx_flags
    flags = []
    allowed_hosts = node['gitlab']['gitlab_rails']['allowed_hosts']
    flags << "--header \"Host: #{allowed_hosts[0]}\"" unless allowed_hosts.empty?
    flags << '--haproxy-protocol' if node['gitlab']['nginx']['proxy_protocol']
    flags << '--insecure'
    flags
  end

  def workhorse_flags
    flags = []
    if workhorse_helper.unix_socket?
      flags << '--unix-socket'
      flags << node['gitlab']['gitlab_workhorse']['listen_addr']
    else
      flags << '--insecure'
    end
    flags
  end
end
