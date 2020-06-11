require 'fileutils'
require 'net/http'
require 'optparse'

module Patroni
  ClientError = Class.new(StandardError)

  def self.parse_options(args)
    # throw away arguments that initiated this command
    loop do
      break if args.shift == 'patroni'
    end

    options = {}

    global = OptionParser.new do |opts|
      opts.banner = 'patroni [options] command [options]'
      opts.on('-q', '--quiet', 'Silent or quiet mode') do |q|
        options[:quiet] = q
      end
      opts.on('-v', '--verbose', 'Verbose or debug mode') do |v|
        options[:verbose] = v
      end
      opts.on('-h', '--help', 'Usage help') do
        warn usage
        Kernel.exit 1
      end
    end

    commands = {
      'bootstrap' => OptionParser.new do |opts|
        opts.on('--scope=SCOPE', 'Name of the cluster to be bootstrapped') do |scope|
          options[:scope] = scope
        end
        opts.on('--datadir=DATADIR', 'Path to the data directory of the cluster instance to be bootstrapped') do |datadir|
          options[:datadir] = datadir
        end
      end,
      'check-leader' => OptionParser.new,
      'check-replica' => OptionParser.new,
    }

    global.order! args

    command = args.shift

    raise OptionParser::ParseError, "unspecified Patroni command" \
      if command.nil? || command.empty?

    raise OptionParser::ParseError, "unknown Patroni command: #{command}" \
      unless commands.key? command

    options[:command] = command
    commands[command].order! args

    options
  end

  def self.usage
    <<-USAGE

Usage:
  gitlab-ctl patroni [options] command [options]

  GLOBAL OPTIONS:
    -h, --help      Usage help
    -q, --quiet     Silent or quiet mode
    -v, --verbose   Verbose or debug mode

  COMMANDS:
    bootstrap       Bootstraps the node
    check-leader    Check if the current node is the Patroni leader
    check-replica   Check if the current node is a Patroni replica

    USAGE
  end

  def self.init_db(options)
    GitlabCtl::Util.run_command("/opt/gitlab/embedded/bin/initdb -D #{options[:datadir]} -E UTF8")
  end

  def self.copy_config(options)
    attributes = GitlabCtl::Util.get_public_node_attributes
    FileUtils.cp_r "#{attributes['patroni']['data_dir']}/.", options[:datadir]
  end

  def self.leader?(options)
    Client.new.leader?
  end

  def self.replica?(options)
    Client.new.replica?
  end

  class Client
    attr_accessor :uri

    def initialize
      @attributes = GitlabCtl::Util.get_public_node_attributes
      @uri = URI("http://#{@attributes['patroni']['api_address']}")
    end

    def leader?
      get('/leader') do |response|
        response.code == '200'
      end
    end

    def replica?
      get('/replica') do |response|
        response.code == '200'
      end
    end

    private

    def get(endpoint, header = nil)
      Net::HTTP.start(@uri.host, @uri.port) do |http|
        http.request_get(endpoint, header) do |response|
          return yield response
        end
      end
    end
  end
end
