require 'chef_helper'

RSpec.describe 'templatesymlink' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(templatesymlink))
  end

  context 'create' do
    let(:chef_run) { runner.converge('test_package::templatesymlink_create') }

    it 'creates symlinks' do
      expect(chef_run).to create_link('/opt/gitlab/embedded/service/gitlab-rails/config/database.yml')
    end

    it 'populates conf file' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content('value: 500')
    end
  end
  context 'delete' do
    let(:chef_run) { runner.converge('test_package::templatesymlink_delete') }

    it 'deletes symlinks' do
      expect(chef_run).to delete_link('/opt/gitlab/embedded/service/gitlab-rails/config/database.yml')
    end
  end
end
