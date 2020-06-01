require 'chef_helper'

describe 'monitoring::redis-exporter' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:node) { chef_run.node }
  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/'
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when redis is disabled locally' do
    before do
      stub_gitlab_rb(
        redis: { enable: false }
      )
    end

    it 'defaults the redis-exporter to being disabled' do
      expect(node['monitoring']['redis-exporter']['enable']).to eq false
    end

    it 'allows redis-exporter to be explicitly enabled' do
      stub_gitlab_rb(redis_exporter: { enable: true })

      expect(node['monitoring']['redis-exporter']['enable']).to eq true
    end
  end

  context 'when redis-exporter is enabled' do
    let(:config_template) { chef_run.template('/opt/gitlab/sv/redis-exporter/log/config') }

    before do
      stub_gitlab_rb(
        redis_exporter: { enable: true }
      )
    end

    it_behaves_like 'enabled runit service', 'redis-exporter', 'root', 'root'

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/redis-exporter/env').with_variables(default_vars)
    end

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload_log_service]')

      expect(chef_run).to render_file('/opt/gitlab/sv/redis-exporter/run')
        .with_content { |content|
          expect(content).to match(/exec chpst -P/)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/redis_exporter/)
        }

      expect(chef_run).to render_file('/opt/gitlab/sv/redis-exporter/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/redis-exporter/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/redis-exporter').with(
        owner: 'gitlab-redis',
        group: nil,
        mode: '0700'
      )
    end

    it 'sets default flags' do
      expect(chef_run).to render_file('/opt/gitlab/sv/redis-exporter/run')
        .with_content(/web.listen-address=localhost:9121/)
      expect(chef_run).to render_file('/opt/gitlab/sv/redis-exporter/run')
        .with_content(%r{redis.addr=unix:///var/opt/gitlab/redis/redis.socket})
    end
  end

  context 'when log dir is changed' do
    before do
      stub_gitlab_rb(
        redis_exporter: {
          log_directory: 'foo',
          enable: true
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/redis-exporter/log/run')
        .with_content(/exec svlogd -tt foo/)
    end
  end

  context 'with user provided settings' do
    before do
      stub_gitlab_rb(
        redis_exporter: {
          flags: {
            'redis.addr' => '/tmp/socket'
          },
          listen_address: 'localhost:9900',
          enable: true,
          env: {
            'USER_SETTING' => 'asdf1234'
          }
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/redis-exporter/run')
        .with_content(/web.listen-address=localhost:9900/)
      expect(chef_run).to render_file('/opt/gitlab/sv/redis-exporter/run')
        .with_content(%r{redis.addr=/tmp/socket})
    end

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/redis-exporter/env').with_variables(
        default_vars.merge(
          {
            'USER_SETTING' => 'asdf1234'
          }
        )
      )
    end
  end
end
