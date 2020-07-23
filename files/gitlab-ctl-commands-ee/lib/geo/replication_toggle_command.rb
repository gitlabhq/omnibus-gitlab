require_relative "./replication_process"
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
      @replication_process.send(@action.to_sym)
    rescue Geo::PsqlError => e
      puts "Postgres encountered an error: #{e.message}"
      exit 1
    rescue Geo::RakeError => e
      puts "Rake encountered an error: #{e.message}"
      exit 1
    end

    def arguments
      @args.dup
    end

    private

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
  end
end
