require 'fileutils'
require 'net/http'
require 'optparse'

module Geo
  USAGE ||= <<~EOS.freeze
    Usage:
      gitlab-ctl geo [options] command [options]

    GLOBAL OPTIONS:
      -h, --help      Usage help
      -q, --quiet     Silent or quiet mode
      -v, --verbose   Verbose or debug mode

    COMMANDS:
      promote               Promote the current node
  EOS

  def self.parse_options(args)
    loop do
      break if args.shift == 'geo'
    end

    options = {}

    global = OptionParser.new do |opts|
      opts.banner = 'geo [options] command [options]'

      opts.on('-q', '--quiet', 'Silent or quiet mode') do |q|
        options[:quiet] = q
      end

      opts.on('-v', '--verbose', 'Verbose or debug mode') do |v|
        options[:verbose] = v
      end

      opts.on('-h', '--help', 'Usage help') do
        Utils.warn_and_exit usage
      end
    end

    commands = {
      'promote' => OptionParser.new do |opts|
        opts.on('-h', '--help', 'Prints this help') do
          Utils.warn_and_exit opts
        end

        opts.on('-f', '--force', 'Proceed with no confirmation') do |f|
          options[:force] = f
        end
      end
    }

    global.order! args
    command = args.shift

    raise OptionParser::ParseError, "Geo command is not specified." \
      if command.nil? || command.empty?

    raise OptionParser::ParseError, "Unknown Geo command: #{command}" \
      unless commands.key? command

    options[:command] = command
    commands[command].order! args
    options
  end

  def self.usage
    USAGE
  end

  class Utils
    def self.warn_and_exit(msg, code = 0)
      Kernel.warn msg
      Kernel.exit(code)
    end
  end
end
