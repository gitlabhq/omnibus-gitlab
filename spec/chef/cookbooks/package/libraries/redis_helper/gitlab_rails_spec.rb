require 'chef_helper'

RSpec.describe RedisHelper::GitlabRails do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default') }

  subject { described_class.new(chef_run.node) }

  describe '#validate_instance_shard_config' do
    before { allow(Gitlab).to receive(:[]).and_call_original }

    context 'with both sentinels and cluster declared' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_cache_sentinels: [
              { 'host' => 'sentinel1.example.com', 'port' => '12345' },
              { 'host' => 'sentinel2.example.com', 'port' => '12345' }
            ],
            redis_cache_cluster_nodes: [
              { 'host' => 'cluster1.example.com', 'port' => '12345' },
              { 'host' => 'cluster1.example.com', 'port' => '12345' }
            ]
          }
        )
      end

      it 'raises error' do
        expect { subject.validate_instance_shard_config('cache') }.to raise_error(RuntimeError)
      end
    end

    context 'with only sentinels declared' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_cache_sentinels: [
              { 'host' => 'sentinel1.example.com', 'port' => '12345' },
              { 'host' => 'sentinel2.example.com', 'port' => '12345' }
            ]
          }
        )
      end

      it 'does not raise error' do
        expect { subject.validate_instance_shard_config('cache') }.not_to raise_error(RuntimeError)

        subject
      end
    end

    context 'with only clusters declared' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_rate_limiting_cluster_nodes: [
              { 'host' => 'cluster1.example.com', 'port' => '12345' },
              { 'host' => 'cluster1.example.com', 'port' => '12345' }
            ]
          }
        )
      end

      it 'does not raise error' do
        expect { subject.validate_instance_shard_config('rate_limiting') }.not_to raise_error(RuntimeError)
      end
    end

    context 'with cluster declared for instances outside allowed list' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_sessions_cluster_nodes: [
              { 'host' => 'cluster1.example.com', 'port' => '12345' },
              { 'host' => 'cluster1.example.com', 'port' => '12345' }
            ]
          }
        )
      end

      it 'raises error' do
        expect { subject.validate_instance_shard_config('sessions') }.to raise_error(RuntimeError)
      end
    end
  end
end
