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
      else
        nil
      end
    end

    def print(prepend_version = true)
      if @read_version.include?('.pre') || @read_version == "master"
        "master"
      elsif @read_version.start_with?('buildfrombranch:')
        @read_version.gsub(/^buildfrombranch:/,'').strip
      elsif @read_version.empty?
        nil
      else
        v = "v" if prepend_version
        [
          v,
          @read_version
        ].join
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
