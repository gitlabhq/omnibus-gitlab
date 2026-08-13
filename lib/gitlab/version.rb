require 'uri'
require 'yaml'

require_relative 'util'

module Gitlab
  class Version
    DEFAULT_SOURCE = 'remote'.freeze
    ALTERNATIVE_SOURCE = 'alternative'.freeze
    SECURITY_SOURCE = 'security'.freeze

    CUSTOM_SOURCES_FILENAME = '.custom_sources.yml'.freeze

    # Single source of truth for pinned versions and checksums of bundled
    # third-party components. See the file header for its schema.
    SOFTWARE_VERSIONS_FILENAME = 'config/software_versions.yml'.freeze

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

    # Parsed contents of config/software_versions.yml, memoized so the file is
    # read once regardless of how many software definitions ask for it.
    #
    # @return [Hash]
    def self.software_versions
      @software_versions ||= load_versions_file(software_versions_path)
    end

    def self.software_versions_path
      File.expand_path("../../#{SOFTWARE_VERSIONS_FILENAME}", __dir__)
    end

    # Parses a versions YAML file with every scalar kept as a String, so a
    # version like "3.4" or "1.20" is never coerced to a Float (which would
    # silently turn "1.20" into 1.2). This is why the data file does not need
    # every value quoted.
    #
    # It walks the documented Psych::Nodes AST rather than using the default
    # loader (which applies type coercion) or Psych's internal ScalarScanner /
    # ToRuby APIs, so it does not depend on Psych internals that could change
    # across Ruby versions.
    #
    # @return [Hash]
    def self.load_versions_file(path)
      nodes_to_strings(Psych.parse_file(path))
    end

    # Recursively converts a Psych::Nodes tree into Ruby Hashes/Arrays with
    # every scalar kept as its raw String value.
    def self.nodes_to_strings(node)
      case node
      when Psych::Nodes::Stream, Psych::Nodes::Document
        nodes_to_strings(node.children.first)
      when Psych::Nodes::Mapping
        node.children.each_slice(2).to_h { |key, value| [nodes_to_strings(key), nodes_to_strings(value)] }
      when Psych::Nodes::Sequence
        node.children.map { |child| nodes_to_strings(child) }
      when Psych::Nodes::Scalar
        node.value
      else
        raise "Unsupported YAML node type #{node.class} in #{SOFTWARE_VERSIONS_FILENAME}"
      end
    end

    # Drops the memoized data. Only needed in tests that stub the file.
    def self.reset_software_versions!
      @software_versions = nil
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
        token = Gitlab::Util.get_env("SECURITY_PRIVATE_TOKEN") || Gitlab::Util.get_env("CI_JOB_TOKEN")
        attach_remote_credential(sources[channel], token) || sources[::Gitlab::Version.fallback_sources_channel]
      else
        sources[channel]
      end
    end

    def remote(channel = nil)
      read_remote_from_env || read_remote_from_file(channel) || ""
    end

    # Entry for this component in config/software_versions.yml.
    #
    # @return [Hash]
    def software_data
      @software_data ||= self.class.software_versions.fetch(@software) do
        raise KeyError, "No entry for '#{@software}' in #{SOFTWARE_VERSIONS_FILENAME}"
      end
    end

    # Lenient reader for an optional key of this component's data; returns nil
    # when the key is absent.
    def [](key)
      software_data[key.to_s]
    end

    # Strict reader for a required key, raising a descriptive error when it is
    # missing. Use this for values a definition cannot sensibly run without,
    # e.g. ruby's `current`/`next` pins, so a data file that drops them fails
    # loudly instead of silently yielding nil.
    def fetch(key)
      software_data.fetch(key.to_s) do
        raise KeyError, "'#{@software}' is missing required key '#{key}' in #{SOFTWARE_VERSIONS_FILENAME}"
      end
    end

    # The pinned upstream version for single-version components. An optional
    # `env_var` in the data file lets ad-hoc builds override the pin without
    # editing the YAML.
    #
    # Not valid for components that use a `checksums` map (e.g. ruby); read
    # their `current`/`next` pins via #[] instead.
    #
    # @return [String]
    def upstream_version
      env_var = software_data['env_var']
      (env_var && Gitlab::Util.get_env(env_var)) || single_pinned_version
    end

    # sha256 of the upstream source tarball for the given version (defaults to
    # the pinned `upstream_version`). Works with either a single `sha256` or a
    # `checksums` map.
    #
    # @return [String]
    def source_sha256(for_version = upstream_version)
      checksums = software_data['checksums'] || { software_data['version'] => software_data['sha256'] }

      checksums.fetch(for_version) do
        raise KeyError, "No sha256 for #{@software} #{for_version} in #{SOFTWARE_VERSIONS_FILENAME}"
      end
    end

    # Version string of the pre-built UBT bundle (e.g. "3.2.1-3ubt"). Derived
    # from the source version and the UBT `revision` suffix so it stays coupled
    # to `default_version`, matching the pre-externalization `"#{version}-Nubt"`.
    def ubt_version
      revision = ubt_data.fetch('revision')
      "#{upstream_version}-#{revision}"
    end

    # sha256 of the pre-built UBT bundle.
    def ubt_sha256
      ubt_data.fetch('sha256')
    end

    private

    def single_pinned_version
      software_data.fetch('version') do
        raise KeyError,
              "'#{@software}' uses a checksums map and has no single 'version' pin in " \
              "#{SOFTWARE_VERSIONS_FILENAME}; read its 'current'/'next' pins via #[] instead"
      end
    end

    def ubt_data
      software_data.fetch('ubt') do
        raise KeyError, "No 'ubt' entry for '#{@software}' in #{SOFTWARE_VERSIONS_FILENAME}"
      end
    end

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
