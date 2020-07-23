require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/geo/replication_toggle_command"

add_command_under_category('geo-replication-pause', 'gitlab-geo', 'Replication Process', 2) do |_cmd_name, *args|
  Geo::ReplicationToggleCommand.new(self, 'pause', ARGV).execute!
end

add_command_under_category('geo-replication-resume', 'gitlab-geo', 'Replication Process', 2) do |_cmd_name, *args|
  Geo::ReplicationToggleCommand.new(self, 'resume', ARGV).execute!
end
