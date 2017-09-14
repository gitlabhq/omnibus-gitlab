require 'chef/mixins'
require 'erb'

# For testing purposes, if the first path cannot be found load the second
begin
  require_relative '../../omnibus-ctl/lib/gitlab_ctl'
rescue LoadError
  require_relative '../../gitlab-ctl-commands/lib/gitlab_ctl'
end

module Pgbouncer
  class Databases
    attr_accessor :install_path, :databases, :options, :ini_file, :json_file, :template_file, :attributes, :userinfo, :database
    attr_reader :data_path

    def initialize(options, install_path, base_data_path)
      self.data_path = base_data_path
      @attributes = GitlabCtl::Util.get_node_attributes(install_path)
      @install_path = install_path
      @options = options
      @ini_file = options['databases_ini'] || attributes['gitlab']['pgbouncer']['databases_ini']
      @json_file = options['databases_json'] || attributes['gitlab']['pgbouncer']['databases_json']
      @template_file = "#{@install_path}/embedded/cookbooks/gitlab-ee/templates/default/databases.ini.erb"
      @database = if attributes.key?('gitlab')
                    attributes['gitlab']['gitlab-rails']['db_database']
                  else
                    'gitlabhq_production'
                  end
      @databases = update_databases(JSON.parse(File.read(@json_file)))
      @userinfo = GitlabCtl::Util.userinfo(options['host_user']) if options['host_user']
    end

    def update_databases(original)
      if original.empty?
        original = {
          database => {}
        }
      end
      updated = Chef::Mixin::DeepMerge.merge(updated, original)
      original.each do |db, settings|
        updated[db] = ''
        settings['host'] = options['newhost'] if options['newhost']
        settings['port'] = options['port'] if options['port']
        settings['auth_user'] = options['user'] if options['user']
        settings['dbname'] =  options['pg_database'] if options['pg_database']
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
      unless Dir.exist?(full_path)
        raise "The directory #{full_path} does not exist. Please ensure pgbouncer is configured on this node"
      end
      @data_path = full_path
    end

    def render
      ERB.new(database_ini_template).result(binding)
    end

    def write
      File.open(@ini_file, 'w') do |file|
        file.puts render
        file.chown(userinfo.uid, userinfo.gid) if options['host_user']
      end
    end

    def pgbouncer_command(command)
      psql = "#{install_path}/embedded/bin/psql"
      host = options['host'] || attributes['gitlab']['pgbouncer']['listen_addr']
      host = '127.0.0.1' if host.eql?('0.0.0.0')
      port = options['port'] || attributes['gitlab']['pgbouncer']['listen_port']
      GitlabCtl::Util.get_command_output(
        "#{psql} -d pgbouncer -h #{host} -p #{port} -c '#{command}' -U #{options['user']}",
        options['host_user']
      )
    rescue GitlabCtl::Errors::ExecutionError => results
      $stderr.puts "Error running command: #{results}"
      $stderr.puts "ERROR: #{results.stderr}"
      raise
    end

    def reload
      # Attempt to connect to the pgbouncer admin interface and send the RELOAD
      # command. Assumes the current user is in the list of admin-users
      pgbouncer_command('RELOAD')
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
      write
      reload
    end
  end
end
