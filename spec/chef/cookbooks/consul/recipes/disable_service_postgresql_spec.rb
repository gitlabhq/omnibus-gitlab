require 'chef_helper'

RSpec.describe 'consul::disable_service_postgresql' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default', 'consul::disable_service_postgresql') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'default' do
    before do
      stub_gitlab_rb(
        consul: {
          enable: true,
          services: []
        }
      )
    end

    it 'deletes the service configuration file' do
      expect(chef_run).to delete_file('/var/opt/gitlab/consul/config.d/postgresql_service.json')
    end
  end
end
