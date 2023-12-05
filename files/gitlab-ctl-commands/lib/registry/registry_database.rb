require 'fileutils'
require 'optparse'

require_relative './migrate'
require_relative './import'

module RegistryDatabase
  EXEC_PATH = '/opt/gitlab/embedded/bin/registry'.freeze
  CONFIG_PATH = '/var/opt/gitlab/registry/config.yml'.freeze

  USAGE = <<~EOS.freeze
    Usage:
      gitlab-ctl registry-database command subcommand [options]

    GLOBAL OPTIONS:
      -h, --help      Usage help

    COMMANDS:
      migrate                Manage schema migrations
      import                 Import filesystem metadata into the database
  EOS

  def self.parse_options!(ctl, args)
    @ctl = ctl

    loop do
      break if args.shift == 'registry-database'
    end

    global = OptionParser.new do |opts|
      opts.on('-h', '--help', 'Usage help') do
        Kernel.puts USAGE
        Kernel.exit 0
      end
    end

    global.order!(args)

    # the command is needed by the dependencies in populate_commands
    command = args[0]
    raise OptionParser::ParseError, "registry-database command is not specified." \
      if command.nil? || command.empty?

    options = {}
    commands = populate_commands(options)

    raise OptionParser::ParseError, "Unknown registry-database command: #{command}" \
      unless commands.key?(command)

    commands[command].parse!(args)
    options[:command] = command

    options
  end

  def self.populate_commands(options)
    database_docs_url = 'https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/database-migrations.md#administration'

    {
      'migrate' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl registry-database migrate SUBCOMMAND [options]. See documentation at #{database_docs_url}"
        begin
          Migrate.parse_options!(ARGV, options)
        rescue OptionParser::ParseError => e
          warn "#{e}\n\n#{Migrate::USAGE}"
          exit 128
        end
      end,

      'import' => OptionParser.new do |parser|
        Import.parse_options!(ARGV, parser, options)
      rescue OptionParser::ParseError => e
        warn "#{e}\n\n#{Import::USAGE}"
        exit 128
      end,
    }
  end

  def self.usage
    USAGE
  end

  def self.execute(options)
    unless enabled?
      log "Container registry is not enabled, exiting..."
      return
    end

    [EXEC_PATH, CONFIG_PATH].each do |path|
      next if File.exist?(path)

      Kernel.abort "Could not find '#{path}' file. Is this command being run on a Container Registry node?"
    end

    command = set_command(options)

    puts "Executing command:\n#{command.join(' ')}\n"

    begin
      status = Kernel.system(*command)
      Kernel.exit!(1) unless status
    ensure
      start! unless running?
    end
  end

  def self.set_command(options)
    command = [EXEC_PATH, "database", options[:command]]
    options.delete(:command)

    command += [options[:subcommand]] unless options[:subcommand].nil?
    options.delete(:subcommand)

    needs_stop = options[:needs_stop]
    options.delete(:needs_stop)

    needs_read_only = options[:needs_read_only]
    options.delete(:needs_read_only)

    continue?(needs_stop, needs_read_only)

    command += ["-n", options[:limit]] unless options[:limit].nil?
    options.delete(:limit)

    options.each do |_, opt|
      command.append(opt)
    end

    # always set the config file at the end
    command += [CONFIG_PATH]

    command
  end

  def self.log(msg)
    @ctl.log(msg)
  end

  def self.running?
    !GitlabCtl::Util.run_command("gitlab-ctl status #{service_name}").error?
  end

  def self.read_only?
    config = YAML.load_file(CONFIG_PATH)
    config.dig('storage', 'maintenance', 'readonly', 'enabled') == true
  end

  def self.start!
    puts "Starting service #{service_name}"

    @ctl.run_sv_command_for_service('start', service_name)
  end

  def self.stop!
    puts "Stopping service #{service_name}"

    @ctl.run_sv_command_for_service('stop', service_name)
  end

  def self.enabled?
    @ctl.service_enabled?(service_name)
  end

  def self.config?
    File.exist?(@path)
  end

  def self.service_name
    "registry"
  end

  def self.continue?(needs_stop, needs_read_only)
    if needs_stop && running?
      puts 'WARNING: Command cannot run while the container registry is running. ' \
           'Stop the registry before proceeding? (y/n)'.color(:yellow)

      if $stdin.gets.chomp.casecmp('y').zero?
        stop!
      else
        puts "Exiting..."
        exit 1
      end
    end

    return unless running? && needs_read_only && !read_only?

    puts 'Command requires the container registry to be in read-only mode. Exiting...'
    exit 1
  end
end
