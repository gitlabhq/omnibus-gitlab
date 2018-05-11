require 'chef_helper'

describe 'templatesymlink' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(templatesymlink))
  end

  context 'delete' do
    let(:chef_run) { runner.converge('test_package_templatesymlink::delete') }

    it 'deletes symlinks' do
      expect(chef_run).to delete_link('/opt/gitlab/embedded/service/gitlab-rails/config/database.yml')
    end
  end
end
