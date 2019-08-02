require "#{base_path}/embedded/service/omnibus-ctl-ee/lib/repmgr"
require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl"

add_command_under_category('repmgr', 'database', 'Manage repmgr PostgreSQL cluster nodes', 2) do |_cmd_name, _args|
  repmgr_command = ARGV[3]
  repmgr_subcommand = ARGV[4]
  repmgr_primary = ARGV[5]
  begin
    node_attributes = GitlabCtl::Util.get_public_node_attributes
  rescue GitlabCtl::Errors::NodeError => e
    log e.message
  end
  # We only need the arguments if we're performing an action which needs to
  # know the primary node
  repmgr_options = Repmgr.parse_options(ARGV)

  # We still need to support legacy attributes starting with `gitlab`, as they might exists before running
  # configure on an existing installation
  #
  # TODO: Remove support for legacy attributes in GitLab 13.0
  postgresql_directory = node_attributes.dig('gitlab', 'postgresql', 'data_dir') ||
    node_attributes.dig('postgresql', 'data_dir')

  repmgr_args = begin
                  {
                    primary: repmgr_primary,
                    user: repmgr_options[:user] || node_attributes['repmgr']['username'],
                    database: node_attributes['repmgr']['database'],
                    directory: postgresql_directory,
                    verbose: repmgr_options[:verbose],
                    wait: repmgr_options[:wait],
                    host: repmgr_options[:host],
                    node: repmgr_options[:node]
                  }
                rescue NoMethodError
                  $stderr.puts "Unable to determine node attributes. Has reconfigure successfully ran?"
                  exit 1
                end
  begin
    repmgr_obj = Repmgr.new(repmgr_command, repmgr_subcommand, repmgr_args)
    results = repmgr_obj.execute
  rescue Mixlib::ShellOut::ShellCommandFailed
    exit 1
  rescue NoMethodError
    $stderr.puts "The repmgr command #{repmgr_command} does not support #{repmgr_subcommand}" if repmgr_command
    puts repmgr_help
    exit 1
  rescue NameError => e
    puts e
    $stderr.puts "There is no repmgr command #{repmgr_command}"
    puts repmgr_help
    exit 1
  end
  log results
end

add_command_under_category('repmgr-check-master', 'database', 'Check if the current node is the repmgr master', 2) do
  node = Repmgr::Node.new
  begin
    if node.is_master?
      Kernel.exit 0
    else
      Kernel.exit 1
    end
  rescue Repmgr::MasterError => e
    $stderr.puts "Error checking for master: #{e}"
    Kernel.exit 3
  end
end

add_command_under_category('repmgr-event-handler', 'database', 'Handle events from rpmgrd actions', 2) do
  Repmgr::Events.fire(ARGV)
end

def repmgr_help
  <<-EOF
  Available repmgr commands:
  master register -- Register the current node as a master node in the repmgr cluster
  standby
    clone MASTER -- Clone the data from node MASTER to set this node up as a standby server
    register -- Register the node as a standby node in the cluster. Assumes clone has been done
    setup MASTER -- Performs all steps necessary to setup the current node as a standby for MASTER
    follow MASTER -- Follow the new master node MASTER
    unregister --node=X -- Removes the node with id X from the cluster. Without --node removes the current node.
    promote -- Promote the current node to be the master node
  cluster show -- Displays the current membership status of the cluster
  EOF
end
