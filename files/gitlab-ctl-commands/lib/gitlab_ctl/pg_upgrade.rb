require 'optparse'
require_relative 'util'

# For testing purposes, if the first path cannot be found load the second
begin
  require_relative '../../../../cookbooks/gitlab/libraries/pg_version'
rescue LoadError
  require_relative '../../../gitlab-cookbooks/gitlab/libraries/pg_version'
end

module GitlabCtl
  class PgUpgrade
    include GitlabCtl::Util
    attr_accessor :base_path, :data_path, :tmp_dir
    attr_writer :data_dir, :tmp_data_dir

    def initialize(base_path, data_path, tmp_dir = nil)
      @base_path = base_path
      @data_path = data_path
      @tmp_dir = tmp_dir
    end

    def default_data_dir
      "#{@data_path}/postgresql/data"
    end

    def data_dir
      return @data_dir if @data_dir

      @data_dir = File.realpath(default_data_dir)
    end

    def tmp_data_dir
      return @tmp_data_dir if @tmp_data_dir
      @tmp_data_dir = @tmp_dir ? "#{@tmp_dir}/data" : data_dir
    end

    def run_pg_command(command)
      GitlabCtl::Util.get_command_output("su - gitlab-psql -c \"#{command}\"")
    end

    def fetch_running_version
      PGVersion.parse(GitlabCtl::Util.get_command_output(
        "#{@base_path}/embedded/bin/pg_ctl --version"
      ).split.last)
    end

    def run_query(query)
      GitlabCtl::Util.get_command_output(
        "#{@base_path}/bin/gitlab-psql -d postgres -c '#{query}' -q -t"
      ).strip
    end

    def fetch_lc_collate
      run_query('SHOW LC_COLLATE')
    end

    def fetch_server_encoding
      run_query('SHOW SERVER_ENCODING')
    end

    def fetch_data_version
      PGVersion.parse(File.read("#{data_dir}/PG_VERSION").strip)
    end

    def running?
      !GitlabCtl::Util.run_command('gitlab-ctl status postgresql').error?
    end

    def start
      GitlabCtl::Util.run_command('gitlab-ctl start postgresql').error!
    end

    class << self
      def parse_options(args)
        options = {
          tmp_dir: nil,
          wait: true
        }

        OptionParser.new do |opts|
          opts.on('-tDIR', '--tmp-dir=DIR', 'Storage location for temporary data') do |t|
            options[:tmp_dir] = t
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
