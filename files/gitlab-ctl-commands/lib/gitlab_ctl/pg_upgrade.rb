require_relative 'util'

module GitlabCtl
  class PgUpgrade
    include GitlabCtl::Util
    attr_accessor :base_path

    def initialize(base_path)
      @base_path = base_path
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
