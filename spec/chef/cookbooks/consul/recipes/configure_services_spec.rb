require 'chef_helper'

RSpec.describe 'consul::configure_services' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  describe 'enabling services' do
    before do
      stub_gitlab_rb(
        consul: {
          enable: true,
          services: %w(postgresql)
        }
      )
    end

    it 'includes the enable_service recipe for the corresponding service' do
      expect(chef_run).to include_recipe('consul::enable_service_postgresql')
    end
  end

  describe 'disabling services' do
    before do
      stub_gitlab_rb(
        consul: {
          enable: true,
          services: []
        }
      )
    end

    it 'includes the disable_service for all known services' do
      expect(chef_run).to include_recipe('consul::disable_service_postgresql')
    end
  end
end
