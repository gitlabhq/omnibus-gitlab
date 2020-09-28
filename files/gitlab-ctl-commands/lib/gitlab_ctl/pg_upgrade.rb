require 'optparse'
require 'mixlib/shellout'
require 'rainbow'

require_relative 'util'
require_relative '../gitlab_ctl'

# For testing purposes, if the first path cannot be found load the second
begin
  require_relative '../../../../cookbooks/gitlab/libraries/pg_version'
rescue LoadError
  require_relative '../../../gitlab-cookbooks/gitlab/libraries/pg_version'
end

module GitlabCtl
  class PgUpgrade
    include GitlabCtl::Util
    attr_accessor :base_path, :data_path, :tmp_dir, :timeout, :target_version, :initial_version, :psql_command
    attr_writer :data_dir, :tmp_data_dir

    def initialize(base_path, data_path, target_version, tmp_dir = nil, timeout = nil, psql_command = nil)
      @base_path = base_path
      @data_path = data_path
      @tmp_dir = tmp_dir
      @timeout = timeout
      @target_version = target_version
      @initial_version = fetch_running_version
      @psql_command ||= "gitlab-psql"
    end

    def data_dir
      return @data_dir if @data_dir

      # We still need to support legacy attributes starting with `gitlab`, as
      # they might exists before running configure on an existing installation
      pg_base_dir = node_attributes.dig(:gitlab, :postgresql, :dir) || node_attributes.dig(:postgresql, :dir) || File.join(@data_path, "postgresql")

      # If an explicit data_dir exists, that trumps everything, at least until
      # 13.0 when it will be removed. If there isn't one for any reason, we
      # default to computing the data_dir from the info we have.
      @data_dir = node_attributes.dig(:gitlab, :postgresql, :data_dir) || node_attributes.dig(:postgresql, :data_dir) || File.join(pg_base_dir, "data")

      @data_dir = File.realpath(@data_dir) if File.exist?(@data_dir)
      @data_dir
    end

    def tmp_data_dir
      return @tmp_data_dir if @tmp_data_dir

      @tmp_data_dir = @tmp_dir ? "#{@tmp_dir}/data" : data_dir
    end

    def enough_free_space?(dir)
      space_needed(dir) <= space_free(dir)
    end

    def space_needed(dir)
      space_used = GitlabCtl::Util.get_command_output(
        "du -s --block-size=1m #{dir}", nil, @timeout
      ).split.first.to_i

      space_used * 2
    end

    def space_free(dir)
      space_available = GitlabCtl::Util.get_command_output(
        "df -P --block-size=1m #{dir} | awk '{print $4}'", nil, @timeout
      ).split.last.to_i

      (space_available * 0.9).to_i
    end

    def run_pg_command(command)
      pg_username = node_attributes.dig(:postgresql, :username)

      GitlabCtl::Util.get_command_output("su - #{pg_username} -c \"#{command}\"", nil, @timeout)
    end

    def fetch_running_version
      PGVersion.parse(GitlabCtl::Util.get_command_output(
        "#{@base_path}/embedded/bin/pg_ctl --version"
      ).split.last)
    end

    def run_query(query)
      GitlabCtl::Util.get_command_output(
        "#{@psql_command} -d postgres -c '#{query}' -q -t",
        nil, # user
        @timeout
      ).strip
    end

    def fetch_lc_collate
      run_query('SHOW LC_COLLATE')
    end

    def fetch_lc_ctype
      run_query('SHOW LC_CTYPE')
    end

    def fetch_server_encoding
      run_query('SHOW SERVER_ENCODING')
    end

    def fetch_data_version
      PGVersion.parse(File.read("#{data_dir}/PG_VERSION").strip)
    end

    def running?(service = 'postgresql')
      !GitlabCtl::Util.run_command("gitlab-ctl status #{service}").error?
    end

    def start(service = 'postgresql')
      GitlabCtl::Util.run_command("gitlab-ctl start #{service}").error!
    end

    def node_attributes
      @node_attributes ||= GitlabCtl::Util.get_node_attributes(@base_path)
    end

    def base_postgresql_path
      "#{base_path}/embedded/postgresql"
    end

    def target_version_path
      "#{base_postgresql_path}/#{target_version.major}"
    end

    def initial_version_path
      "#{base_postgresql_path}/#{initial_version.major}"
    end

    def run_pg_upgrade
      unless GitlabCtl::Util.progress_message('Upgrading the data') do
        begin
          run_pg_command(
            "#{target_version_path}/bin/pg_upgrade " \
            "-b #{initial_version_path}/bin " \
            "--old-datadir=#{data_dir}  " \
            "--new-datadir=#{tmp_data_dir}.#{target_version.major}  " \
            "-B #{target_version_path}/bin"
          )
        rescue GitlabCtl::Errors::ExecutionError => e
          $stderr.puts "Error upgrading the data to version #{target_version}"
          $stderr.puts "STDOUT: #{e.stdout}"
          $stderr.puts "STDERR: #{e.stderr}"
          false
        rescue Mixlib::ShellOut::CommandTimeout
          $stderr.puts
          $stderr.puts "Timed out during the database upgrade.".color(:red)
          $stderr.puts "To run with more time, remove the temporary directory #{tmp_data_dir}.#{target_version.major},".color(:red)
          $stderr.puts "then re-run your previous command, adding the --timeout option.".color(:red)
          $stderr.puts "See the docs for more information: https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server".color(:red)
          $stderr.puts "Or run gitlab-ctl pg-upgrade --help for usage".color(:red)
          false
        end
      end
        raise GitlabCtl::Errors::ExecutionError.new(
          'run_pg_upgrade', '', 'Error upgrading the database'
        )
      end
    end

    class << self
      def parse_options(args)
        options = {
          tmp_dir: nil,
          wait: true,
          skip_unregister: false,
          timeout: nil,
          target_version: nil,
          skip_disk_check: false,
          leader: nil,
          replica: nil
        }

        OptionParser.new do |opts|
          opts.on('-tDIR', '--tmp-dir=DIR', 'Storage location for temporary data') do |t|
            options[:tmp_dir] = t
          end

          opts.on('-w', '--no-wait', 'Do not wait before starting the upgrade process') do
            options[:wait] = false
          end

          opts.on('-s', '--skip-unregister', 'Skip the attempt to unregister an HA secondary node. No-op in non-HA scenarios') do
            options[:skip_unregister] = true
          end

          opts.on('-TTIMEOUT', '--timeout=TIMEOUT', 'Timeout in milliseconds for the execution of the underlying commands. Accepts duration format such as 1d2h3m4s5ms.') do |t|
            i = GitlabCtl::Util.parse_duration(t)
            options[:timeout] = i.positive? ? i : nil
          end

          opts.on('-VVERSION', '--target-version=VERSION', 'The explicit major version to upgrade or downgrade to') do |v|
            options[:target_version] = v
          end

          opts.on('--skip-disk-check', 'Skip checking that there is enough free disk space to perform upgrade') do
            options[:skip_disk_check] = true
          end

          opts.on('--leader', 'Patroni only. Force leader upgrade procedure.') do
            options[:leader] = true
            options[:replica] = false
          end

          opts.on('--replica', 'Patroni only. Force replica upgrade procedure.') do
            options[:replica] = true
            options[:leader] = false
          end
        end.parse!(args)

        options
      end
    end
  end
end
