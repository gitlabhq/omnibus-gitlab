require 'optparse'

module Praefect
  EXEC_PATH = '/opt/gitlab/embedded/bin/praefect'.freeze
  DIR_PATH = '/var/opt/gitlab/praefect'.freeze

  USAGE ||= <<~EOS.freeze
    Usage:
      gitlab-ctl praefect command [options]

    COMMANDS:
      Repository/Metadata Health
        remove-repository           Remove repository from Gitaly cluster
        track-repository            Tells Gitaly cluster to track a repository
        list-untracked-repositories Lists repositories that exist on disk but are untracked by Praefect
        list-storages               List virtual storages and their nodes

      Operational Cluster Health
        check                       Runs checks to determine cluster health
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

    praefect_docs_url = 'https://docs.gitlab.com/ee/administration/gitaly/praefect.html'

    options = {}
    commands = {
      'remove-repository' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl praefect remove-repository [options]. See documentation at #{praefect_docs_url}#manually-remove-repositories"

        parse_common_options!(options, opts)
        parse_repository_options!(options, opts)

        opts.on('--apply', 'When --apply is used, the repository will be removed from the database and any gitaly nodes on which they reside.') do |apply|
          options[:apply] = true
        end
      end,

      'track-repository' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl praefect track-repository [options]. See documentation at #{praefect_docs_url}#manually-track-repositories"

        parse_common_options!(options, opts)
        parse_repository_options!(options, opts)

        opts.on('--authoritative-storage STORAGE-NAME', 'The storage to use as the primary for this repository (mandatory for per_repository elector).
                                                        Repository data on this storage will be used to overwrite corresponding repository data on other
                                                        nodes. ') do |authoritative_storage|
          options[:authoritative_storage] = authoritative_storage
        end

        opts.on('--replicate-immediately', "Causes track-repository to replicate the repository to its secondaries immediately. Without this flag,
                                            replication jobs will be added to the queue and replication will eventually be executed through Praefect's
                                            background process.") do
          options[:replicate_immediately] = true
        end
      end,

      'list-untracked-repositories' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl praefect list-untracked-repositories [options]. See documentation at #{praefect_docs_url}#manually-list-untracked-repositories"

        parse_common_options!(options, opts)
      end,

      'check' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl praefect check"

        parse_common_options!(options, opts)
      end,

      'list-storages' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl praefect list-storages [options]. See documentation at #{praefect_docs_url}#list-storages"

        parse_common_options!(options, opts)
        parse_virtual_storage_option!(options, opts)
      end,
    }

    global.order!(args)

    command = args.shift

    # common arguments
    raise OptionParser::ParseError, "Praefect command is not specified." \
      if command.nil? || command.empty?

    raise OptionParser::ParseError, "Unknown Praefect command: #{command}" \
      unless commands.key?(command)

    commands[command].parse!(args)

    # repository arguments
    if ['remove-repository', 'track-repository'].include?(command)
      raise OptionParser::ParseError, "Option --virtual-storage-name must be specified." \
              unless options.key?(:virtual_storage_name)

      raise OptionParser::ParseError, "Option --repository-relative-path must be specified." \
       unless options.key?(:repository_relative_path)
    end

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
  end

  def self.parse_virtual_storage_option!(options, option_parser)
    option_parser.on('--virtual-storage-name NAME', 'Name of the virtual storage where the repository resides (mandatory) The virtual-storage-name can be found in /etc/gitlab/gitlab.rb under praefect["virtual_storages"].
                      If praefect["virtual_storages"] = { "default" => {"nodes" => { ... }},
                      "storage_1" => {"nodes" => { ... }}}, the virtual-storage-name would be either "default", or "storage_1".
                      This can also be found in the Project Detail page in the Admin Panel under "Gitaly storage name".'
    ) do |virtual_storage_name|
      options[:virtual_storage_name] = virtual_storage_name
    end
  end

  def self.parse_repository_options!(options, option_parser)
    parse_virtual_storage_option!(options, option_parser)

    option_parser.on('--repository-relative-path PATH', 'Relative path to the repository on the disk (mandatory).
                      These start with @hashed/..." and can be found in the Project Detail page in the Admin Panel under
                      "Gitaly relative path"'
    ) do |repository_relative_path|
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

    # virtual storage argument
    if ['remove-repository', 'track-repository', 'list-storages'].include?(options[:command]) &&
        options.key?(:virtual_storage_name)
      command += ["-virtual-storage", options[:virtual_storage_name]]
    end

    # repository arguments
    command += ["-repository", options[:repository_relative_path]] if ['remove-repository', 'track-repository'].include?(options[:command])

    # command specific arguments
    if options[:command] == 'track-repository'
      command += ["-authoritative-storage", options[:authoritative_storage]] if options.key?(:authoritative_storage)
      command += ["-replicate-immediately"] if options.key?(:replicate_immediately)
    end

    command += ["-apply"] if options[:command] == 'remove-repository' && options.key?(:apply)

    status = Kernel.system(*command)
    Kernel.exit!(1) unless status
  end
end
