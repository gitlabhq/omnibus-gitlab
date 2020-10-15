require 'chef/json_compat'
require 'chef/log'
require_relative 'logging_helper'

class GitlabClusterHelper
  CONFIG_PATH = '/etc/gitlab'.freeze
  JSON_FILE   = '/etc/gitlab/gitlab-cluster.json'.freeze

  class << self
    def config_available?
      File.exist?(JSON_FILE)
    end
  end

  def config
    return @config if defined?(@config)

    @config = load_from_file
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

  # Load configuration from the local JSON file
  def load_from_file
    return {} unless self.class.config_available?

    Chef::JSONCompat.from_json(File.read(JSON_FILE))
  end

  def load_role!(role, key)
    return unless config.key?(key)

    print_warning(role, key) if Gitlab[role]['enable']
    Gitlab[role]['enable'] = config[key]
  end

  def print_warning(role, key)
    LoggingHelper.warning "The #{role} is defined in #{JSON_FILE} as #{key} and takes priority over the role in the /etc/gitlab/gitlab.rb"
  end
end
