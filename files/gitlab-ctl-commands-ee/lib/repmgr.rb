require 'mixlib/shellout'
require 'timeout'

class RepmgrHelper
  attr_accessor :command, :subcommand, :args

  def initialize(command, subcommand, args = nil)
    @command = Kernel.const_get("#{self.class}::#{command.capitalize}")
    @subcommand = subcommand
    @args = args
  end

  def execute
    @command.send(subcommand, @args)
  end

  class Base
    class << self
      def repmgr_cmd(args, command)
        cmd("/opt/gitlab/embedded/bin/repmgr #{args[:verbose]} -f /var/opt/gitlab/postgresql/repmgr.conf #{command}", 'gitlab-psql')
      end

      def cmd(command, user = 'root')
        results = Mixlib::ShellOut.new(command, user: user, cwd: '/tmp')
        begin
          results.run_command
          results.error!
        rescue Mixlib::ShellOut::ShellCommandFailed
          puts "Error running command: #{results.command}"
          puts "STDOUT: #{results.stdout}" if results.stdout
          puts "STDERR: #{results.stderr}" if results.stderr
          raise
        rescue StandardError => se
          puts "Unknown Error: #{se}"
        end
        results.stdout
      end

      def repmgr_with_args(command, args)
        repmgr_cmd(args, "-h #{args[:primary]} -U #{args[:user]} -d #{args[:database]} -D #{args[:directory]} #{command}")
      end

      def wait_for_postgresql(timeout)
        # wait for *timeout* seconds for postgresql to respond to queries
        Timeout.timeout(timeout) do
          results = nil
          loop do
            begin
              results = cmd("gitlab-psql -l")
            rescue Mixlib::ShellOut::ShellCommandFailed
              sleep 1
              next
            else
              break
            end
          end
        end
      rescue Timeout::TimeoutError
        raise TimeoutError("Timed out waiting for PostgreSQL to start")
      end
    end
  end

  class Standby < Base
    class << self
      def clone(args)
        repmgr_with_args('standby clone', args)
      end

      def follow(args)
        repmgr_with_args('standby follow', args)
      end

      def promote(args)
        repmgr_cmd(args, 'standby promote')
      end

      def register(args)
        repmgr_cmd(args, 'standby register')
      end

      def unregister(args, node = nil)
        return repmgr_cmd(args, "standby unregister --node=#{node}") unless node.nil?
        repmgr_cmd(args, "standby unregister")
      end

      def setup(args)
        if args[:wait]
          $stdout.puts "Doing this will delete the entire contents of #{args[:directory]}"
          $stdout.puts "If this is not what you want, hit Ctrl-C now to exit"
          $stdout.puts "To skip waiting, rerun with the -w option"
          $stdout.puts "Sleeping for 30 seconds"
          sleep 30
        end
        $stdout.puts "Stopping the database"
        cmd("gitlab-ctl stop postgresql")
        $stdout.puts "Removing the data"
        cmd("rm -rf /var/opt/gitlab/postgresql/data")
        $stdout.puts "Cloning the data"
        clone(args)
        $stdout.puts "Starting the database"
        cmd("gitlab-ctl start postgresql")
        # Wait until postgresql is responding to queries before proceeding
        wait_for_postgresql(30)
        $stdout.puts "Registering the node with the cluster"
        register(args)
      end
    end
  end

  class Cluster < Base
    class << self
      def show(args)
        repmgr_cmd(args, 'cluster show')
      end
    end
  end

  class Master < Base
    class << self
      def register(args)
        repmgr_cmd(args, 'master register')
      end
    end
  end
end
