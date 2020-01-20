require 'io/console'
require 'rainbow/ext/string'

# For testing purposes, if the first path cannot be found load the second
begin
  require_relative '../../../omnibus-ctl/lib/postgresql'
rescue LoadError
  require_relative '../../../gitlab-ctl-commands/lib/postgresql'
end

module Geo
  class ReplicationProcess
    attr_accessor :base_path, :ctl
    attr_reader :options

    def initialize(instance, options)
      @base_path = instance.base_path
      @ctl = instance
      @options = options
    end

    def pause
      puts '* Pausing replication'.color(:green)
      run_query('SELECT pg_wal_replay_pause();')
    end

    def resume
      puts '* Resume replication'.color(:green)
      run_query('pg_wal_replay_resume();')
    end

    private

    def run_query(query)
      status = GitlabCtl::Util.run_command(
        "#{base_path}/bin/gitlab-psql -d #{db_name} -c '#{query}' -q -t"
      )
      status.error? ? false : status.stdout.strip
    end

    def db_name
      @options[:db_name]
    end
  end
end
