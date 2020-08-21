require 'chef_helper'

RSpec.describe 'gitlab::sidekiq-cluster' do
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

  describe 'when sidekiq-cluster is disabled' do
    before { stub_gitlab_rb(sidekiq_cluster: { enable: false }) }

    it 'does not render the sidekiq-cluster service file' do
      expect(chef_run).not_to render_file("/opt/gitlab/sv/sidekiq-cluster/run")
    end
  end

  context 'with default values' do
    before do
      stub_gitlab_rb(sidekiq_cluster: {
                       enable: true,
                       queue_groups: ['process_commit,post_receive', 'gitlab_shell']
                     })
    end

    it_behaves_like "enabled runit service", "sidekiq-cluster", "root", "root"
  end

  context 'with custom user and group values' do
    before do
      stub_gitlab_rb(
        sidekiq_cluster: {
          enable: true,
          queue_groups: ['process_commit,post_receive', 'gitlab_shell']
        },
        user: {
          username: 'foo',
          group: 'bar'
        }
      )
    end

    it_behaves_like "enabled runit service", "sidekiq-cluster", "root", "root"
  end

  context 'with queue_groups set' do
    before do
      stub_gitlab_rb(sidekiq_cluster: {
                       enable: true,
                       queue_groups: ['process_commit,post_receive', 'gitlab_shell']
                     })
    end

    it 'correctly renders out the sidekiq-cluster service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq-cluster/run")
        .with_content { |content|
          expect(content).not_to match(/export prometheus_run_dir=\'\'/)
          expect(content).to match(/mkdir -p \/run\/gitlab\/sidekiq-cluster/)
          expect(content).to match(/rm \/run\/gitlab\/sidekiq-cluster/)
          expect(content).to match(/chmod 0700 \/run\/gitlab\/sidekiq-cluster/)
          expect(content).to match(/chown git \/run\/gitlab\/sidekiq-cluster/)
          expect(content).to match(/export prometheus_run_dir=\'\/run\/gitlab\/sidekiq-cluster\'/)
          expect(content).to match(/process_commit,post_receive/)
          expect(content).to match(/gitlab_shell/)
          expect(content).not_to match(/--negate/)
          expect(content).not_to match(/-m /)
        }
    end
  end

  context 'with --negate set' do
    before do
      stub_gitlab_rb(sidekiq_cluster: {
                       enable: true,
                       negate: true,
                       queue_groups: ['process_commit,post_receive', 'gitlab_shell']
                     })
    end

    it 'correctly renders out the sidekiq-cluster service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq-cluster/run")
        .with_content { |content|
          expect(content).to match(/--negate/)
        }
    end
  end

  context 'with interval set' do
    before do
      stub_gitlab_rb(sidekiq_cluster: {
                       enable: true,
                       interval: 10,
                       queue_groups: ['process_commit,post_receive']
                     })
    end

    it 'correctly renders out the sidekiq-cluster service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq-cluster/run").with_content(/\-i 10/)
    end
  end

  context 'with max_concurrency set' do
    before do
      stub_gitlab_rb(sidekiq_cluster: {
                       enable: true,
                       max_concurrency: 100,
                       queue_groups: ['process_commit,post_receive', 'gitlab_shell']
                     })
    end

    it 'correctly renders out the sidekiq-cluster service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq-cluster/run")
        .with_content { |content|
          expect(content).to match(/-m 100/)
        }
    end
  end

  context 'with min_concurrency set' do
    before do
      stub_gitlab_rb(sidekiq_cluster: {
                       enable: true,
                       min_concurrency: 50,
                       queue_groups: ['process_commit,post_receive', 'gitlab_shell']
                     })
    end

    it 'correctly renders out the sidekiq-cluster service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq-cluster/run")
        .with_content { |content|
          expect(content).to match(/--min-concurrency 50/)
        }
    end
  end

  context 'with experimental_queue_selector set' do
    before do
      stub_gitlab_rb(sidekiq_cluster: {
                       enable: true,
                       experimental_queue_selector: true,
                       queue_groups: ['feature_category=pages', 'feature_category=continuous_integration']
                     })
    end

    it 'correctly renders out the sidekiq-cluster service file' do
      expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq-cluster/run")
        .with_content { |content|
          expect(content).to match(/--experimental-queue-selector/)
          expect(content).to match(/"feature_category=pages"/)
        }
    end
  end

  describe 'when specifying sidekiq.log_format' do
    before do
      stub_gitlab_rb(
        sidekiq_cluster: {
          enable: true,
          queue_groups: ['process_commit,post_receive', 'gitlab_shell']
        }
      )
    end

    context 'when default' do
      before { stub_gitlab_rb(sidekiq: { log_format: 'default' }) }

      it 'sets the svlogd -tt option' do
        expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq-cluster/log/run")
          .with_content(/svlogd -tt/)
      end
    end

    context 'when json' do
      it 'does not set the svlogd -tt option' do
        expect(chef_run).not_to render_file("/opt/gitlab/sv/sidekiq-cluster/log/run")
          .with_content(/-tt/)
      end
    end
  end
end
