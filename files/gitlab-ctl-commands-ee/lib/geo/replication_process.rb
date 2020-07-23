require 'rainbow/ext/string'

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

      task = run_task('geo:replication:pause')
      # This isn't an error because theoretically if the primary is down you
      # may want to use this to pause the WAL anyway.
      puts task.stdout.strip.color(:red) if task.error?

      query = run_query('SELECT pg_wal_replay_pause();')
      raise PsqlError, "Unable to pause postgres replication #{query.stdout.strip}" if query.error?

      puts '* Replication paused'.color(:green)
    end

    def resume
      puts '* Resume replication'.color(:green)

      query = run_query('pg_wal_replay_resume();')
      raise PsqlError, "Unable to resume postgres replication #{query.stdout.strip}" if query.error?

      task = run_task('geo:replication:resume')
      raise RakeError, "Unable to resume replication from primary #{task.stdout.strip}" if task.error?

      puts '* Replication resumed'.color(:green)
    end

    private

    def run_query(query)
      GitlabCtl::Util.run_command(
        "#{base_path}/bin/gitlab-psql -d #{db_name} -c '#{query}' -q -t"
      )
    end

    def run_task(task)
      GitlabCtl::Util.run_command(
        "#{base_path}/bin/gitlab-rake #{task}"
      )
    end

    def db_name
      @options[:db_name]
    end
  end

  PsqlError = Class.new(StandardError)
  RakeError = Class.new(StandardError)
end
