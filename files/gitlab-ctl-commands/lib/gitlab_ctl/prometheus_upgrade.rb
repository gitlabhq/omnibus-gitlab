require 'optparse'
require 'fileutils'
require 'mixlib/shellout'
require_relative 'util'

module GitlabCtl
  class PrometheusUpgrade
    attr_reader :v1_path, :v2_path, :backup_path, :binary_path

    # Sample output of prometheus --version is
    # prometheus, version 1.8.2 (branch: master, revision: 6aa68e74cdc25a7d95f3f120ccc8eddd46e3c07b)
    VERSION_REGEX = %r{.*?version (?<version>.*?) .*?}.freeze

    def initialize(base_path, home_dir)
      @base_path = base_path
      @home_dir = home_dir
      @v1_path = File.join(home_dir, "data")
      @v2_path = File.join(home_dir, "data2")
      @backup_path = File.join(home_dir, "data_tmp")
      @binary_path = File.join(base_path, "embedded", "bin", "prometheus")
    end

    def is_version_2?
      file_existence_check
    end

    def file_existence_check
      File.exist?(File.join(@home_dir, "data", "wal"))
    end

    def prepare_directories
      # Directory to store data in v2 format
      FileUtils.mkdir_p(@v2_path)
      system(*%W[chown --reference=#{@v1_path} #{@v2_path}])
      system(*%W[chmod --reference=#{@v1_path} #{@v2_path}])
    end

    def backup_data
      # Backup existing v1 data to a temporary location
      FileUtils.mv(@v1_path, @backup_path)
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

    class << self
      def parse_options(args)
        node_attributes = GitlabCtl::Util.get_node_attributes

        options = {
          home_dir: node_attributes.dig(:monitoring, :prometheus, :home),
          skip_reconfigure: false,
          wait: true,
        }
        OptionParser.new do |opts|
          opts.on('-s', '--skip-data-migration', 'Obsolete flag, ignored.')

          opts.on('--skip-reconfigure', 'Skip reconfigure when upgrading.') do
            options[:skip_reconfigure] = true
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
