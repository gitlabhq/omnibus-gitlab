require "gitlab_ctl/geo/replication_toggle_command"

add_command_under_category('geo-replication-pause', 'gitlab-geo', 'Replication Process', 2) do |_cmd_name, *args|
  GitlabCtl::Geo::ReplicationToggleCommand.new(self, 'pause', ARGV).execute!
end

add_command_under_category('geo-replication-resume', 'gitlab-geo', 'Replication Process', 2) do |_cmd_name, *args|
  GitlabCtl::Geo::ReplicationToggleCommand.new(self, 'resume', ARGV).execute!
end
