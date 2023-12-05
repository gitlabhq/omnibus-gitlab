require 'optparse'

module Import
  CMD_NAME = 'import'.freeze
  SUMMARY_WIDTH = 40
  DESC_INDENT = 45

  def self.indent(str, len)
    str.gsub(/%%/, ' ' * len)
  end

  USAGE = <<~EOS.freeze
  Import filesystem metadata into the database

  See documentation at https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/database-import-tool.md

  Usage:
    gitlab-ctl registry-database import [options]

  Options:
    -B, --common-blobs                Import all blob metadata from common storage
    -c, --row-count                   Count and log number of rows across relevant database tables on (pre)import completion
    -d, --dry-run                     Do not commit changes to the database
    -e, --require-empty-database      Abort import if the database is not empty
    -p, --pre-import                  Import immutable repository-scoped data to speed up a following import
    -r, --all-repositories            Import all repository-scoped data
    -h, --help                        Help for import
    -1, --step-one pre-import         Perform step one of a multi-step import: alias for pre-import
    -2, --step-two all-repositories   Perform step two of a multi-step import: alias for all-repositories
    -3, --step-three common-blobs     Perform step three of a multi-step import: alias for common-blobs
  EOS

  def self.parse_options!(args, parser, options)
    return unless args.include? CMD_NAME

    loop do
      break if args.shift == CMD_NAME
    end

    parser.on('-h', '--help', 'Usage help') do
      parser.set_summary_width(SUMMARY_WIDTH)
      Kernel.puts USAGE
      Kernel.exit 0
    end

    parser.on('-B', '--common-blobs', indent('import all blob metadata from common storage', DESC_INDENT)) do
      options[:common_blobs] = '--common-blobs'
    end

    parser.on('-c', '--row-count', indent('count and log number of rows across relevant database tables on (pre)import completion', DESC_INDENT)) do
      options[:row_count] = '--row-count'
    end

    parser.on('-d', '--dry-run', indent('do not commit changes to the database', DESC_INDENT)) do
      options[:dry_run] = '--dry-run'
    end

    parser.on('-e', '--require-empty-database', indent('abort import if the database is not empty', DESC_INDENT)) do
      options[:empty] = '--require-empty-database'
    end

    parser.on('-p', '--pre-import', indent('import immutable repository-scoped data to speed up a following import', DESC_INDENT)) do
      options[:pre_import] = '--pre-import'
    end

    parser.on('-r', '--all-repositories', indent('import all repository-scoped data', DESC_INDENT)) do
      options[:all_repositories] = '--all-repositories'
      options[:needs_read_only] = true
    end

    parser.on('-1', '--step-one', indent('perform step one of a multi-step import: alias for pre-import', DESC_INDENT)) do
      options[:step_one] = '--step-one'
    end

    parser.on('-2', '--step-two', indent('perform step two of a multi-step import: alias for all-repositories', DESC_INDENT)) do
      options[:step_two] = '--step-two'
      options[:needs_read_only] = true
    end

    parser.on('-3', '--step-three', indent('perform step three of a multi-step import: alias for common-blobs', DESC_INDENT)) do
      options[:step_three] = '--step-three'
    end

    parser.order!(args)

    options
  end
end
