require 'optparse'

module Praefect
  EXEC_PATH = '/opt/gitlab/embedded/bin/praefect'.freeze
  DIR_PATH = '/var/opt/gitlab/praefect'.freeze

  USAGE ||= <<~EOS.freeze
    Usage:
      gitlab-ctl praefect command [options]

    COMMANDS:
      remove-repository     Remove repository from Gitaly cluster
      track-repository      Tells Gitaly cluster to track a repository
  EOS

  def self.parse_options!(args)
    loop do
      break if args.shift == 'praefect'
    end

    global = OptionParser.new do |opts|
      opts.on('-h', '--help', 'Usage help') do
        Kernel.puts USAGE
        Kernel.exit 0
      end
    end

    options = {}
    commands = {
      'remove-repository' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl praefect remove-repository [options]"

        parse_common_options!(options, opts)
      end,

      'track-repository' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl praefect track-repository [options]"

        parse_common_options!(options, opts)

        opts.on('--authoritative-storage STORAGE-NAME', 'The storage to use as the primary for this repository (optional)') do |authoritative_storage|
          options[:authoritative_storage] = authoritative_storage
        end
      end
    }

    global.order!(args)

    command = args.shift

    raise OptionParser::ParseError, "Praefect command is not specified." \
      if command.nil? || command.empty?

    raise OptionParser::ParseError, "Unknown Praefect command: #{command}" \
      unless commands.key?(command)

    commands[command].parse!(args)

    # common arguments
    raise OptionParser::ParseError, "Option --virtual-storage-name must be specified" \
      unless options.key?(:virtual_storage_name)

    raise OptionParser::ParseError, "Option --repository-relative-path must be specified" \
      unless options.key?(:repository_relative_path)

    options[:command] = command
    options
  end

  def self.parse_common_options!(options, option_parser)
    option_parser.on("-h", "--help", "Prints this help") do
      Kernel.puts option_parser
      Kernel.exit 0
    end

    option_parser.on('--dir DIR', 'Directory in which Praefect is installed') do |dir|
      options[:dir] = dir
    end

    option_parser.on('--virtual-storage-name NAME', 'Name of the virtual storage where the repository resides (mandatory)') do |virtual_storage_name|
      options[:virtual_storage_name] = virtual_storage_name
    end

    option_parser.on('--repository-relative-path PATH', 'Relative path to the repository on the disk (mandatory)') do |repository_relative_path|
      options[:repository_relative_path] = repository_relative_path
    end
  end

  def self.execute(options)
    config_file_path = File.join(options.fetch(:dir, DIR_PATH), 'config.toml')

    [EXEC_PATH, config_file_path].each do |path|
      next if File.exist?(path)

      Kernel.abort "Could not find '#{path}' file. Is this command being run on a Praefect node?"
    end

    # common arguments
    command = [EXEC_PATH, "-config", config_file_path, options[:command]]
    command += ["-virtual-storage", options[:virtual_storage_name]]
    command += ["-repository", options[:repository_relative_path]]

    # command specific arguments
    command += ["-authoritative-storage", options[:authoritative_storage]] if options[:command] == 'track-repository' && options.key?(:authoritative_storage)

    status = Kernel.system(*command)
    Kernel.exit!(1) unless status
  end
end
