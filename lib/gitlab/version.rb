require 'yaml'
require 'uri'

require_relative "util.rb"

module Gitlab
  class Version
    DEFAULT_SOURCE = 'remote'.freeze
    ALTERNATIVE_SOURCE = 'alternative'.freeze
    SECURITY_SOURCE = 'security'.freeze

    CUSTOM_SOURCES_FILENAME = '.custom_sources.yml'.freeze

    COMPONENTS_ENV_VARS = {
      'gitlab-rails' => 'GITLAB_VERSION',
      'gitlab-rails-ee' => 'GITLAB_VERSION',
      'gitlab-shell' => 'GITLAB_SHELL_VERSION',
      'gitlab-pages' => 'GITLAB_PAGES_VERSION',
      'gitaly' => 'GITALY_SERVER_VERSION',
      'gitlab-elasticsearch-indexer' => 'GITLAB_ELASTICSEARCH_INDEXER_VERSION',
      'gitlab-kas' => 'GITLAB_KAS_VERSION',
    }.freeze

    COMPONENTS_FILES = {
      "gitlab-rails" => "VERSION",
      "gitlab-rails-ee" => "VERSION",
      "gitlab-shell" => "GITLAB_SHELL_VERSION",
      "gitlab-pages" => "GITLAB_PAGES_VERSION",
      "gitaly" => "GITALY_SERVER_VERSION",
      "gitlab-elasticsearch-indexer" => "GITLAB_ELASTICSEARCH_INDEXER_VERSION",
      "gitlab-kas" => "GITLAB_KAS_VERSION",
      "omnibus" => "OMNIBUS_GEM_VERSION"
    }.freeze

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
      Gitlab::Util.get_env("ALTERNATIVE_SOURCES").to_s == "false" ? DEFAULT_SOURCE : ALTERNATIVE_SOURCE
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
      Gitlab::Util.get_env(COMPONENTS_ENV_VARS[@software]) if COMPONENTS_ENV_VARS.include?(@software)
    end

    def read_version_from_file
      path_to_build_facts_file = "build_facts/#{@software}_version"
      path_to_version_file = COMPONENTS_FILES[@software]

      if File.exist?(path_to_build_facts_file)
        File.read(path_to_build_facts_file).chomp
      elsif path_to_version_file
        filepath = File.expand_path(path_to_version_file, @project_root)
        File.read(filepath).chomp
      else
        ""
      end
    rescue Errno::ENOENT
      # Didn't find the file
      @read_version = ""
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
        if COMPONENTS_FILES.key?(@software)
          return @read_version unless /^\d+\.\d+\.\d+(-rc\d+)?(-ee)?$/.match?(@read_version)
        end
        v = "v" if prepend_version
        [
          v,
          @read_version
        ].join
      end
    end

    def read_remote_from_env
      remote = case @software
               when "gitlab-rails", "gitlab-rails-ee"
                 Gitlab::Util.get_env("GITLAB_ALTERNATIVE_REPO")
               when "gitlab-shell"
                 Gitlab::Util.get_env("GITLAB_SHELL_ALTERNATIVE_REPO")
               when "gitlab-pages"
                 Gitlab::Util.get_env("GITLAB_PAGES_ALTERNATIVE_REPO")
               when "gitaly"
                 Gitlab::Util.get_env("GITALY_SERVER_ALTERNATIVE_REPO")
               when "gitlab-elasticsearch-indexer"
                 Gitlab::Util.get_env("GITLAB_ELASTICSEARCH_INDEXER_ALTERNATIVE_REPO")
               when "gitlab-kas"
                 Gitlab::Util.get_env("GITLAB_KAS_ALTERNATIVE_REPO")
               end

      if remote && Gitlab::Util.get_env("ALTERNATIVE_PRIVATE_TOKEN")
        attach_remote_credential(remote, Gitlab::Util.get_env("ALTERNATIVE_PRIVATE_TOKEN"))
      else
        remote
      end
    end

    def read_remote_from_file(channel = nil)
      filepath = File.expand_path(CUSTOM_SOURCES_FILENAME, @project_root)
      sources = YAML.load_file(filepath)[@software]
      channel ||= ::Gitlab::Version.sources_channel

      return "" unless sources

      if channel == SECURITY_SOURCE
        attach_remote_credential(sources[channel], Gitlab::Util.get_env("CI_JOB_TOKEN")) || sources[::Gitlab::Version.fallback_sources_channel]
      else
        sources[channel]
      end
    end

    def remote(channel = nil)
      read_remote_from_env || read_remote_from_file(channel) || ""
    end

    private

    def attach_remote_credential(url, token)
      return unless url

      uri = URI.parse(url)
      uri.user = "gitlab-ci-token"
      uri.password = token
      uri.to_s
    rescue URI::InvalidURIError
      # Git may use scp address which is not valid URI. Ignore it
      url
    end
  end
end
