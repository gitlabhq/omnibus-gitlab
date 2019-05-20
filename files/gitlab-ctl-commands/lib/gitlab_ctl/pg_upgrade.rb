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

    def initialize(base_path, data_path, tmp_dir = nil, timeout = nil)
      @base_path = base_path
      @data_path = data_path
      @tmp_dir = tmp_dir
      @timeout = timeout
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
      # We still need to support legacy attributes starting with `gitlab`, as they might exists before running
      # configure on an existing installation
      #
      # TODO: Remove support for legacy attributes in GitLab 13.0
      pg_username = node_attributes.dig(:gitlab, :postgresql, :username) || node_attributes.dig(:postgresql, :username)

      GitlabCtl::Util.get_command_output(command, pg_username, @timeout)
    end

    def fetch_running_version
      PGVersion.parse(GitlabCtl::Util.get_command_output(
        "#{@base_path}/embedded/bin/pg_ctl --version"
      ).split.last)
    end

    def run_query(query)
      GitlabCtl::Util.get_command_output(
        "#{@base_path}/bin/gitlab-psql -d postgres -c '#{query}' -q -t",
        nil, # user
        @timeout
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

    def node_attributes
      @node_attributes ||= GitlabCtl::Util.get_node_attributes(@base_path)
    end

    class << self
      def parse_options(args)
        options = {
          tmp_dir: nil,
          wait: true,
          skip_unregister: false,
          timeout: nil
        }

        OptionParser.new do |opts|
          opts.on('-tDIR', '--tmp-dir=DIR', 'Storage location for temporary data') do |t|
            options[:tmp_dir] = t
          end

          opts.on('-w', '--no-wait', 'Do not wait before starting the upgrade process') do
            options[:wait] = false
          end

          opts.on('-s', '--skip-unregister', 'Skip the attempt to unregister an HA secondary node. No-op in non-HA scenarios.') do
            options[:skip_unregister] = true
          end

          opts.on('-TTIMEOUT', '--timeout=TIMEOUT', 'Timeout in milliseconds for the execution of the underlying commands') do |t|
            options[:timeout] = t
          end
        end.parse!(args)

        options
      end
    end
  end
end
