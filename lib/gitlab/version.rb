require 'yaml'

module Gitlab
  class Version
    def initialize(software_name, version = nil)
      @software = software_name

      @read_version = if version
                        version
                      else
                        read_version_from_file
                      end
      @project_root = File.join(File.dirname(__dir__), '../')
    end

    def read_version_from_file
      path_to_version_file = version_file
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

    def version_file
      case @software
      when "gitlab-rails", "gitlab-rails-ee"
        "VERSION"
      when "gitlab-shell"
        "GITLAB_SHELL_VERSION"
      when "gitlab-workhorse"
        "GITLAB_WORKHORSE_VERSION"
      when "gitlab-pages"
        "GITLAB_PAGES_VERSION"
      when "gitaly"
        "GITALY_SERVER_VERSION"
      end
    end

    def print(prepend_version = true)
      return nil if @read_version.empty?
      begin
        Gem::Version.new(@read_version)
        v = "v" if prepend_version
        [
          v,
          @read_version
        ].join
      rescue ArgumentError
        # An exception will be raised if @read_version is not a proper version
        # string - i.e. if it is a branch name or a commit SHA.
        @read_version
      end
    end

    def remote
      filepath = File.expand_path(".custom_sources.yml", @project_root)
      software = YAML.load_file(filepath)[@software]

      if software
        software['remote']
      else
        ""
      end
    end
  end
end
