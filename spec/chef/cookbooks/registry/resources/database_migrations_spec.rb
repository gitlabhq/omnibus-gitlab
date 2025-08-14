require 'chef_helper'

RSpec.describe 'registry_database_migrations' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(registry_database_migrations)) do |node|
      node.normal['registry']['auto_migrate'] = true
    end
  end

  let(:chef_run) { runner.converge('test_registry::registry_database_migrations_run') }

  before do
    allow_any_instance_of(AccountHelper).to receive(:registry_user).and_return('registry')
    allow_any_instance_of(AccountHelper).to receive(:registry_group).and_return('registry')
    allow_any_instance_of(LogfilesHelper).to receive(:logging_settings).and_return(
      log_directory: '/var/log/gitlab/registry'
    )
  end

  context 'when auto_migrate is enabled' do
    it 'runs the database migration command' do
      expect(chef_run).to run_bash_hide_env('migrate registry database: up').with(
        code: match(/gitlab-ctl registry-database migrate up/)
      )
    end

    it 'sets correct log file path with timestamp' do
      expect(chef_run).to run_bash_hide_env('migrate registry database: up').with(
        code: match(%r{LOG_FILE="/var/log/gitlab/registry/db-migrations-\$\(date \+%Y-%m-%d-%H-%M-%S\)\.log"})
      )
    end

    it 'sets correct ownership on log file' do
      expect(chef_run).to run_bash_hide_env('migrate registry database: up').with(
        code: match(/chown registry:registry \$\{LOG_FILE\}/)
      )
    end

    it 'pipes output to log file' do
      expect(chef_run).to run_bash_hide_env('migrate registry database: up').with(
        code: match(/2>& 1 \| tee \$\{LOG_FILE\}/)
      )
    end

    it 'checks exit status' do
      expect(chef_run).to run_bash_hide_env('migrate registry database: up').with(
        code: match(/STATUS=\$\{PIPESTATUS\[0\]\}/)
      )
    end

    context 'with SKIP_POST_DEPLOYMENT_MIGRATIONS environment variable set to true' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('SKIP_POST_DEPLOYMENT_MIGRATIONS').and_return('true')
      end

      it 'includes --skip-post-deployment flag when env var is true' do
        expect(chef_run).to run_bash_hide_env('migrate registry database: up').with(
          code: match(/--skip-post-deployment/)
        )
      end
    end

    context 'with SKIP_POST_DEPLOYMENT_MIGRATIONS environment variable set to false' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('SKIP_POST_DEPLOYMENT_MIGRATIONS').and_return('false')
      end

      it 'does not include --skip-post-deployment flag when env var is false' do
        expect(chef_run).to run_bash_hide_env('migrate registry database: up').with(
          code: match(/gitlab-ctl registry-database migrate up(?!.*--skip-post-deployment)/)
        )
      end
    end
  end
end
