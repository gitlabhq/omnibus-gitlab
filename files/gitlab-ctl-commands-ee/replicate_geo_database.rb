require 'io/console'
require 'optparse'
require 'rainbow/ext/string'

class ReplicateGeoHelpers
  attr_accessor :base_path, :data_path, :tmp_dir, :ctl
  attr_writer :data_dir, :tmp_data_dir

  def initialize(base_path, data_path, instance)
    @base_path = base_path
    @data_path = data_path
    @ctl = instance
  end

  def execute
    if gitlab_is_active?
      if @options[:force]
        puts "Found data inside the #{db_name} database! Proceeding because --force was supplied".color(:yellow)
      else
        puts "Found data inside the #{db_name} database! If you are sure you are in the secondary server, override with --force".color(:red)
        exit 1
      end
    end

    unless ctl.service_enabled?('postgresql')
      puts 'There is no PostgreSQL instance enabled in omnibus, exiting...'.color(:red)
      exit! 1
    end

    puts
    puts '---------------------------------------------------------------'.color(:yellow)
    puts 'WARNING: Make sure this script is run from the secondary server'.color(:yellow)
    puts '---------------------------------------------------------------'.color(:yellow)
    puts
    puts 'This script will disable your local PostgreSQL database, and start '
    puts "a backup/restore from the primary node at '#{@options[:host]}'"
    puts

    unless @options[:now]
      puts '*** You have 30 seconds to hit CTRL-C ***'.color(:yellow)
      puts
      sleep 30
    end

    execute_gitlab_backup!

    puts '* Stopping PostgreSQL and all GitLab services'.color(:green)
    run_command('gitlab-ctl stop')

    puts '* Backing up postgresql.conf'.color(:green)
    run_command("sudo -u gitlab-psql mv #{data_path}/postgresql/data/postgresql.conf #{data_path}/postgresql/")

    bkp_dir = "#{data_path}/postgresql/data.#{Time.now.to_i}"
    puts "* Moving old data directory to '#{bkp_dir}'".color(:green)

    run_command("sudo -u gitlab-psql mv #{data_path}/postgresql/data #{bkp_dir}")
    run_command('rm -f /tmp/postgresql.trigger')

    puts "* Starting base backup as the replicator user (#{@options[:user]})".color(:green)
    @options[:password] = ask_pass("Enter the password for #{@options[:user]}@#{@options[:host]}")
    pgpass = "#{data_path}/postgresql/.pgpass"
    create_pgpass_file!(pgpass)

    run_command("sudo PGPASSFILE=#{pgpass} -u gitlab-psql #{base_path}/embedded/bin/pg_basebackup -h #{@options[:host]} -D #{data_path}/postgresql/data -U #{@options[:user]} -v -x -P", live: true)

    puts '* Writing recovery.conf file'.color(:green)
    create_recovery_file!

    puts '* Restoring postgresql.conf'.color(:green)
    run_command("sudo -u gitlab-psql mv #{data_path}/postgresql/postgresql.conf #{data_path}/postgresql/data/")

    puts '* Starting PostgreSQL and all GitLab services'.color(:green)
    run_command('gitlab-ctl start')
  end

  def parse_options!(args)
    @options = {
      user: 'gitlab_replicator',
      port: 5432,
      host: nil,
      password: nil,
      now: false,
      force: false,
      skip_backup: false
    }

    opts_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: gitlab-ctl replicate-geo-database [options]'

      opts.separator ''
      opts.separator 'Specific options:'

      opts.on('--host=HOST', 'Hostname address of the primary node') do |host|
        @options[:host] = host
      end

      opts.on('--user[=USER]', 'Specify a different replication user') do |user|
        @options[:user] = user
      end

      opts.on('--port[=PORT]', 'Specify a different PostgreSQL port') do |port|
        @options[:port] = port
      end

      opts.on('--no-wait', 'Do not wait before starting the replication process') do
        @options[:now] = true
      end

      opts.on('--force', 'Disable existing database even if instance is not empty') do
        @options[:force] = true
      end

      opts.on('--skip-backup', 'Skip the backup before starting the replication process') do
        @options[:skip_backup] = true
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end

    opts_parser.parse!(args)
    raise OptionParser::MissingArgument.new(:host) unless @options.fetch(:host)
  rescue OptionParser::InvalidOption, OptionParser::MissingArgument
    puts $!.to_s
    puts opts_parser
    exit 1
  end

  private

  def execute_gitlab_backup!
    return if @options[:skip_backup]
    return unless gitlab_bootstrapped? && database_exists? && table_exists?('projects')

    puts '* Executing GitLab backup task to prevent accidental data loss'.color(:green)
    run_command('gitlab-rake gitlab:backup:create')
  end

  def create_pgpass_file!(pgpass)
    File.open(pgpass, 'w', 0600) do |file|
      file.write(<<~EOF
        #{@options[:host]}:#{@options[:port]}:*:#{@options[:user]}:#{@options[:password]}
      EOF
      )
    end
    run_command("sudo chown gitlab-psql #{pgpass}")
  end

  def create_recovery_file!
    recovery_file = "#{data_path}/postgresql/data/recovery.conf"
    File.open(recovery_file, 'w', 0640) do |file|
      file.write(<<~EOF
        standby_mode = 'on'
        primary_conninfo = 'host=#{@options[:host]} port=#{@options[:port]} user=#{@options[:user]} password=#{@options[:password]}'
        trigger_file = '/tmp/postgresql.trigger'
      EOF
      )
    end
    run_command("sudo chown gitlab-psql #{recovery_file}")
  end

  def ask_pass(text)
    STDIN.getpass("#{text}: ")
  end

  def run_command(cmd, live: false)
    status = GitlabCtl::Util.run_command(cmd, live: live)
    if status.error?
      puts status.stdout
      puts status.stderr
      puts "[ERROR] Failed to execute: #{cmd} -- be sure to run this command as root".color(:red)
      puts
      exit 1
    end
  end

  def run_query(query)
    status = GitlabCtl::Util.run_command(
      "#{base_path}/bin/gitlab-psql -d #{db_name} -c '#{query}' -q -t"
    )
    status.error? ? false : status.stdout.strip
  end

  def gitlab_bootstrapped?
    File.exist?("#{data_path}/bootstrapped")
  end

  def database_exists?
    status = GitlabCtl::Util.run_command("#{base_path}/bin/gitlab-psql -d template1 -c 'SELECT datname FROM pg_database' -A | grep -x #{db_name}")
    !status.error?
  end

  def table_exists?(table_name)
    query = "SELECT table_name
               FROM information_schema.tables
              WHERE table_catalog = '#{db_name}'
                AND table_schema='public'"
    status = GitlabCtl::Util.run_command("#{base_path}/bin/gitlab-psql -d #{db_name} -c \"#{query}\" -A | grep -x #{table_name}")
    !status.error?
  end

  def table_empty?(table_name)
    output = run_query('SELECT 1 FROM projects LIMIT 1')
    output == '1' ? false : true
  end

  def gitlab_is_active?
    database_exists? && table_exists?('projects') && !table_empty?('projects')
  end

  def db_name
    'gitlabhq_production'
  end
end

add_command_under_category('replicate-geo-database', 'gitlab-geo', 'Make this node the Geo primary', 2) do |_cmd_name, *args|
  replicate = ReplicateGeoHelpers.new(base_path, data_path, self)
  replicate.parse_options!(ARGV)
  replicate.execute
end
