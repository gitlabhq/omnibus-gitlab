require 'chef_helper'

describe SidekiqCluster do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  before { allow(Gitlab).to receive(:[]).and_call_original }

  describe 'when queue_groups is passed a string instead of an array' do
    before { stub_gitlab_rb(sidekiq_cluster: { enable: true, queue_groups: 'gitlab_shell' }) }

    it 'casts to an array' do
      expect(chef_run.node['gitlab']['sidekiq-cluster']['queue_groups']).to eql(['gitlab_shell'])
    end
  end

  describe 'when queue_groups not set' do
    before { stub_gitlab_rb(sidekiq_cluster: { enable: true }) }

    it 'throws an error' do
      expect { chef_run }.to raise_error(/The sidekiq_cluster queue_groups must be set/)
    end
  end

  describe 'when sidekiq_cluster is enabled' do
    it 'allows you to set the queue_groups' do
      stub_gitlab_rb(sidekiq_cluster: { enable: true, queue_groups: ['process_commit,post_receive', 'gitlab_shell'] })
      expect(chef_run.node['gitlab']['sidekiq-cluster']['queue_groups']).to eql(['process_commit,post_receive', 'gitlab_shell'])
    end
  end
end
