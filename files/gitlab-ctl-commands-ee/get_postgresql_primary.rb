require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl/util"
require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/postgresql_ee"

add_command_under_category 'get-postgresql-primary', 'database',
                           'Get connection details to the PostgreSQL primary', 2 do

  node_attributes = GitlabCtl::Util.get_node_attributes
  pg = GitlabCtl::PostgreSQL.new(node_attributes)
  begin
    pg.get_primary.each do |entry|
      log entry
    end
  rescue StandardError => e
    warn e
    Kernel.exit 1
  end
end
