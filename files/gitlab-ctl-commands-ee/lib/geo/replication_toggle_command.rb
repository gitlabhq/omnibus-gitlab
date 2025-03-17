require_relative "./replication_process"
require_relative "./promote_db"
require_relative "./pitr_file"
require 'optparse'
require 'English'

module Geo
  class ReplicationToggleCommand
    def initialize(ctl, action, args)
      @ctl = ctl
      @args = args
      @action = action

      @options = {
        db_name: 'gitlabhq_production'
      }
      parse_options!

      @replication_process = Geo::ReplicationProcess.new(@ctl, @options)
    end

    def execute!
      process_action
      process_pitr_file
    rescue Geo::PitrFileError => e
      puts "Geo point-in-time recovery file encountered an error: #{e.message}. The #{action} process was aborted."
      process_action(reverse_action) if reverse_action
      exit 1
    end

    def arguments
      @args.dup
    end

    private

    attr_reader :action, :ctl

    def process_action(act = action)
      @replication_process.send(act.to_sym)
    rescue Geo::PsqlError => e
      puts "Postgres encountered an error: #{e.message}"
      exit 1
    rescue Geo::RakeError => e
      puts "Rake encountered an error: #{e.message}"
      exit 1
    end

    def process_pitr_file
      geo_pitr_file = Geo::PitrFile.new(ctl)

      if action == 'pause'
        puts "* Create Geo point-in-time recovery file".color(:green)
        geo_pitr_file.create(current_lsn)
      elsif action == 'resume'
        puts "* Remove Geo point-in-time recovery file".color(:green)
        geo_pitr_file.delete
      end
    end

    def current_lsn
      run_query('SELECT pg_last_wal_replay_lsn()')
    end

    def run_query(query)
      GitlabCtl::Util.get_command_output("gitlab-psql -d postgres -c '#{query}' -q -t").strip
    end

    def parse_options!
      opts_parser = OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl replication-process-#{@action} [options]"

        opts.separator ''
        opts.separator 'Specific options:'

        opts.on('--db_name=gitlabhq_production', 'Specify the database name') do |db_name|
          @options[:db_name] = db_name
        end

        opts.on_tail('-h', '--help', 'Show this message') do
          puts opts
          exit
        end
      end

      opts_parser.parse!(arguments)
    end

    def reverse_action
      if action == 'pause'
        'resume'
      elsif action == 'resume'
        'pause'
      end
    end
  end
end
