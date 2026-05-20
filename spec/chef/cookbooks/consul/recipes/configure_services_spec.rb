require 'chef_helper'

RSpec.describe 'consul::configure_services' do
  # `consul::configure_services` notifies `execute[reload consul]`, which is
  # defined in `consul::enable_daemon` - include it so the notification target
  # resolves at compile time.
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab-base::config', 'consul::enable_daemon', 'consul::configure_services') }

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
