require 'erb'
require 'mixlib/shellout'

module Pgbouncer
  class Databases
    attr_accessor :install_path, :databases, :ini_file, :template_file
    attr_reader :data_path

    def initialize(databases, install_path, base_data_path)
      self.data_path = base_data_path
      @install_path = install_path
      @databases = databases
      @ini_file =  "#{data_path}/pgbouncer/databases.ini"
      @template_file = "#{@install_path}/embedded/cookbooks/gitlab-ee/templates/default/databases.ini.erb"
    end

    def data_path=(path)
      full_path = "#{path}/pgbouncer"
      unless Dir.exist?(full_path)
        raise "The directory #{full_path} does exist. Please ensure pgbouncer is configured on this node"
      end
      @data_path = full_path
    end

    def render
      ERB.new(File.read(@template_file)).result(binding)
    end

    def write
      File.open(@ini_file, 'w') { |f| f.puts render }
    end

    def reload
      pid = File.read("#{@install_path}/sv/pgbouncer/supervise/pid")
      # If pgbouncer isn't running, there is nothing to do
      return if pid.empty?
      command = Mixlib::ShellOut.new("kill -1 #{pid}")
      command.run_command
      begin
        command.error!
      rescue Mixlib::ShellOut::ShellCommandFailed
        $stderr.puts "Error running command: #{command}"
        $stderr.puts "ERROR: #{command.stderr}"
        raise
      end
    end

    def notify
      write
      reload
    end
  end
end
