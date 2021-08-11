require 'chef/json_compat'
require 'chef/log'

require_relative '../config_mash'
require_relative 'logging_helper'

class GitlabClusterHelper
  CONFIG_PATH = '/etc/gitlab'.freeze
  JSON_FILE   = '/etc/gitlab/gitlab-cluster.json'.freeze

  def config
    return @config if defined?(@config)

    @config = Gitlab::ConfigMash.new(load_from_file)
  end

  #
  # Set the value of a config option in the JSON file. It overrides the key value if it already exists.
  #
  # Example:
  #
  #   GitlabClusterHelper.new.set('patroni', 'standby_cluster', 'enable', false)
  #   => {
  #     patroni: {
  #       standby_cluster: {
  #         enable: false
  #       }
  #     }
  #   }
  #
  def set(*args)
    auto_vivify(config, *args)
  end

  #
  # Get the value of a config option if the key exists in the JSON file. Otherwise, returns nil.
  #
  # Example:
  #
  #   GitlabClusterHelper.new.get('patroni', 'standby_cluster', 'enable')
  #   => true
  #
  def get(*args)
    config.dig(*args)
  end

  #
  # Merge an incoming setting with Gitlab config options if the key exists in the JSON file.
  #
  # Example:
  #
  #   GitlabClusterHelper.new.merge!('patroni', 'standby_cluster', 'enable')
  #   => true
  #
  def merge!(*args)
    value = get(*args)
    return if value.nil?

    log_overriding_message(args, value)
    auto_vivify(Gitlab, *args, value)
  end

  # Roles defined in the JSON file overrides roles from /etc/gitlab/gitlab.rb
  def load_roles!
    load_role!('geo_primary_role', 'primary')
    load_role!('geo_secondary_role', 'secondary')
  end

  # Write configuration to the local JSON file overriding current settings
  def write_to_file!
    return unless File.directory?(CONFIG_PATH)

    json_config = Chef::JSONCompat.to_json_pretty(config)

    File.open(JSON_FILE, 'w', 0600) do |f|
      f.puts(json_config)
      f.chmod(0600)
    end
  end

  private

  def auto_vivify(hash, *keys, value)
    Gitlab::ConfigMash.auto_vivify do
      if keys.length == 1
        hash[keys.first] = value
      else
        *keys, last = *keys
        keys.inject(hash, :[])[last] = value
      end
    end

    hash
  end

  # Load configuration from the local JSON file
  def load_from_file
    return {} unless File.exist?(JSON_FILE)

    Chef::JSONCompat.from_json(File.read(JSON_FILE))
  end

  def load_role!(role, key)
    value = get(key)
    return if value.nil?

    log_overriding_message(role, value)
    Gitlab[role]['enable'] = value
  end

  def log_overriding_message(keys, value)
    message = "The '#{Array(keys).join('.')}' is defined in #{JSON_FILE} as '#{value}' " \
              "and overrides the setting in the /etc/gitlab/gitlab.rb"

    LoggingHelper.warning(message)
  end
end
