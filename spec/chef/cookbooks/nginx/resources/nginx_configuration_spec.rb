require 'chef_helper'

RSpec.describe 'nginx_configuration' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into: %w(nginx_configuration))
  end

  context 'create' do
    let(:chef_run) { runner.converge('gitlab-base::config', 'test_nginx::enable') }

    before do
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('nginx').and_return(true)
    end

    it 'creates the configuration file' do
      expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/service_conf/gitlab-foobar.conf')
    end

    it 'restarts nginx' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/service_conf/gitlab-foobar.conf')).to notify('runit_service[nginx]').to(:restart)
    end
  end

  context 'delete' do
    let(:chef_run) { runner.converge('gitlab-base::config', 'test_nginx::disable') }

    before do
      allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).with('nginx').and_return(true)
    end

    it 'deletes the configuration file' do
      expect(chef_run).to delete_file('/var/opt/gitlab/nginx/conf/service_conf/gitlab-foobar.conf')
    end

    it 'restarts nginx' do
      expect(chef_run.file('/var/opt/gitlab/nginx/conf/service_conf/gitlab-foobar.conf')).to notify('runit_service[nginx]').to(:restart)
    end
  end
end
