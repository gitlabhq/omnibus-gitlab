require "#{base_path}/embedded/service/omnibus-ctl/lib/postgresql/replication"

add_command_under_category('set-replication-password', 'database', 'Set database replication password', 2) do |_cmd, *args|
  PostgreSQL::Replication.new(self).set_password!
end
