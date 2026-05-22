require 'chef_helper'

$LOAD_PATH << File.expand_path('../../../../../../files/gitlab-ctl-commands/lib', __dir__)
require 'gitlab_ctl/registry/database'

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
    it 'runs the registry binary directly with the config path' do
      expect(chef_run).to run_bash_hide_env('migrate registry database: up').with(
        code: match(%r{/opt/gitlab/embedded/bin/registry database migrate up})
      )
    end

    it 'uses the default registry directory for the config path' do
      expect(chef_run).to run_bash_hide_env('migrate registry database: up').with(
        code: match(%r{/var/opt/gitlab/registry/config\.yml})
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

    context 'with a custom registry directory' do
      let(:runner) do
        ChefSpec::SoloRunner.new(step_into: %w(registry_database_migrations)) do |node|
          node.normal['registry']['auto_migrate'] = true
          node.normal['registry']['dir'] = '/var/opt/gitlab/registry-2'
        end
      end

      it 'uses the custom registry directory for the config path' do
        expect(chef_run).to run_bash_hide_env('migrate registry database: up').with(
          code: match(%r{/var/opt/gitlab/registry-2/config\.yml})
        )
      end
    end

    context 'with SKIP_POST_DEPLOYMENT_MIGRATIONS environment variable set to true' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('SKIP_POST_DEPLOYMENT_MIGRATIONS').and_return('true')
      end

      it 'includes -s flag when env var is true' do
        expect(chef_run).to run_bash_hide_env('migrate registry database: up').with(
          code: match(/ -s /)
        )
      end
    end

    context 'with SKIP_POST_DEPLOYMENT_MIGRATIONS environment variable set to false' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('SKIP_POST_DEPLOYMENT_MIGRATIONS').and_return('false')
      end

      it 'does not include -s flag when env var is false' do
        expect(chef_run).to run_bash_hide_env('migrate registry database: up').with(
          code: match(%r{/opt/gitlab/embedded/bin/registry database migrate up\s+/})
        )
      end
    end
  end

  # The CLI (gitlab-ctl registry-database) and this resource each construct
  # <registry_dir>/config.yml independently. These examples fail if the two
  # sides drift on either the default directory or the config filename.
  describe 'config path consistency with the CLI' do
    let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }

    before do
      allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return({})
    end

    it 'shares the same default registry directory between CLI and cookbook' do
      expect(GitlabCtl::Registry::Database::DEFAULT_REGISTRY_DIR)
        .to eq(chef_run.node['registry']['dir'])
    end

    it 'produces the same default config.yml path on both sides' do
      cookbook_path = ::File.join(chef_run.node['registry']['dir'], 'config.yml')
      expect(GitlabCtl::Registry::Database.config_path).to eq(cookbook_path)
    end
  end
end
