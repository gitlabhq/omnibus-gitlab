module Gitlab
  class Version

    def initialize(filename)
      @filename = filename
      filepath = File.expand_path(@filename, Omnibus::Config.project_root)
      @read_version = File.read(filepath).chomp
    rescue Errno::ENOENT
      # Didn't find the file
      @read_version = ""
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
      case @filename
      when "VERSION"
        if @read_version.include?('-ee')
          "git@dev.gitlab.org:gitlab/gitlab-ee.git"
        else
          "git@dev.gitlab.org:gitlab/gitlabhq.git"
        end
      when "GITLAB_SHELL_VERSION"
        "git@dev.gitlab.org:gitlab/gitlab-shell.git"
      when "GITLAB_WORKHORSE_VERSION"
        "git@dev.gitlab.org:gitlab/gitlab-workhorse.git"
      when "GITLAB_PAGES_VERSION"
        "https://gitlab.com/gitlab-org/gitlab-pages.git"
      else
        nil
      end
    end
  end
end
