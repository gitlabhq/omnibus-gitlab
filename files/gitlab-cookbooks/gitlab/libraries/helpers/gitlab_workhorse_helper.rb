require_relative 'base_helper'

class GitlabWorkhorseHelper < BaseHelper
  attr_reader :node

  def socket_file_name
    return unless unix_socket?

    file_path = node['gitlab']['gitlab-workhorse']['listen_addr']

    return File.basename(file_path) unless file_path.nil?

    'socket'
  end

  def sockets_directory
    return unless unix_socket?

    node['gitlab']['gitlab-workhorse']['sockets_directory']
  end

  def unix_socket?
    node['gitlab']['gitlab-workhorse']['listen_network'] == "unix"
  end

  def deprecated_socket
    '/var/opt/gitlab/gitlab-workhorse/socket'
  end

  def user_customized_socket?
    default_path = node.default['gitlab']['gitlab-workhorse']['listen_addr']
    configured_path = node['gitlab']['gitlab-workhorse']['listen_addr']

    default_path != configured_path
  end

  def user_customized_sockets_directory?
    default_directory = node.default['gitlab']['gitlab-workhorse']['sockets_directory']
    configured_directory = node['gitlab']['gitlab-workhorse']['sockets_directory']

    default_directory != configured_directory
  end

  def orphan_socket
    return deprecated_socket unless user_customized_socket?

    node['gitlab']['gitlab-workhorse']['listen_addr']
  end

  def orphan_socket?
    return false unless unix_socket?

    cleanup_needed = orphan_socket != listen_address

    File.exist?(orphan_socket) && cleanup_needed
  end

  def listen_address
    return node['gitlab']['gitlab-workhorse']['listen_addr'] unless unix_socket?

    selinux_socket = File.join(sockets_directory, socket_file_name)

    return selinux_socket if user_customized_sockets_directory?

    return node['gitlab']['gitlab-workhorse']['listen_addr'] if user_customized_socket?

    selinux_socket
  end
end
