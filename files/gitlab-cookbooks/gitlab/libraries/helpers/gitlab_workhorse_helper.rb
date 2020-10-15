require_relative 'base_helper'

class GitlabWorkhorseHelper < BaseHelper
  attr_reader :node

  def unix_socket?
    node['gitlab']['gitlab-workhorse']['listen_network'] == "unix"
  end
end
