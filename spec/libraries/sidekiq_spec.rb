require 'chef_helper'
require 'pry'

describe Sidekiq do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  before { allow(Gitlab).to receive(:[]).and_call_original }

  context 'when cluster is enabled' do
    before { stub_gitlab_rb({ sidekiq: { cluster: true } }) }

    it 'disables sidekiq itself and enables sidekiq-cluster with the default sidekiq settings' do
      expect(chef_run.node['gitlab']['sidekiq']['enable']).to be(false)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['enable']).to be(true)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['experimental_queue_selector']).to be(false)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['interval']).to be_nil
      expect(chef_run.node['gitlab']['sidekiq-cluster']['max_concurrency']).to eq(nil)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['min_concurrency']).to eq(nil)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['negate']).to be(false)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['queue_groups']).to eq(['*'])
    end

    it 'propagonates settings from sidekiq to sidekiq cluster' do
      stub_gitlab_rb(
        {
          sidekiq: {
            enable: true,
            cluster: true,
            ha: true,
            log_directory: "/hello/world",
            min_concurrency: 7,
            max_concurrency: 12
          }
        }
      )

      expect(chef_run.node['gitlab']['sidekiq-cluster']['log_directory']).to eq('/hello/world')
      expect(chef_run.node['gitlab']['sidekiq-cluster']['ha']).to be(true)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['min_concurrency']).to eq(7)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['max_concurrency']).to eq(12)
    end

    it 'allows setting concurrency using a single `concurrency` setting' do
      stub_gitlab_rb(
        {
          sidekiq: {
            enable: true,
            cluster: true,
            concurrency: 42,
          }
        }
      )

      expect(chef_run.node['gitlab']['sidekiq-cluster']['min_concurrency']).to eq(42)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['max_concurrency']).to eq(42)
    end

    it 'raises an error when configuring both `concurrency` and cluster concurerncy' do
      stub_gitlab_rb(
        {
          sidekiq: {
            enable: true,
            cluster: true,
            concurrency: 12,
            min_concurrency: 2
          }
        }
      )

      expect { chef_run }.to raise_error(/Cannot specify `concurrency`/)
    end

    it 'raises an error if sidekiq-cluster was manually configured' do
      stub_gitlab_rb(
        {
          sidekiq: {
            enable: true,
            cluster: true
          },
          "sidekiq_cluster": {
            enable: true,
            queue_groups: "group"
          }
        }
      )

      expect { chef_run }.to raise_error(/Sidekiq cluster configured/)
    end
  end
end
