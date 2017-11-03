require 'io/console'
require 'rainbow/ext/string'

module Geo
  class Replication
    attr_accessor :base_path, :data_path, :tmp_dir, :ctl
    attr_writer :data_dir, :tmp_data_dir
    attr_reader :options

    def initialize(instance, options)
      @base_path = instance.base_path
      @data_path = instance.data_path
      @ctl = instance
      @options = options
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
        Kernel.exit 1
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

      create_gitlab_backup!

      puts '* Stopping PostgreSQL and all GitLab services'.color(:green)
      run_command('gitlab-ctl stop')

      @options[:password] = ask_pass("Enter the password for #{@options[:user]}@#{@options[:host]}")
      @pgpass = "#{data_path}/postgresql/.pgpass"
      create_pgpass_file!

      check_and_create_replication_slot!

      puts '* Backing up postgresql.conf'.color(:green)
      run_command("mv #{data_path}/postgresql/data/postgresql.conf #{data_path}/postgresql/")

      bkp_dir = "#{data_path}/postgresql/data.#{Time.now.to_i}"
      puts "* Moving old data directory to '#{bkp_dir}'".color(:green)

      run_command("mv #{data_path}/postgresql/data #{bkp_dir}")
      run_command('rm -f /tmp/postgresql.trigger')

      puts "* Starting base backup as the replicator user (#{@options[:user]})".color(:green)
      run_command("PGPASSFILE=#{@pgpass} #{base_path}/embedded/bin/pg_basebackup -h #{@options[:host]} -p #{@options[:port]} -D #{data_path}/postgresql/data -U #{@options[:user]} -v -x -P", live: true, timeout: @options[:backup_timeout])

      puts '* Writing recovery.conf file'.color(:green)
      create_recovery_file!

      puts '* Restoring postgresql.conf'.color(:green)
      run_command("mv #{data_path}/postgresql/postgresql.conf #{data_path}/postgresql/data/")

      puts '* Setting ownership permissions in PostgreSQL data directory'.color(:green)
      run_command("chown -R gitlab-psql:gitlab-psql #{data_path}/postgresql/data")

      puts '* Starting PostgreSQL and all GitLab services'.color(:green)
      run_command('gitlab-ctl start')
    end

    def check_and_create_replication_slot!
      return if @options[:skip_replication_slot]

      puts "* Checking for replication slot #{@options[:slot_name]}".color(:green)
      unless replication_slot_exists?
        puts "* Creating replication slot #{@options[:slot_name]}".color(:green)
        create_replication_slot!
      end
    end

    private

    def create_gitlab_backup!
      return if @options[:skip_backup]
      return unless gitlab_bootstrapped? && database_exists? && table_exists?('projects')

      puts '* Executing GitLab backup task to prevent accidental data loss'.color(:green)
      run_command('gitlab-rake gitlab:backup:create')
    end

    def create_pgpass_file!
      File.open(@pgpass, 'w', 0600) do |file|
        file.write(<<~EOF
          #{@options[:host]}:#{@options[:port]}:*:#{@options[:user]}:#{@options[:password]}
        EOF
        )
      end
      run_command("chown gitlab-psql #{@pgpass}")
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
        file.write("primary_slot_name = '#{@options[:slot_name]}'\n") if @options[:slot_name]
      end
      run_command("chown gitlab-psql #{recovery_file}")
    end

    def ask_pass(text)
      if STDIN.tty?
        STDIN.getpass("#{text}: ")
      else
        STDIN.gets
      end
    end

    def replication_slot_exists?
      status = run_psql_command("SELECT slot_name FROM pg_replication_slots WHERE slot_name = '#{@options[:slot_name]}';")
      status.stdout.include?(@options[:slot_name])
    end

    def create_replication_slot!
      status = run_psql_command("SELECT slot_name FROM pg_create_physical_replication_slot('#{@options[:slot_name]}');")
      status.stdout.include?(@options[:slot_name])
    end

    def run_psql_command(query)
      cmd = %(PGPASSFILE=#{@pgpass} #{base_path}/bin/gitlab-psql -h #{@options[:host]} -U #{@options[:user]} -d #{db_name} -t -c "#{query}")
      run_command(cmd, live: false)
    end

    def run_command(cmd, live: false, timeout: nil)
      status = GitlabCtl::Util.run_command(cmd, live: live, timeout: timeout)
      if status.error?
        puts status.stdout
        puts status.stderr
        puts "[ERROR] Failed to execute: #{cmd} -- be sure to run this command as root".color(:red)
        puts
        exit 1
      end

      status
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
end
