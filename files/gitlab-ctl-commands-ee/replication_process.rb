require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/geo/replication_process"
require 'optparse'
require 'English'

add_command_under_category('replication-process-pause', 'gitlab-geo', 'Replication Process', 2) do |_cmd_name, *args|
  ReplicationProcessCommand.new(self, ARGV).execute!
end

class ReplicationProcessCommand
  def initialize(ctl, args)
    @ctl = ctl
    @args = args

    @options = {
      db_name: 'gitlabhq_production'
    }

    parse_options!
  end

  def execute!
    Geo::ReplicationProcess.new(@ctl, @options).pause
  end

  def arguments
    @args.dup
  end

  private

  def parse_options!
    opts_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: gitlab-ctl replication-process-pause [options]'

      opts.separator ''
      opts.separator 'Specific @options:'

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
