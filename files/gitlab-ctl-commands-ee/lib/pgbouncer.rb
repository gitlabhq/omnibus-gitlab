require 'chef/mixins'
require 'erb'

# For testing purposes, if the first path cannot be found load the second
begin
  require_relative '../../omnibus-ctl/lib/gitlab_ctl'
rescue LoadError
  require_relative '../../gitlab-ctl-commands/lib/gitlab_ctl'
end

module Pgbouncer
  DEFAULT_RAILS_DATABASE = 'gitlabhq_production'.freeze

  class Databases
    attr_accessor :install_path, :databases, :options, :ini_file, :json_file, :template_file, :attributes, :userinfo, :groupinfo, :database
    attr_reader :data_path

    def self.rails_database(attributes: nil)
      attributes = GitlabCtl::Util.get_public_node_attributes if attributes.nil?

      if attributes.key?('gitlab')
        attributes.dig('gitlab', 'gitlab_rails', 'db_database') || attributes.dig('gitlab', 'gitlab-rails', 'db_database')
      else
        DEFAULT_RAILS_DATABASE
      end
    end

    def initialize(options, install_path, base_data_path)
      self.data_path = base_data_path
      @attributes = GitlabCtl::Util.get_public_node_attributes
      @install_path = install_path
      @options = options
      @ini_file = options['databases_ini'] || database_ini
      @json_file = options['databases_json'] || database_json
      @template_file = "#{@install_path}/embedded/cookbooks/gitlab-ee/templates/default/databases.ini.erb"
      @database = options['database'] || Databases.rails_database(attributes: @attributes)
      @databases = update_databases(JSON.parse(File.read(@json_file))) if File.exist?(@json_file)
      @userinfo = GitlabCtl::Util.userinfo(options['host_user']) if options['host_user']
      @groupinfo = GitlabCtl::Util.groupinfo(options['host_group']) if options['host_group']
    end

    def update_databases(original = {})
      updated = {}

      if original.empty?
        original = {
          database => {}
        }
      end

      original.each do |db, settings|
        settings.delete('password')

        updated[db] = ''

        settings['auth_user'] = settings.delete('user') if settings.key?('user')

        if db == @database
          settings['host'] = options['newhost'] if options['newhost']
          settings['port'] = options['port'] if options['port']
          settings['auth_user'] = options['user'] if options['user']
          settings['dbname'] = options['pg_database'] if options['pg_database']
        end

        settings.each do |setting, value|
          updated[db] << " #{setting}=#{value}"
        end

        updated[db].strip!
      end

      updated
    end

    def database_ini_template
      <<~EOF
        [databases]
        <% @databases.each do |db, settings| %>
        <%= db %> = <%= settings %>
        <% end %>
      EOF
    end

    def data_path=(path)
      full_path = "#{path}/pgbouncer"
      raise "The directory #{full_path} does not exist. Please ensure pgbouncer is configured on this node" unless Dir.exist?(full_path)

      @data_path = full_path
    end

    def render
      ERB.new(database_ini_template).result(binding)
    end

    def write
      File.open(@ini_file, 'w') do |file|
        file.puts render
        file.chown(userinfo.uid, groupinfo.gid) if options['host_user'] && options['host_group']
      end
    end

    def build_command_line
      psql = "#{install_path}/embedded/bin/psql"
      host = options['pg_host'] || listen_addr
      host = '127.0.0.1' if host.eql?('0.0.0.0')
      port = options['pg_port'] || listen_port
      "#{psql} -d pgbouncer -h #{host} -p #{port} -U #{options['user']}"
    end

    def pgbouncer_command(command)
      GitlabCtl::Util.get_command_output(
        "#{build_command_line} -c '#{command}'",
        options['host_user']
      )
    rescue GitlabCtl::Errors::ExecutionError => e
      $stderr.puts "Error running command: #{e}"
      $stderr.puts "ERROR: #{e.stderr}"
      raise
    end

    def show_databases
      pgbouncer_command('SHOW DATABASES')
    end

    def running?
      true if show_databases
    rescue GitlabCtl::Errors::ExecutionError
      false
    end

    def database_paused?
      return false unless running?

      databases = show_databases

      # Find the headings of the output from `SHOW DATABASES` to find out the location of the `paused` column
      headings = databases.lines.first.split("|").map(&:strip)
      paused_position = headings.index('paused')

      # Find the paused value of the specified database
      paused_status = databases.lines.find { |x| x.match(/#{@database}/) }.split('|')[paused_position].strip

      # 1 for paused and 0 for unpaused
      paused_status == "1"
    end

    def resume_if_paused
      pgbouncer_command("RESUME #{@database}") if database_paused?
    end

    def reload
      # Attempt to connect to the pgbouncer admin interface and send the RELOAD
      # command. Assumes the current user is in the list of admin-users
      pgbouncer_command('RELOAD')
    rescue GitlabCtl::Errors::ExecutionError
      $stderr.puts "There was an issue reloading pgbouncer through admin console"
      $stderr.puts "Check that gitlab-ctl write-pgpass has been run to populate ~/.pgpass for the Consul account."
      $stderr.puts "See https://docs.gitlab.com/ee/administration/postgresql/replication_and_failover.html#configure-pgbouncer-nodes"
    end

    def restart
      GitlabCtl::Util.get_command_output("gitlab-ctl restart pgbouncer")
    end

    def suspend
      pgbouncer_command('SUSPEND')
    end

    def resume
      pgbouncer_command('RESUME')
    end

    def kill
      pgbouncer_command("KILL #{options['pg_database']}")
    end

    def notify
      # If we haven't written databases.json yet, don't do anything
      return if databases.nil?

      write
      resume_if_paused
      begin
        reload
      rescue GitlabCtl::Errors::ExecutionError
        $stderr.puts "Unable to reload pgbouncer, restarting instead"
        restart
      end
    end

    def console
      exec(build_command_line)
    end

    private

    def database_ini
      attributes['pgbouncer']['databases_ini']
    end

    def database_json
      attributes['pgbouncer']['databases_json']
    end

    def listen_addr
      attributes['pgbouncer']['listen_addr']
    end

    def listen_port
      attributes['pgbouncer']['listen_port']
    end
  end
end
