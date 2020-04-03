require 'chef_helper'

describe 'gitlab::sidekiq' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(runit_service),
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
          expect(content).to match(/\-C \/opt\/gitlab\/embedded\/service\/.*\/config\/sidekiq_queues.yml/)
          expect(content).to match(/\-t 4/)
          expect(content).to match(/\-c 25/)
        }
    end

    it_behaves_like "enabled runit service", "sidekiq", "root", "root", "git", "git"
  end

  context 'with specified values' do
    before do
      stub_gitlab_rb(
        sidekiq: {
          shutdown_timeout: 8, concurrency: 35
        },
        user: {
          username: 'foo',
          group: 'bar'
        }
      )
    end
    it 'correctly renders out the sidekiq service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run").with_content(/\-t 8/)
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/run").with_content(/\-c 35/)
    end

    it_behaves_like "enabled runit service", "sidekiq", "root", "root", "foo", "bar"
  end

  context 'when enabling sidekiq-cluster through the sidekiq configuration' do
    before do
      stub_gitlab_rb(
        sidekiq: {
          cluster: true
        }
      )
    end

    it 'renders the sidekiq-service file with sidekiq-cluster content', :aggregate_failures do
      expect(chef_run).to(render_file("/opt/gitlab/sv/sidekiq/run").with_content do |content|
        expect(content).to match(%r{bin/sidekiq-cluster})
        expect(content).to match(%r{prometheus_run_dir='\/run\/gitlab\/sidekiq'})
      end)
    end

    it_behaves_like "enabled runit service", "sidekiq", "root", "root", "git", "git"
    it_behaves_like "disabled runit service", "sidekiq-cluster"
  end
end
