require 'chef_helper'

RSpec.describe 'crond::enable' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::config', 'crond::enable') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it "should create a cron.d directory" do
    expect(chef_run).to create_directory("/var/opt/gitlab/crond").with(
      recursive: true,
      owner: "root"
    )
  end

  it "should pass correct options to runit_service" do
    expect(chef_run).to render_file("/opt/gitlab/sv/crond/run").with_content(/--include=\/var\/opt\/gitlab\/crond/)
  end

  it_behaves_like "enabled runit service", "crond", "root", "root"

  context 'log directory and runit group' do
    context 'default values' do
      before do
        stub_gitlab_rb(
          crond: {
            enable: true,
          }
        )
      end
      it_behaves_like 'enabled logged service', 'crond', true, { log_directory_owner: 'root' }
    end

    context 'custom values' do
      before do
        stub_gitlab_rb(
          crond: {
            enable: true,
            log_group: 'fugee'
          }
        )
      end
      it_behaves_like 'enabled logged service', 'crond', true, { log_directory_owner: 'root', log_group: 'fugee' }
    end
  end
end
