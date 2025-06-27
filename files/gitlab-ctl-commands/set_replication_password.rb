require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl/postgresql/replication"

add_command_under_category('set-replication-password', 'database', 'Set database replication password', 2) do |_cmd, *args|
  GitlabCtl::PostgreSQL::Replication.new(self).set_password!
end
