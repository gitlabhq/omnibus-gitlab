require_relative 'shell_out_helper'

# This is a base class to be inherited by PG Helpers
class BasePgHelper
  include ShellOutHelper
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def is_running?
    OmnibusHelper.new(node).service_up?(service_name)
  end

  def database_exists?(db_name)
    psql_cmd(["-d 'template1'",
      "-c 'select datname from pg_database' -A",
      "| grep -x #{db_name}"])
  end

  def extension_exists?(extension_name)
    psql_cmd(["-d 'template1'",
      "-c 'select name from pg_available_extensions' -A",
      "| grep -x #{extension_name}"])
  end

  def extension_enabled?(extension_name, db_name)
    psql_cmd(["-d '#{db_name}'",
      "-c 'select extname from pg_extension' -A",
      "| grep -x #{extension_name}"])
  end

  def user_exists?(db_user)
    psql_cmd(["-d 'template1'",
      "-c 'select usename from pg_user' -A",
      "|grep -x #{db_user}"])
  end

  def is_slave?
    psql_cmd(["-d 'template1'",
      "-c 'select pg_is_in_recovery()' -A",
      "|grep -x t"])
  end

  def bootstrapped?
    File.exists?(File.join(node['gitlab'][service_name]['data_dir'], 'PG_VERSION'))
  end

  def psql_cmd(cmd_list)
    cmd = ["/opt/gitlab/bin/#{service_cmd}", cmd_list.join(' ')].join(' ')
    success?(cmd)
  end

  def version
    VersionHelper.version('/opt/gitlab/embedded/bin/psql --version').split.last
  end

  def database_version
    version_file = "#{@node['gitlab'][service_name]['data_dir']}/PG_VERSION"
    if File.exist?(version_file)
      File.read(version_file).chomp
    else
      nil
    end
  end

  protected

  def service_name
    raise NotImplementedError
  end

  def service_cmd
    raise NotImplementedError
  end
end
