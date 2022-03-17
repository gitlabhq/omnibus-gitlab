# ingests and serializes data from consul to determine whether or not a
# failover action should be performed

require 'json'
require 'resolv'

module FailoverHelper
  class PrimaryMissing < StandardError
    def initialize(msg = "No healthy primary node found.")
      super
    end
  end

  class SplitBrain < StandardError
    attr_reader :primary_nodes

    def initialize(msg = "Split brain detected, multiple primary nodes found!", primary_nodes = [])
      @primary_nodes = primary_nodes
      super(msg)
    end
  end

  ServiceData = Struct.new('ServiceData', :service_name, :check_field, :leader_value)

  class LeaderFinder
    NodeInfo = Struct.new('NodeInfo', :name, :address, :leader, :healthy)

    def initialize(watcher_json, service_data)
      @service_data = service_data
      watcher_data = parse(watcher_json)
      @data = ingest(watcher_data)
    end

    def parse(watcher_data)
      JSON.parse(watcher_data)
    end

    def ingest(watcher_data)
      data = []

      watcher_data.each do |node|
        node_info = NodeInfo.new
        node_info.name = node['Node']['Node']
        node_info.address = node['Node']['Address']
        health_check = node['Checks'].find do |check|
          check['CheckID'] == 'serfHealth'
        end

        node_info.healthy = (health_check['Status'] == 'passing')

        leader_check = node['Checks'].find do |check|
          check['CheckID'] == @service_data.service_name
        end

        node_info.leader = (leader_check[@service_data.check_field] == @service_data.leader_value)

        data.push(node_info)
      end

      data
    end

    def healthy_nodes
      @data.select(&:healthy)
    end

    def leader_nodes
      leader_nodes = healthy_nodes.select(&:leader)

      raise PrimaryMissing unless leader_nodes.length.positive?

      leader_nodes
    end

    # primary and standby clusters each have a leader. this is correct for
    # the current use case and maintains a stable API if multiple cluster
    # support is ever added
    def primary_node
      raise SplitBrain.new("Split brain detected, multiple primary nodes found!", leader_nodes) if leader_nodes.length > 1

      leader_nodes.first
    end

    def primary_node_address
      begin
        Resolv::DNS.new.getaddress(primary_node.name)
        address = primary_node.name
      rescue Resolv::ResolvError
        address = primary_node.address
      end

      address
    end
  end
end
