require 'chef_helper'

describe 'gitlab::unicorn' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(unicorn_service unicorn_config runit_service),
      path: 'spec/fixtures/fauxhai/ubuntu/16.04.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      unicorn: { enable: true },
      puma: { enable: false }
    )
  end

  context 'when unicorn is enabled' do
    it_behaves_like 'enabled runit service', 'unicorn', 'root', 'root'

    describe 'logrotate settings' do
      context 'default values' do
        it_behaves_like 'configured logrotate service', 'unicorn', 'git', 'git'
      end

      context 'specified username and group' do
        before do
          stub_gitlab_rb(
            unicorn: { enable: true },
            puma: { enable: false },
            user: {
              username: 'foo',
              group: 'bar'
            }
          )
        end

        it_behaves_like 'configured logrotate service', 'unicorn', 'foo', 'bar'
      end
    end

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/unicorn/run')
        .with_content { |content|
          expect(content).not_to match(/export prometheus_run_dir=\'\'/)
          expect(content).not_to match(/rm \/run\/gitlab\/unicorn/)
          expect(content).to match(/mkdir -p \/run\/gitlab\/unicorn/)
          expect(content).to match(/chmod 0700 \/run\/gitlab\/unicorn/)
          expect(content).to match(/chown git \/run\/gitlab\/unicorn/)
          expect(content).to match(/export prometheus_run_dir=\'\/run\/gitlab\/unicorn\'/)
        }
    end

    it 'renders the unicorn.rb file' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/unicorn.rb').with_content { |content|
        expect(content).to match(/^require_relative \"\/opt\/gitlab\/embedded\/service\/gitlab-rails\/lib\/gitlab\/cluster\/lifecycle_events\"/)
        expect(content).to match(/^before_exec/)
        expect(content).to match(/^before_fork/)
        expect(content).to match(/^after_fork/)
        expect(content).to match(/^worker_processes 2/)
      }
    end
  end

  context 'with custom user and group' do
    before do
      stub_gitlab_rb(
        unicorn: { enable: true },
        puma: { enable: false },
        user: {
          username: 'foo',
          group: 'bar'
        }
      )
    end

    it_behaves_like 'enabled runit service', 'unicorn', 'root', 'root'
  end

  context 'with custom runtime_dir' do
    before do
      stub_gitlab_rb(
        unicorn: { enable: true },
        puma: { enable: false },
        runtime_dir: '/tmp/test-dir'
      )
    end

    it 'uses the user-specific runtime_dir' do
      expect(chef_run).to render_file('/opt/gitlab/sv/unicorn/run')
        .with_content { |content|
          expect(content).to match(%r(export prometheus_run_dir='/tmp/test-dir/gitlab/unicorn'))
          expect(content).to match(%r(mkdir -p /tmp/test-dir/gitlab/unicorn))
        }
    end
  end
end

describe 'gitlab::unicorn' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(unicorn_service unicorn_config runit_service),
      path: 'spec/fixtures/fauxhai/ubuntu/16.04-no-run-tmpfs.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      unicorn: { enable: true },
      puma: { enable: false }
    )
  end

  context 'when unicorn is enabled on a node with no /run or /dev/shm tmpfs' do
    it_behaves_like 'enabled runit service', 'unicorn', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/unicorn/run')
        .with_content { |content|
          expect(content).to match(/export prometheus_run_dir=\'\'/)
          expect(content).not_to match(/mkdir -p \/run\/gitlab\/unicorn/)
        }
    end
  end
end

describe 'gitlab::unicorn' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(unicorn_service unicorn_config runit_service),
      path: 'spec/fixtures/fauxhai/ubuntu/16.04-docker.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      unicorn: { enable: true },
      puma: { enable: false }
    )
  end

  context 'when unicorn is enabled on a node with a /dev/shm tmpfs' do
    it_behaves_like 'enabled runit service', 'unicorn', 'root', 'root'

    it 'populates the files with expected configuration' do
      expect(chef_run).to render_file('/opt/gitlab/sv/unicorn/run')
        .with_content { |content|
          expect(content).to match(/export prometheus_run_dir=\'\/dev\/shm\/gitlab\/unicorn\'/)
          expect(content).to match(/mkdir -p \/dev\/shm\/gitlab\/unicorn/)
        }
    end
  end
end

describe 'gitlab::unicorn' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      step_into: %w(unicorn_service unicorn_config runit_service),
      path: 'spec/fixtures/fauxhai/ubuntu/16.04-more-cpus.json'
    )
    runner.converge('gitlab::default')
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      unicorn: { enable: true },
      puma: { enable: false }
    )
  end

  context 'when unicorn is enabled' do
    it 'renders the unicorn.rb file' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/unicorn.rb').with_content { |content|
        expect(content).to match(/^require_relative \"\/opt\/gitlab\/embedded\/service\/gitlab-rails\/lib\/gitlab\/cluster\/lifecycle_events\"/)
        expect(content).to match(/^worker_processes 25/)
      }
    end
  end
end
