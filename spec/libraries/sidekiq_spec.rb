require 'chef_helper'
require 'pry'

describe Sidekiq do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  before { allow(Gitlab).to receive(:[]).and_call_original }

  context 'with cluster enabled (default)' do
    it 'disables sidekiq itself and enables sidekiq-cluster with the default sidekiq settings' do
      expect(chef_run.node['gitlab']['sidekiq']['enable']).to be(false)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['enable']).to be(true)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['experimental_queue_selector']).to be(false)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['interval']).to be_nil
      expect(chef_run.node['gitlab']['sidekiq-cluster']['shutdown_timeout']).to eq(25)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['max_concurrency']).to eq(50)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['min_concurrency']).to eq(nil)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['negate']).to be(false)
      expect(chef_run.node['gitlab']['sidekiq-cluster']['queue_groups']).to eq(['*'])
    end

    it 'propagates settings from sidekiq to sidekiq cluster' do
      stub_gitlab_rb(
        {
          sidekiq: {
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
            concurrency: 12,
            min_concurrency: 2
          }
        }
      )

      expect { chef_run }.to raise_error(/Cannot specify `concurrency`/)
    end

    it 'prints a warning if sidekiq-cluster was manually configured' do
      stub_gitlab_rb(
        {
          sidekiq: { enable: false },
          "sidekiq_cluster": {
            enable: true,
            queue_groups: "group"
          }
        }
      )
      allow(LoggingHelper).to receive(:deprecation).and_call_original

      expect(LoggingHelper).to receive(:deprecation).with(a_string_including("Configuring `sidekiq_cluster[*]` directly"))

      chef_run
    end
  end

  it 'warns when trying to run sidekiq directly' do
    stub_gitlab_rb(sidekiq: { cluster: false })
    allow(LoggingHelper).to receive(:deprecation).and_call_original

    expect(LoggingHelper).to receive(:deprecation).with(a_string_matching(/Running Sidekiq directly is deprecated/))

    chef_run
  end

  it 'does not enable cluster when sidekiq was explicitly disabled' do
    stub_gitlab_rb(
      { sidekiq: { enable: false } }
    )

    expect(chef_run.node['gitlab']['sidekiq']['enable']).to eq(false)
    expect(chef_run.node['gitlab']['sidekiq-cluster']['enable']).to eq(false)
  end

  describe 'used with roles' do
    context 'when using a default role' do
      it 'runs a sidekiq service' do
        stub_gitlab_rb(
          external_url: 'https://gitlab.example.com'
        )

        expect(chef_run).not_to include_recipe('gitlab::sidekiq')
        expect(chef_run).to include_recipe('gitlab::sidekiq-cluster')
        expect(chef_run).to enable_sidekiq_service('sidekiq')
        expect(chef_run).not_to enable_sidekiq_service('sidekiq-cluster')
      end
    end

    context 'when using a non-default role' do
      it 'does not run a sidekiq service by default' do
        stub_gitlab_rb(
          roles: ['redis_sentinel_role']
        )
        expect(chef_run).not_to include_recipe('gitlab::sidekiq-cluster')
        expect(chef_run).not_to include_recipe('gitlab::sidekiq')
        expect(chef_run).not_to enable_sidekiq_service('sidekiq')
        expect(chef_run).not_to enable_sidekiq_service('sidekiq-cluster')
      end

      it 'runs a sidekiq service if explicitly enabled' do
        stub_gitlab_rb(
          roles: ['redis_sentinel_role'],
          sidekiq: { enable: true }
        )

        expect(chef_run).not_to include_recipe('gitlab::sidekiq')
        expect(chef_run).to include_recipe('gitlab::sidekiq-cluster')
        expect(chef_run).to enable_sidekiq_service('sidekiq')
      end
    end
  end
end
