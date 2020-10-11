require_relative 'base_helper'

class GitlabWorkhorseHelper < BaseHelper
  attr_reader :node

  def socket_file_name
    return unless unix_socket?

    File.basename(node['gitlab']['gitlab-workhorse']['listen_addr'])
  end

  def sockets_directory
    return unless unix_socket?

    path = File.dirname(node['gitlab']['gitlab-workhorse']['listen_addr'])
    return path if File.basename(path) == 'sockets'

    File.join(path, 'sockets')
  end

  def unix_socket?
    node['gitlab']['gitlab-workhorse']['listen_network'] == "unix"
  end

  def deprecated_socket
    '/var/opt/gitlab/gitlab-workhorse/socket'
  end

  def orphan_socket
    default_path = node.default['gitlab']['gitlab-workhorse']['listen_addr']
    configured_path = node['gitlab']['gitlab-workhorse']['listen_addr']

    return deprecated_socket if default_path == configured_path

    configured_path
  end

  def orphan_socket?
    return false unless unix_socket?

    cleanup_needed = orphan_socket != listen_address

    File.exist?(orphan_socket) && cleanup_needed
  end

  def listen_address
    return File.join(sockets_directory, socket_file_name) if unix_socket?

    node['gitlab']['gitlab-workhorse']['listen_addr']
  end
end
