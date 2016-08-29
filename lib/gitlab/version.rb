require 'yaml'

module Gitlab
  class Version

    def initialize(software_name, version)
      @software = software_name

      @read_version = if version
                        version
                      else
                        read_version_from_file
                      end
    end

    def read_version_from_file
      filepath = File.expand_path(version_file, Omnibus::Config.project_root)
      File.read(filepath).chomp
    rescue Errno::ENOENT
      # Didn't find the file
      @read_version = ""
    end

    def version_file
      case @software
      when "gitlab-rails" || "gitlab-rails-ee"
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

    def print
      if @read_version.include?('.pre') || @read_version == "master"
        "master"
      elsif @read_version.start_with?('buildfrombranch:')
        @read_version.gsub(/^buildfrombranch:/,'').strip
      elsif @read_version.empty?
        nil
      else
        "v#{@read_version}"
      end
    end

    def remote
      filepath = File.expand_path(".custom_sources.yml", Omnibus::Config.project_root)
      YAML.load_file(filepath)[@software]['remote']
    end
  end
end
