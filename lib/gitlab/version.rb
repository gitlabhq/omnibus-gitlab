require 'yaml'
require 'uri'

require_relative "util.rb"

module Gitlab
  class Version
    DEFAULT_SOURCE = 'remote'.freeze
    ALTERNATIVE_SOURCE = 'alternative'.freeze
    SECURITY_SOURCE = 'security'.freeze

    # Return which remote sources channel we are using
    #
    # Channels can be selected based on ENVIRONMENTAL variables
    # It defaults to "remote", which means internal "dev" instance.
    #
    # Security always takes precedence.
    #
    # @return [String]
    def self.sources_channel
      return SECURITY_SOURCE if Gitlab::Util.get_env("SECURITY_SOURCES").to_s == "true"

      fallback_sources_channel
    end

    # Return the fallback remote sources channel, which can be used when
    # no security remote alternative exists
    #
    # @return [String]
    def self.fallback_sources_channel
      Gitlab::Util.get_env("ALTERNATIVE_SOURCES").to_s == "true" ? ALTERNATIVE_SOURCE : DEFAULT_SOURCE
    end

    # Whether security sources channel is selected
    #
    # @return [Boolean] whether we are using security channel
    def self.security_channel?
      sources_channel == SECURITY_SOURCE
    end

    def self.alternative_channel?
      sources_channel == ALTERNATIVE_SOURCE
    end

    def initialize(software_name, version = nil)
      @software = software_name

      @read_version = version || get_software_version
      @project_root = File.join(File.dirname(__dir__), '../')
    end

    def get_software_version
      read_version_from_env || read_version_from_file
    end

    def read_version_from_env
      case @software
      when "gitlab-rails", "gitlab-rails-ee"
        Gitlab::Util.get_env("GITLAB_VERSION")
      when "gitlab-shell"
        Gitlab::Util.get_env("GITLAB_SHELL_VERSION")
      when "gitlab-workhorse"
        Gitlab::Util.get_env("GITLAB_WORKHORSE_VERSION")
      when "gitlab-pages"
        Gitlab::Util.get_env("GITLAB_PAGES_VERSION")
      when "gitaly"
        Gitlab::Util.get_env("GITALY_SERVER_VERSION")
      when "gitlab-elasticsearch-indexer"
        Gitlab::Util.get_env("GITLAB_ELASTICSEARCH_INDEXER_VERSION")
      end
    end

    def read_version_from_file
      path_to_version_file = components_files[@software]
      if path_to_version_file
        filepath = File.expand_path(path_to_version_file, @project_root)
        File.read(filepath).chomp
      else
        ""
      end
    rescue Errno::ENOENT
      # Didn't find the file
      @read_version = ""
    end

    def components_files
      {
        "gitlab-rails" => "VERSION",
        "gitlab-rails-ee" => "VERSION",
        "gitlab-shell" => "GITLAB_SHELL_VERSION",
        "gitlab-workhorse" => "GITLAB_WORKHORSE_VERSION",
        "gitlab-pages" => "GITLAB_PAGES_VERSION",
        "gitaly" => "GITALY_SERVER_VERSION",
        "gitlab-elasticsearch-indexer" => "GITLAB_ELASTICSEARCH_INDEXER_VERSION"
      }
    end

    def print(prepend_version = true)
      if @read_version.include?('.pre') || @read_version == "master"
        "master"
      elsif @read_version.empty?
        nil
      else
        # Check if it satisfies the following criteria
        # 1. One of our own components - has a VERSION file
        # 2. Not a valid version string following SemVer
        # If it satisfy both, it is probably a branch name or a SHA
        # commit of one of our own component so it doesn't need `v` prepended
        if components_files.key?(@software)
          return @read_version unless /^\d+\.\d+\.\d+(-rc\d+)?(-ee)?$/.match?(@read_version)
        end
        v = "v" if prepend_version
        [
          v,
          @read_version
        ].join
      end
    end

    def remote
      filepath = File.expand_path(".custom_sources.yml", @project_root)
      sources = YAML.load_file(filepath)[@software]

      return "" unless sources

      if ::Gitlab::Version.security_channel?
        attach_remote_credential(sources[::Gitlab::Version.sources_channel]) || sources[::Gitlab::Version.fallback_sources_channel]
      else
        sources[::Gitlab::Version.sources_channel]
      end
    end

    private

    def attach_remote_credential(url)
      return unless url

      uri = URI.parse(url)
      uri.user = "gitlab-ci-token"
      uri.password = Gitlab::Util.get_env("CI_JOB_TOKEN")
      uri.to_s
    rescue URI::InvalidURIError
      # Git may use scp address which is not valid URI. Ignore it
      url
    end
  end
end
