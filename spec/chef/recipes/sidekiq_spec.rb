require 'chef_helper'

RSpec.describe 'gitlab::sidekiq' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(sidekiq_service runit_service),
      path: 'spec/fixtures/fauxhai/ubuntu/16.04.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'with default values' do
    it 'correctly renders out the sidekiq service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run")
        .with_content { |content|
          expect(content).not_to match(/export prometheus_run_dir=\'\'/)
          expect(content).to match(/mkdir -p \/run\/gitlab\/sidekiq/)
          expect(content).to match(/rm \/run\/gitlab\/sidekiq/)
          expect(content).to match(/chmod 0700 \/run\/gitlab\/sidekiq/)
          expect(content).to match(/chown git \/run\/gitlab\/sidekiq/)
          expect(content).to match(/export prometheus_run_dir=\'\/run\/gitlab\/sidekiq\'/)
          expect(content).to match(%r{bin/sidekiq-cluster})
          expect(content).to match(/-m 50/) # max_concurrency
          expect(content).to match(/--timeout 25/) # shutdown timeout
          expect(content).to match(/\*/) # all queues
        }
    end

    it_behaves_like "enabled runit service", "sidekiq", "root", "root"
  end

  describe 'log_format' do
    context 'by default' do
      it 'does not pass timestamp flag to svlogd' do
        expect(chef_run).not_to render_file("/opt/gitlab/sv/sidekiq/log/run").with_content(/-tt/)
      end
    end

    context 'when user specifies text log format' do
      before do
        stub_gitlab_rb(
          sidekiq: { log_format: 'text' }
        )
      end

      it 'passes timestamp flag to svlogd' do
        expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/log/run").with_content(/-tt/)
      end
    end
  end

  describe 'consul service discovery' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

    context 'by default' do
      it 'is not registered as a consul service' do
        expect(chef_run).not_to create_consul_service('sidekiq')
      end
    end

    context 'when enabled' do
      before do
        stub_gitlab_rb(
          consul: {
            enable: true,
            monitoring_service_discovery: true
          }
        )
      end

      context 'with default service name' do
        it 'is registered as a consul service' do
          expect(chef_run).to create_consul_service('sidekiq')
        end
      end

      context 'with user specified service name' do
        before do
          stub_gitlab_rb(
            consul: {
              enable: true,
              monitoring_service_discovery: true
            },
            sidekiq: {
              consul_service_name: 'sidekiq-foobar'
            }
          )
        end

        it 'is registered as a consul service with specified service name' do
          expect(chef_run).to create_consul_service('sidekiq-foobar')
        end
      end
    end
  end
end
