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
        track-repositories          Track multiple repositories as a single batch
        list-untracked-repositories Lists repositories that exist on disk but are untracked by Praefect
        list-storages               List virtual storages and their nodes

      Operational Cluster Health
        check                       Runs checks to determine cluster health
  EOS

  # These are used arguments to track-repository and listed in the description of --input-path on
  # track-repositories, requiring different indentation levels.
  STORAGE_NAME_DESC = <<~EOS.freeze
    The storage to use as the primary for this repository (mandatory for per_repository elector).
    %%Repository data on this storage will be used to overwrite corresponding repository data on other
    %%nodes.
  EOS

  VIRTUAL_STORAGE_DESC = <<~EOS.freeze
    Name of the virtual storage where the repository resides (mandatory).
    %%The virtual-storage-name can be found in /etc/gitlab/gitlab.rb under praefect["virtual_storages"].
    %%If praefect["virtual_storages"] = { "default" => {"nodes" => { ... }},
    %%"storage_1" => {"nodes" => { ... }}}, the virtual-storage-name would be either "default", or "storage_1".
    %%This can also be found in the Project Detail page in the Admin Panel under "Gitaly storage name".'
  EOS

  RELATIVE_PATH_DESC = <<~EOS.freeze
    Relative path to the repository on the disk (mandatory).
    %%These start with @hashed/..." and can be found in the Project Detail page in the Admin Panel under
    %%"Gitaly relative path"'.
  EOS

  SUMMARY_WIDTH = 40
  DESC_INDENT = 45
  LIST_INDENT = 50

  def self.indent(str, len)
    str.gsub(/%%/, ' ' * len)
  end

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
    commands = populate_commands(options)

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

    raise OptionParser::ParseError, "Option --input-path must be specified." \
      if command == 'track-repositories' && !options.key?(:input_path)

    options[:command] = command
    options
  end

  def self.populate_commands(options)
    praefect_docs_url = 'https://docs.gitlab.com/ee/administration/gitaly/recovery.html'

    {
      'remove-repository' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl praefect remove-repository [options]. See documentation at #{praefect_docs_url}#manually-remove-repositories"

        parse_common_options!(options, opts)
        parse_repository_options!(options, opts)
        parse_remove_repository_options!(options, opts)
      end,

      'track-repository' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl praefect track-repository [options]. See documentation at #{praefect_docs_url}#manually-add-a-single-repository-to-the-tracking-database"

        parse_common_options!(options, opts)
        parse_repository_options!(options, opts)

        opts.on('--authoritative-storage STORAGE-NAME', indent(STORAGE_NAME_DESC, DESC_INDENT)) do |authoritative_storage|
          options[:authoritative_storage] = authoritative_storage
        end

        parse_replicate_immediately_option!(options, opts)
      end,

      'track-repositories' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl praefect track-repositories [options]. See documentation at #{praefect_docs_url}#manually-add-many-repositories-to-the-tracking-database"

        parse_common_options!(options, opts)

        opts.on('--input-path INPUT-PATH', "The path the file containing the list of repositories to be tracked. Must contain a newline-delimited list of
                                             JSON objects. Each object must contain the following keys:
                                               - relative_path: #{indent(RELATIVE_PATH_DESC, LIST_INDENT).chop}
                                               - virtual_storage: #{indent(VIRTUAL_STORAGE_DESC, LIST_INDENT).chop}
                                               - authoritative_storage: #{indent(STORAGE_NAME_DESC, LIST_INDENT).chop}") do |input_path|
          options[:input_path] = input_path
        end

        parse_replicate_immediately_option!(options, opts)
      end,

      'list-untracked-repositories' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl praefect list-untracked-repositories [options]. See documentation at #{praefect_docs_url}#list-untracked-repositories"

        parse_common_options!(options, opts)
      end,

      'check' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl praefect check"

        parse_common_options!(options, opts)
      end,

      'list-storages' => OptionParser.new do |opts|
        opts.banner = "Usage: gitlab-ctl praefect list-storages [options]. See documentation at #{praefect_docs_url}#list-virtual-storage-details"

        parse_common_options!(options, opts)
        parse_virtual_storage_option!(options, opts)
      end,
    }
  end

  def self.parse_common_options!(options, option_parser)
    option_parser.on("-h", "--help", "Prints this help") do
      option_parser.set_summary_width(SUMMARY_WIDTH)
      Kernel.puts option_parser
      Kernel.exit 0
    end

    option_parser.on('--dir DIR', 'Directory in which Praefect is installed') do |dir|
      options[:dir] = dir
    end
  end

  def self.parse_virtual_storage_option!(options, option_parser)
    option_parser.on('--virtual-storage-name NAME', indent(VIRTUAL_STORAGE_DESC, DESC_INDENT)) do |virtual_storage_name|
      options[:virtual_storage_name] = virtual_storage_name
    end
  end

  def self.parse_repository_options!(options, option_parser)
    parse_virtual_storage_option!(options, option_parser)

    option_parser.on('--repository-relative-path PATH', indent(RELATIVE_PATH_DESC, DESC_INDENT)) do |repository_relative_path|
      options[:repository_relative_path] = repository_relative_path
    end
  end

  def self.parse_replicate_immediately_option!(options, option_parser)
    option_parser.on('--replicate-immediately', "Causes track-repository to replicate the repository to its secondaries immediately. Without this flag,
                                             replication jobs will be added to the queue and replication will eventually be executed through Praefect's
                                             background process.") do
      options[:replicate_immediately] = true
    end
  end

  # options specific to remove-repository
  def self.parse_remove_repository_options!(options, option_parser)
    option_parser.on('--db-only', 'Remove the repository records from the database only, leaving any the repository on-disk if it exists.') do
      options[:db_only] = true
    end

    option_parser.on('--apply', 'When --apply is used, the repository will be removed from the database and any gitaly nodes on which they reside.') do
      options[:apply] = true
    end
  end

  def self.set_command(options, config_file_path)
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
    command += ["-authoritative-storage", options[:authoritative_storage]] if options[:command] == 'track-repository' && options.key?(:authoritative_storage)

    command += ["-input-path", options[:input_path]] if options[:command] == 'track-repositories' && options.key?(:input_path)

    command += ["-db-only"] if options[:command] == 'remove-repository' && options.key?(:db_only)

    command += ["-apply"] if options[:command] == 'remove-repository' && options.key?(:apply)

    # replication argument
    command += ["-replicate-immediately"] if ['track-repository', 'track-repositories'].include?(options[:command]) && options.key?(:replicate_immediately)

    command
  end

  def self.execute(options)
    config_file_path = File.join(options.fetch(:dir, DIR_PATH), 'config.toml')

    [EXEC_PATH, config_file_path].each do |path|
      next if File.exist?(path)

      Kernel.abort "Could not find '#{path}' file. Is this command being run on a Praefect node?"
    end

    command = set_command(options, config_file_path)

    status = Kernel.system(*command)
    Kernel.exit!(1) unless status
  end
end
