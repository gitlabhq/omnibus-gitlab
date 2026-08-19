require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  describe 'Managed settings' do
    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: 'templatesymlink').converge('gitlab-base::config', 'gitlab::gitlab-rails') }
    let(:managed_settings_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/managed_settings.yml') }
    let(:managed_settings_yml_file_content) { ChefSpec::Renderer.new(chef_run, managed_settings_yml_template).content }
    let(:managed_settings_yml) { YAML.safe_load(managed_settings_yml_file_content) }

    before do
      allow(Gitlab).to receive(:[]).and_call_original
      allow(File).to receive(:symlink?).and_call_original
    end

    context 'with default settings' do
      it 'does not create managed_settings.yml' do
        expect(chef_run).to delete_templatesymlink('Create a managed_settings.yml and create a symlink to Rails root')
        expect(chef_run).to delete_file('/var/opt/gitlab/gitlab-rails/etc/managed_settings.yml')
        expect(chef_run).to delete_link('/opt/gitlab/embedded/service/gitlab-rails/config/managed_settings.yml')
      end
    end

    context 'with only installation metadata configured' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            managed_settings: {
              'installation' => { 'managed_by' => 'ACME Corp' }
            }
          }
        )
      end

      it 'does not create managed_settings.yml' do
        expect(chef_run).to delete_templatesymlink('Create a managed_settings.yml and create a symlink to Rails root')
      end
    end

    context 'with managed settings configured' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            managed_settings: {
              'settings' => { 'sidekiq_timezone_override' => 'Europe/London' }
            }
          }
        )
      end

      it 'creates managed_settings.yml and symlinks it into the Rails root' do
        expect(chef_run).to create_templatesymlink('Create a managed_settings.yml and create a symlink to Rails root').with(
          owner: 'root',
          group: 'git',
          mode: '0640'
        )
        expect(chef_run).to create_link('/opt/gitlab/embedded/service/gitlab-rails/config/managed_settings.yml').with(
          to: '/var/opt/gitlab/gitlab-rails/etc/managed_settings.yml'
        )
      end

      it 'renders managed_settings.yml with the default managed_by value' do
        expect(managed_settings_yml).to eq(
          'installation' => { 'managed_by' => 'GitLab Omnibus' },
          'managed_settings' => { 'sidekiq_timezone_override' => 'Europe/London' }
        )
      end
    end

    context 'with the settings assigned key by key in gitlab.rb' do
      before do
        allow(IO).to receive(:read).and_call_original
        allow(IO).to receive(:read).with('config-test.rb').and_return(
          <<~CONFIG
            gitlab_rails['managed_settings']['installation']['managed_by'] = 'ACME Corp'
            gitlab_rails['managed_settings']['settings'] = {
              'sidekiq_timezone_override' => 'Europe/London'
            }
          CONFIG
        )

        Gitlab.from_file('config-test.rb')
      end

      it 'renders managed_settings.yml' do
        expect(managed_settings_yml).to eq(
          'installation' => { 'managed_by' => 'ACME Corp' },
          'managed_settings' => { 'sidekiq_timezone_override' => 'Europe/London' }
        )
      end
    end

    context 'with only the managed settings assigned in gitlab.rb' do
      before do
        allow(IO).to receive(:read).and_call_original
        allow(IO).to receive(:read).with('config-test.rb').and_return(
          "gitlab_rails['managed_settings']['settings']['sidekiq_timezone_override'] = 'Europe/London'\n"
        )

        Gitlab.from_file('config-test.rb')
      end

      it 'keeps the default installation metadata' do
        expect(managed_settings_yml['installation']).to eq('managed_by' => 'GitLab Omnibus')
      end
    end

    context 'with a custom managed_by value' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            managed_settings: {
              'installation' => { 'managed_by' => 'ACME Corp' },
              'settings' => { 'sidekiq_timezone_override' => 'Europe/London' }
            }
          }
        )
      end

      it 'renders managed_settings.yml using the configured name' do
        expect(managed_settings_yml['installation']).to eq('managed_by' => 'ACME Corp')
      end
    end
  end
end
