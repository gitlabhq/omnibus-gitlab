require 'chef_helper'

RSpec.describe 'puma_config' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(puma_config))
  end

  context 'create' do
    let(:chef_run) { runner.converge('test_gitlab::puma_config_create') }

    it 'creates necessary directories' do
      expect(chef_run).to create_directory('/var/opt/gitlab/gitlab-rails/etc')
    end

    it 'renders puma.rb file' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with_content { |content|
        expect(content).to match(%r(^environment 'production'))
        expect(content).to match(%r(^rackup '/opt/gitlab/embedded/service/gitlab-rails/config.ru'))
        expect(content).to match(%r(^pidfile '/opt/gitlab/var/puma/puma.pid'))
        expect(content).to match(%r(^state_path '/opt/gitlab/var/puma/puma.state'))
        expect(content).to match(%r(^bind 'unix:///var/opt/gitlab/gitlab-rails/sockets/gitlab.socket'))
        expect(content).to match(%r(^bind 'tcp://127.0.0.1:8080'))
        expect(content).to match(%r(^directory '/var/opt/gitlab/gitlab-rails/working'))
        expect(content).to match(%r(^require_relative "/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/cluster/lifecycle_events"$))
        expect(content).to match(/^options = { workers: 2 }$/)
        expect(content).to match(%r(Gitlab::Cluster::PumaWorkerKillerInitializer.start\(options\)))
        expect(content).to match(/^preload_app!$/)
        expect(content).to match(%r(^require_relative "/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/puma_logging/json_formatter"$))
      }
    end
  end

  context 'create with default puma config' do
    let(:chef_run) { runner.converge('test_gitlab::puma_config_create') }

    it 'renders puma.rb file' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with_content { |content|
        expect(content).to match(%r(rackup '/opt/gitlab/embedded/service/gitlab-rails))
      }
    end
  end

  context 'create with custom Puma settings' do
    let(:chef_run) { runner.converge('test_gitlab::puma_config_custom') }

    it 'renders puma.rb file' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/puma.rb').with_content { |content|
        expect(content).to match(%r(Gitlab::Cluster::PumaWorkerKillerInitializer.start\(options, puma_per_worker_max_memory_mb: 1000\)))
        expect(content).to match(%r(rackup '/opt/custom/gitlab/embedded/service/gitlab-rails))
      }
    end
  end
end
