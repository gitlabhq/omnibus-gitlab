require 'chef_helper'

describe 'redis' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'by default' do
    it 'creates redis config with default values' do
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/client-output-buffer-limit normal 0 0 0/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/client-output-buffer-limit slave 256mb 64mb 60/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/client-output-buffer-limit pubsub 32mb 8mb 60/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^hz 10/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save 900 1/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save 300 10/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save 60 10000/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^maxmemory 0/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^maxmemory-policy noeviction/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^maxmemory-samples 5/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^tcp-backlog 511/)
      expect(chef_run).not_to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^slaveof/)
    end

    it 'creates redis user and group' do
      expect(chef_run).to create_account('user and group for redis').with(username: 'gitlab-redis', groupname: 'gitlab-redis')
    end

    it_behaves_like 'enabled runit service', 'redis', 'root', 'root', 'gitlab-redis', 'gitlab-redis'
  end

  context 'with user specified values' do
    before do
      stub_gitlab_rb(
        redis: {
          client_output_buffer_limit_normal: "5 5 5",
          client_output_buffer_limit_slave: "512mb 128mb 120",
          client_output_buffer_limit_pubsub: "64mb 16mb 120",
          save: ["10 15000"],
          maxmemory: "32gb",
          maxmemory_policy: "allkeys-url",
          maxmemory_samples: 10,
          tcp_backlog: 1024,
          hz: 100,
          username: 'foo',
          group: 'bar'
        }
      )
    end

    it 'creates redis config with custom values' do
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/client-output-buffer-limit normal 5 5 5/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/client-output-buffer-limit slave 512mb 128mb 120/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/client-output-buffer-limit pubsub 64mb 16mb 120/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save 10 15000/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^maxmemory 32gb/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^maxmemory-policy allkeys-url/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^maxmemory-samples 10/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^tcp-backlog 1024/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^hz 100/)
    end

    it 'creates redis user and group' do
      expect(chef_run).to create_account('user and group for redis').with(username: 'foo', groupname: 'bar')
    end

    it_behaves_like 'enabled runit service', 'redis', 'root', 'root', 'foo', 'bar'
  end

  context 'with snapshotting disabled' do
    before do
      stub_gitlab_rb(
        redis: {
          save: []
        }
      )
    end
    it 'creates redis config without save setting' do
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
      expect(chef_run).not_to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save/)
    end
  end

  context 'with snapshotting cleared' do
    before do
      stub_gitlab_rb(
        redis: {
          save: [""]
        }
      )
    end
    it 'creates redis config without save setting' do
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save ""/)
    end
  end

  context 'with a slave configured' do
    let(:redis_host) { '1.2.3.4' }
    let(:redis_port) { 6370 }
    let(:master_ip) { '10.0.0.0' }
    let(:master_port) { 6371 }

    before do
      stub_gitlab_rb(
        redis: {
          bind: redis_host,
          port: redis_port,
          master_ip: master_ip,
          master_port: master_port,
          master_password: 'password',
          master: false
        }
      )
    end

    it 'includes slaveof' do
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^slaveof #{master_ip} #{master_port}/)
    end
  end

  context 'in HA mode with Sentinels' do
    let(:redis_host) { '1.2.3.4' }
    let(:redis_port) { 6370 }
    let(:master_ip) { '10.0.0.0' }
    let(:master_port) { 6371 }

    before do
      stub_gitlab_rb(
        redis: {
          bind: redis_host,
          port: redis_port,
          ha: true,
          master_ip: master_ip,
          master_port: master_port,
          master_password: 'password',
          master: false
        }
      )
    end

    it 'omits slaveof' do
      expect(chef_run).not_to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^slaveof/)
    end
  end

  context 'with redis disabled' do
    before do
      stub_gitlab_rb(redis: { enable: false })
    end

    it_behaves_like 'disabled runit service', 'redis', 'root', 'root'
  end
end
