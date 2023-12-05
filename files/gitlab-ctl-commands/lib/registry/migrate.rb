require 'optparse'

module Migrate
  CMD_NAME = 'migrate'.freeze
  SUMMARY_WIDTH = 40
  DESC_INDENT = 45

  def self.indent(str, len)
    str.gsub(/%%/, ' ' * len)
  end

  USAGE ||= <<~EOS.freeze
  Manage migrations

  Usage:
    gitlab-ctl registry-database migrate SUBCOMMAND [options]

  Subcommands:
    down        Apply down migrations
    status      Show migration status
    up          Apply up migrations
    version     Show current migration version

  Options:
    -h, --help   help for migrate
  EOS

  UP_USAGE ||= <<~EOS.freeze
  Apply up migrations

  Usage:
    gitlab-ctl registry-database migrate up [options]

  Options:
    -d, --dry-run                do not commit changes to the database
    -h, --help                   help for up
    -l, --limit int              limit the number of migrations (all by default)
    -s, --skip-post-deployment   do not apply post deployment migrations
  EOS

  DOWN_USAGE ||= <<~EOS.freeze
  Apply down migrations

  Usage:
    gitlab-ctl registry-database migrate down [options]

  Options:
    -d, --dry-run     do not commit changes to the database
    -f, --force       no confirmation message
    -h, --help        help for down
    -l, --limit int   limit the number of migrations (all by default)
  EOS

  STATUS_USAGE ||= <<~EOS.freeze
  Show migration status

  Usage:
    gitlab-ctl registry-database migrate status [options]

  Options:
    -h, --help                   help for status
    -s, --skip-post-deployment   ignore post deployment migrations
    -u, --up-to-date             check if all known migrations are applied

  EOS

  VERSION_USAGE ||= <<~EOS.freeze
  Show current migration version

  Usage:
    gitlab-ctl registry-database migrate version [options]

  Flags:
    -h, --help   help for version
  EOS

  def self.parse_options!(args, options)
    return unless args.include? CMD_NAME

    loop do
      break if args.shift == CMD_NAME
    end

    OptionParser.new do |opts|
      opts.on('-h', '--help', 'Usage help') do
        Kernel.puts USAGE
        Kernel.exit 0
      end
    end.order! args

    subcommands = populate_subcommands(options)
    subcommand = args.shift

    raise OptionParser::ParseError, "migrate subcommand is not specified." \
      if subcommand.nil? || subcommand.empty?

    raise OptionParser::ParseError, "Unknown migrate subcommand: #{subcommand}" \
      unless subcommands.key?(subcommand)

    subcommands[subcommand].parse!(args)
    options[:subcommand] = subcommand
    needs_stop!(options)

    options
  end

  def self.populate_subcommands(options)
    database_docs_url = 'https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/database-migrations.md#administration'

    {
      'up' => OptionParser.new do |opts|
        opts.banner = "Usage gitlab-ctl registry-database migrate up [options]. See documentation at #{database_docs_url}"
        parse_common_options!(opts)
        parse_up_down_common_options!(options, opts)
        parse_up_options!(options, opts)
      end,
      'down' => OptionParser.new do |opts|
        opts.banner = "Usage gitlab-ctl registry-database migrate down [options]. See documentation at #{database_docs_url}"
        parse_common_options!(opts)
        parse_up_down_common_options!(options, opts)
        parse_down_options!(options, opts)
      end,
      'status' => OptionParser.new do |opts|
        opts.banner = "Usage gitlab-ctl registry-database migrate status [options]. See documentation at #{database_docs_url}"
        parse_common_options!(opts)
        parse_status_options!(options, opts)
      end,
      'version' => OptionParser.new do |opts|
        opts.banner = "Usage gitlab-ctl registry-database migrate version [options]. See documentation at #{database_docs_url}"
        opts.on('-h', '--help', 'Usage help') do
          Kernel.puts VERSION_USAGE
          Kernel.exit 0
        end

        parse_common_options!(opts)
      end,
    }
  end

  def self.parse_common_options!(option_parser)
    option_parser.on("-h", "--help", "Prints this help") do
      option_parser.set_summary_width(SUMMARY_WIDTH)
      Kernel.puts USAGE
      Kernel.exit 0
    end
  end

  def self.parse_up_down_common_options!(options, option_parser)
    option_parser.on('-d', '--dry-run', indent('do not commit changes to the database', DESC_INDENT)) do
      options[:dry_run] = '-d'
    end

    option_parser.on('-l limit', '--limit LIMIT', indent('limit the number of migrations (all by default)', DESC_INDENT)) do |limit|
      raise OptionParser::ParseError, "--limit option must be a positive number" \
        if limit.nil? || limit.to_i <= 0

      options[:limit] = limit
    end
  end

  def self.parse_up_options!(options, option_parser)
    option_parser.on('-h', '--help', 'Usage help') do
      Kernel.puts UP_USAGE
      Kernel.exit 0
    end

    option_parser.on('-s', '--skip-post-deployment', indent('do not apply post deployment migration', DESC_INDENT)) do
      options[:skip_post_deploy] = '-s'
    end
  end

  def self.parse_down_options!(options, option_parser)
    option_parser.on('-h', '--help', 'Usage help') do
      Kernel.puts DOWN_USAGE
      Kernel.exit 0
    end

    option_parser.on('-f', '--force', indent('no confirmation message', DESC_INDENT)) do
      options[:force] = '-f'
    end
  end

  def self.parse_status_options!(options, option_parser)
    option_parser.on('-h', '--help', 'Usage help') do
      Kernel.puts STATUS_USAGE
      Kernel.exit 0
    end

    option_parser.on('-u', '--up-to-date', indent('do not commit changes to the database', DESC_INDENT)) do
      options[:up_to_date] = '-u'
    end

    option_parser.on('-s', '--skip-post-deployment', indent('do not apply post deployment migration', DESC_INDENT)) do
      options[:skip_post_deploy] = '-s'
    end
  end

  def self.needs_stop!(options)
    case options[:subcommand]
    when 'up', 'down'
      options[:needs_stop] = true unless options.has_key? :dry_run
    else
      options[:needs_stop] = false
    end
  end
end
