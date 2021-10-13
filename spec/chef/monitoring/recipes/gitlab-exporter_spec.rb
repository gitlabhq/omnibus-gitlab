require 'chef_helper'

RSpec.describe 'monitoring::gitlab-exporter' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:default_env_vars) do
    {
      'LD_PRELOAD' => '/opt/gitlab/embedded/lib/libjemalloc.so',
      'MALLOC_CONF' => 'dirty_decay_ms:0,muzzy_decay_ms:0',
      'RUBY_GC_HEAP_INIT_SLOTS' => 80000,
      'RUBY_GC_HEAP_FREE_SLOTS_MIN_RATIO' => 0.055,
      'RUBY_GC_HEAP_FREE_SLOTS_MAX_RATIO' => 0.111
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when gitlab-exporter is enabled' do
    let(:config_template) { chef_run.template('/opt/gitlab/sv/gitlab-exporter/log/config') }

    before do
      stub_gitlab_rb(
        gitlab_exporter: { enable: true }
      )
    end

    it 'creates a default VERSION file and restarts service' do
      expect(chef_run).to create_version_file('Create version file for GitLab-Exporter').with(
        version_file_path: '/var/opt/gitlab/gitlab-exporter/RUBY_VERSION',
        version_check_cmd: '/opt/gitlab/embedded/bin/ruby --version'
      )

      expect(chef_run.version_file('Create version file for GitLab-Exporter')).to notify('runit_service[gitlab-exporter]').to(:restart)
    end

    it_behaves_like 'enabled runit service', 'gitlab-exporter', 'root', 'root'

    it 'creates necessary env variable files' do
      expect(chef_run).to create_env_dir('/opt/gitlab/etc/gitlab-exporter/env').with_variables(default_env_vars)
    end

    it 'populates the files with expected configuration' do
      expect(config_template).to notify('ruby_block[reload_log_service]')

      expect(chef_run).to render_file('/opt/gitlab/sv/gitlab-exporter/run')
        .with_content { |content|
          expect(content).to match(/exec chpst -P/)
          expect(content).to match(/\/opt\/gitlab\/embedded\/bin\/gitlab-exporter/)
        }

      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-exporter/gitlab-exporter.yml')
        .with_content { |content|
          # Not disabling this Cop fails the test with:
          # Psych::BadAlias: Unknown alias: db_common
          settings = YAML.load(content) # rubocop:disable Security/YAMLLoad
          expect(settings.dig('server', 'name')).to eq('webrick')
          expect(settings.dig('probes', 'database')).not_to be_nil
          expect(settings.dig('probes', 'ruby')).not_to be_nil
          expect(settings.dig('probes', 'metrics', 'rows_count')).not_to be_nil

          expect(content).to match(/host=\/var\/opt\/gitlab\/postgresql/)
          expect(content).to match(/redis_enable_client: true/)
        }

      expect(chef_run).to render_file('/opt/gitlab/sv/gitlab-exporter/log/run')
        .with_content(/exec svlogd -tt \/var\/log\/gitlab\/gitlab-exporter/)
    end

    it 'creates default set of directories' do
      expect(chef_run).to create_directory('/var/log/gitlab/gitlab-exporter').with(
        owner: 'git',
        group: nil,
        mode: '0700'
      )
    end
  end

  context 'with custom user and group' do
    before do
      stub_gitlab_rb(
        gitlab_exporter: {
          enable: true
        },
        user: {
          username: 'foo',
          group: 'bar'
        }
      )
    end

    it_behaves_like 'enabled runit service', 'gitlab-exporter', 'root', 'root'
  end

  context 'when gitlab-exporter is enabled and postgres is disabled' do
    let(:config_template) { chef_run.template('/opt/gitlab/sv/gitlab-exporter/log/config') }

    before do
      stub_gitlab_rb(
        gitlab_exporter: { enable: true },
        gitlab_rails: { db_host: 'postgres.example.com', db_port: '5432', db_password: 'secret' },
        postgresql: { enabled: false }
      )
    end

    it 'populates a config with a remote host' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-exporter/gitlab-exporter.yml')
        .with_content { |content|
          expect(content).to match(/host=postgres\.example\.com/)
          expect(content).to match(/port=5432/)
          expect(content).to match(/password=secret/)
        }
    end
  end

  context 'with custom Redis settings' do
    before do
      stub_gitlab_rb(
        gitlab_exporter: { enable: true },
        gitlab_rails: { redis_enable_client: false }
      )
    end

    it 'disables Redis CLIENT' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-exporter/gitlab-exporter.yml')
        .with_content { |content|
          expect(content).to match(/redis_enable_client: false/)
        }
    end
  end

  context 'when log dir is changed' do
    before do
      stub_gitlab_rb(
        gitlab_exporter: {
          log_directory: 'foo',
          enable: true
        }
      )
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/gitlab-exporter/log/run')
        .with_content(/exec svlogd -tt foo/)
    end
  end

  include_examples "consul service discovery", "gitlab_exporter", "gitlab-exporter"
end
