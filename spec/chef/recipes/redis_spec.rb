require 'chef_helper'

describe 'gitlab::redis' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }

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
        .with_content(/^save 900 1/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save 300 10/)
      expect(chef_run).to render_file('/var/opt/gitlab/redis/redis.conf')
        .with_content(/^save 60 10000/)
    end
  end

  context 'with user specified values' do
    before do
      stub_gitlab_rb(
        redis: {
          client_output_buffer_limit_normal: "5 5 5",
          client_output_buffer_limit_slave: "512mb 128mb 120",
          client_output_buffer_limit_pubsub: "64mb 16mb 120",
          save: ["10 15000"]
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
    end
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
end
