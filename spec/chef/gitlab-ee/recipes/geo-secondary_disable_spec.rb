require 'chef_helper'

RSpec.describe 'gitlab-ee::geo-secondary_disable' do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'when geo_secondary_role is disabled' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

    before { stub_gitlab_rb(geo_secondary_role: { enable: false }) }

    it 'removes database_geo.yml symlink' do
      expect(chef_run).to delete_templatesymlink('Removes database_geo.yml symlink')
                            .with(link_to: '/var/opt/gitlab/gitlab-rails/etc/database_geo.yml',
                                  link_from: '/opt/gitlab/embedded/service/gitlab-rails/config/database_geo.yml')
    end
  end
end
