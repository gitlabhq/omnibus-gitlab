# frozen_string_literal: true

require 'singleton'
require 'chef/json_compat'
require 'chef/log'

require_relative 'config_mash'
require_relative 'helpers/logging_helper'

# GitLab Cluster configuration abstraction
#
# This allows you to acces cluster-wide configuration
class GitlabCluster
  include Singleton

  CONFIG_PATH = '/etc/gitlab'
  JSON_FILE   = '/etc/gitlab/gitlab-cluster.json'

  # @return [GitlabCluster]
  def self.config
    instance
  end

  def self.log_overriding_message(keys, value)
    message = "The '#{Array(keys).join('.')}' is defined in #{GitlabCluster::JSON_FILE} as '#{value}' " \
              "and overrides the setting in the /etc/gitlab/gitlab.rb"

    LoggingHelper.warning(message)
  end

  # Set the value of a config option in the JSON file. It overrides the key value if it already exists.
  #
  # @example setting a new value for `patroni.standby_cluster.enable` key
  #    GitlabCluster.config.set('patroni', 'standby_cluster', 'enable', false)
  #    #=> {
  #    #  patroni: {
  #    #    standby_cluster: {
  #    #      enable: false
  #    #    }
  #    #  }
  #    #}
  #
  # @param [Array] args the nested keys sequence with the value as the last argument
  def set(*args)
    local_store.deep_set(*args)
  end

  # Get the value of a config option if the key exists in the local store. Otherwise, returns nil.
  #
  # @example retrieving value for `patroni.standby_cluster.enable` key
  #    GitlabCluster.config.get('patroni', 'standby_cluster', 'enable')
  #    #=> true
  #
  # @param [Array] args the nested keys sequence to fetch the stored value
  # @return [Object, nil]
  def get(*args)
    local_store.dig(*args)
  end

  # Roles defined in the JSON file overrides roles from /etc/gitlab/gitlab.rb
  def load_roles!
    Gitlab.override_role!('geo_primary_role', get('primary'))
    Gitlab.override_role!('geo_secondary_role', get('secondary'))
  end

  # Write configuration to the local store overwritting current settings
  #
  # @return [Boolean] whether it successfuly persisted the settings or not
  def save
    return false unless File.directory?(CONFIG_PATH)

    json_config = Chef::JSONCompat.to_json_pretty(local_store)

    File.open(JSON_FILE, 'w', 0600) do |f|
      f.puts(json_config)
      f.chmod(0600)
    end

    true
  end

  def all
    local_store.dup
  end

  # Clears local store cache so content is reloaded from disk
  def reload!
    @local_store = nil
  end

  private

  def local_store
    @local_store ||= Gitlab::ConfigMash.new(load_from_file)
  end

  # Load configuration from the local JSON file
  def load_from_file
    return {} unless File.exist?(JSON_FILE)

    Chef::JSONCompat.from_json(File.read(JSON_FILE))
  end
end
