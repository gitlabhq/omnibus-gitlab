require_relative 'base_helper'

class GitlabWorkhorseHelper < BaseHelper
  attr_reader :node

  def sockets_directory
    return unless unix_socket?

    node['gitlab']['gitlab-workhorse']['sockets_directory']
  end

  def unix_socket?
    node['gitlab']['gitlab-workhorse']['listen_network'] == "unix"
  end

  def user_customized_socket?
    default_path = node.default['gitlab']['gitlab-workhorse']['listen_addr']
    configured_path = node['gitlab']['gitlab-workhorse']['listen_addr']

    default_path != configured_path
  end
end
