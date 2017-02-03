require_relative 'util'

module GitlabCtl
  class PgUpgrade
    include GitlabCtl::Util
    attr_accessor :base_path, :data_dir, :data_path, :inst_dir, :tmp_dir
    attr_writer :data_dir, :tmp_data_dir

    def initialize(base_path, data_path, tmp_dir = nil)
      @base_path = base_path
      @data_path = data_path
      @tmp_dir = tmp_dir
    end

    def data_dir
      return @data_dir if @data_dir

      # Try to fetch the data_directory from the running database. Use the default
      # otherwise.
      begin
        @data_dir = run_query('show data_directory')
      rescue GitlabCtl::Errors::ExecutionError
        $stdout.puts 'Error fetching data_directory from running database, using default value.'
        @data_dir = "#{data_path}/postgresql/data"
      end
    end

    def tmp_data_dir
      return @tmp_data_dir if @tmp_data_dir
      @tmp_data_dir = @tmp_dir ? "#{@tmp_dir}/data" : @data_dir
    end

    def run_pg_command(command)
      GitlabCtl::Util.get_command_output("su - gitlab-psql -c \"#{command}\"")
    end

    def fetch_running_version
      GitlabCtl::Util.get_command_output(
        "#{@base_path}/embedded/bin/pg_ctl --version"
      ).split.last
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
  end
end
