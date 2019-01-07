require 'optparse'
require 'fileutils'
require 'mixlib/shellout'

module GitlabCtl
  class PrometheusUpgrade
    attr_reader :v1_path, :v2_path, :backup_path, :binary_path

    # Sample output of prometheus --version is
    # prometheus, version 1.8.2 (branch: master, revision: 6aa68e74cdc25a7d95f3f120ccc8eddd46e3c07b)
    VERSION_REGEX = %r{.*?version (?<version>.*?) .*?}

    def initialize(base_path, home_dir)
      @base_path = base_path
      @home_dir = home_dir
      @v1_path = File.join(home_dir, "data")
      @v2_path = File.join(home_dir, "data2")
      @backup_path = File.join(home_dir, "data_tmp")
      @binary_path = File.join(base_path, "embedded", "bin", "prometheus")
    end

    def is_version_2?
      version_string_check && file_existence_check
    end

    def file_existence_check
      File.exist?(File.join(@home_dir, "data", "wal"))
    end

    def version_string_check
      version_output = `#{@binary_path} --version 2>&1`.strip
      version_output.match(VERSION_REGEX)[:version].start_with?("2")
    end

    def prepare_directories
      # Directory to store data in v2 format
      FileUtils.mkdir_p(@v2_path)
      system("chown --reference=#{@v1_path} #{@v2_path}")
      system("chmod --reference=#{@v1_path} #{@v2_path}")
    end

    def backup_data
      # Backup existing v1 data to a temporary location
      FileUtils.cp_r(@v1_path, @backup_path, preserve: true)
    end

    def revert
      # Delete intermediate directories and restore the original data
      FileUtils.rm_rf(@v1_path)
      FileUtils.rm_rf(@v2_path)
      FileUtils.mv(@backup_path, @v1_path)
    end

    def rename_directory
      # We have already backed up the original data directory to @backup_path
      # Delete it and rename v2 directory to that name
      FileUtils.rm_rf(@v1_path)
      FileUtils.mv(@v2_path, @v1_path)
    end

    def prometheus_user
      Etc.getpwuid(File.stat(@v1_path).uid).name
    end

    def prometheus_group
      Etc.getgrgid(File.stat(@v1_path).gid).name
    end

    def migrate
      status = true

      command = %(#{@base_path}/embedded/bin/prometheus-storage-migrator -v1-path=#{@v1_path} -v2-path=#{@v2_path})
      result = Mixlib::ShellOut.new(
        command,
        user: prometheus_user,
        group: prometheus_group,
        # Allow a week before timing out.
        timeout: 604800
      )
      result.live_stdout = $stdout
      result.live_stderr = $stderr

      begin
        result.run_command
        result.error!
      rescue Mixlib::ShellOut::ShellCommandFailed
        $stderr.puts "Error running command: #{result.command}"
        $stderr.puts "ERROR: #{result.stderr}" unless result.stderr.empty?
        status = false
      rescue Mixlib::ShellOut::CommandTimeout
        $stderr.puts "Timeout running command: #{result.command}"
        status = false
      end

      status
    end

    class << self
      def parse_options(args)
        options = {
          skip_data_migration: false,
          home_dir: "/var/opt/gitlab/prometheus",
          wait: true
        }
        OptionParser.new do |opts|
          opts.on('-s', '--skip-data-migration', 'Skip migrating data to Prometheus 2.x format') do
            options[:skip_data_migration] = true
          end

          opts.on('-dDIR', '--home-dir=DIR', "Value of prometheus['home'] set in gitlab.rb. Defaults to /var/opt/gitlab/prometheus") do |d|
            options[:home_dir] = d
          end

          opts.on('-w', '--no-wait', 'Do not wait before starting the upgrade process') do
            options[:wait] = false
          end
        end.parse!(args)

        options
      end
    end
  end
end
