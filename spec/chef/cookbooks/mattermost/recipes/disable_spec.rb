require 'chef_helper'

RSpec.describe 'mattermost::disable' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service env_dir nginx_configuration)).converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'is always loaded under the default configuration' do
    expect(chef_run).to include_recipe('mattermost::disable')
  end

  it_behaves_like 'disabled runit service', 'mattermost'

  it 'deletes nginx configuration' do
    expect(chef_run).to delete_file('/var/opt/gitlab/nginx/conf/service_conf/gitlab-mattermost.conf')
  end
end
