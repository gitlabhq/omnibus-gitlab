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

  def socket_file_path
    return File.join(sockets_directory, socket_file_name) if unix_socket?

    node['gitlab']['gitlab-workhorse']['listen_addr']
  end
end
