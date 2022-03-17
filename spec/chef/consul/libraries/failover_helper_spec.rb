require 'chef_helper'

require 'json'
require 'logger'

NodeData = Struct.new('NodeData', :name, :address, :leader?)

RSpec.describe FailoverHelper::SplitBrain do
  let(:node_list) { %w(cats kittens) }

  context 'when passed a list of nodes' do
    it 'sets primary_nodes to that list' do
      brain = FailoverHelper::SplitBrain.new("Nobody here but us felines", node_list)
      expect(brain.primary_nodes).to match_array(node_list)
    end
  end
end

RSpec.describe FailoverHelper::LeaderFinder do
  let(:total_nodes) { 3 }
  let(:failover) { FailoverHelper::LeaderFinder.new("{}", service_data) }
  let(:primary_node) { NodeData.new("example_primary_node", "10.0.0.42", true) }
  let(:splitbrain_primary_node) { NodeData.new("example_splitbrain_node", "10.0.0.41", true) }
  let(:follower_node_01) { NodeData.new("example_node_02", "10.0.0.43", false) }
  let(:follower_node_02) { NodeData.new("example_node_03", "10.0.0.44", false) }

  def service_data
    service_data = FailoverHelper::ServiceData.new
    service_data.service_name = "example_service"
    service_data.check_field = "Status"
    service_data.leader_value = "passing"

    service_data
  end

  def generate_parsed_data(unhealthy_primary: false, multiple_primaries: false)
    parsed_data = []
    nodes = [primary_node, follower_node_01, follower_node_02]

    nodes.push(splitbrain_primary_node) if multiple_primaries

    nodes.each do |node|
      if node.leader?
        leader_status = "passing"
        health = unhealthy_primary ? "failing" : "passing"
      else
        leader_status = "warning"
        health = "passing"
      end

      node_info = {
        "Node" => {
          "Node" => node.name,
          "Address" => node.address
        },
        "Checks" => [
          {
            "Node" => node.name,
            "CheckID" => "serfHealth",
            "Status" => health
          },
          {
            "Node" => node.name,
            "CheckID" => "example_service",
            "Status" => leader_status
          }
        ]
      }

      parsed_data.push(node_info)
    end

    parsed_data
  end

  def stub_healthy_primary_watcher_data
    parsed_data = generate_parsed_data

    allow_any_instance_of(FailoverHelper::LeaderFinder).to receive(:parse).and_return(parsed_data)
  end

  def stub_unhealthy_primary_watcher_data
    parsed_data = generate_parsed_data(unhealthy_primary: true)

    allow_any_instance_of(FailoverHelper::LeaderFinder).to receive(:parse).and_return(parsed_data)
  end

  def stub_multiple_primary_nodes_watcher_data
    parsed_data = generate_parsed_data(multiple_primaries: true)

    allow_any_instance_of(FailoverHelper::LeaderFinder).to receive(:parse).and_return(parsed_data)
  end

  describe "#parse" do
    let(:bad_json) { "Nobody here but us errors!" }

    context 'when passed invalid JSON data' do
      it 'throws a JSON::Parser error' do
        expect { FailoverHelper::LeaderFinder.new(bad_json, service_data) }.to raise_error(JSON::ParserError)
      end
    end
  end

  context 'when valid JSON is received from watch' do
    context 'when there is more than one primary node found' do
      before do
        stub_multiple_primary_nodes_watcher_data
      end

      describe "#primary_node" do
        it 'throws a SplitBrain error' do
          expect { failover.primary_node }.to raise_error(FailoverHelper::SplitBrain, "Split brain detected, multiple primary nodes found!")
        end
      end
    end

    context 'when all nodes are healthy' do
      before do
        stub_healthy_primary_watcher_data
      end

      describe "#healthy_nodes" do
        it 'returns the correct number of healthy nodes' do
          expect(failover.healthy_nodes.length).to eq(total_nodes)
        end
      end

      describe "#leader_nodes" do
        context 'when there is one leader' do
          it 'returns only one leader' do
            expect(failover.leader_nodes.length).to eq(1)
          end

          it 'returns the correct node' do
            primary_node = failover.leader_nodes.first
            expect(primary_node.name).to eq(primary_node.name)
          end
        end
      end

      describe "#primary_node_address" do
        context 'when the node name resolves via DNS' do
          it 'returns the machine name' do
            allow_any_instance_of(Resolv::DNS).to receive(:getaddress).and_return(true)
            expect(failover.primary_node_address).to eq(primary_node.name)
          end
        end

        context 'when the node name does not resolve via DNS' do
          it 'returns the machine IP address' do
            allow_any_instance_of(Resolv::DNS).to receive(:getaddress).and_raise(Resolv::ResolvError)
            expect(failover.primary_node_address).to eq(primary_node.address)
          end
        end
      end
    end

    context 'when the primary node is not healthy in a single cluster setup' do
      before do
        stub_unhealthy_primary_watcher_data
      end

      describe "#healthy_nodes" do
        it 'returns the correct number of healthy nodes' do
          expect(failover.healthy_nodes.length).to eq(total_nodes - 1)
        end
      end

      describe "#leader_nodes" do
        it 'throws a PrimaryMissing exception' do
          expect { failover.leader_nodes }.to raise_error(FailoverHelper::PrimaryMissing, "No healthy primary node found.")
        end
      end
    end
  end
end
