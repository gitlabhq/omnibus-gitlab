
module Gitlab
  class Version

    def initialize(filename)
      filepath = File.expand_path(filename, Omnibus::Config.project_root)
      @read_version = File.read(filepath).chomp
    rescue Errno::ENOENT
      # Didn't find the file
      @read_version = ""
    end

    def version
      if @read_version.include?('.pre')
        "master"
      elsif @read_version.empty?
        nil
      else
        @read_version
      end
    end
  end
end
