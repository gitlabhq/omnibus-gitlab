require 'chef_helper'

RSpec.describe 'package::runit' do
  before do
    allow(Chef::Log).to receive(:info).and_call_original
    allow(Chef::Log).to receive(:warn).and_call_original
    allow(File).to receive(:directory?).and_call_original
    allow(File).to receive(:directory?).with('/run/systemd/system').and_return(false)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/.dockerenv').and_return(false)
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'default values' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('package::runit') }

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:include_recipe)
    end

    it 'detects systemd correctly and informs user' do
      allow(File).to receive(:directory?).with('/run/systemd/system').and_return(true)

      expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('package::runit_systemd')

      chef_run
    end

    it 'detects docker container correctly' do
      allow(File).to receive(:exist?).with('/.dockerenv').and_return(true)

      expect_any_instance_of(Chef::Recipe).not_to receive(:include_recipe).with('package::runit_systemd')
      expect_any_instance_of(Chef::Recipe).not_to receive(:include_recipe).with('package::runit_upstart')
      expect_any_instance_of(Chef::Recipe).not_to receive(:include_recipe).with('package::runit_sysvinit')

      chef_run
    end

    it 'detects upstart correctly and informs user' do
      allow(Open3).to receive(:capture3).with('/sbin/init --version | grep upstart').and_return(['', '', double(success?: true)])

      expect_any_instance_of(Chef::Recipe).not_to receive(:include_recipe).with('package::runit_systemd')
      expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('package::runit_upstart')
      expect(Chef::Log).to receive(:warn).with("Selected upstart because /sbin/init --version is showing upstart.")

      chef_run
    end

    it 'fall backs to sysvinit correctly and informs user' do
      allow(Open3).to receive(:capture3).with('/sbin/init --version | grep upstart').and_return(['', '', double(success?: false)])

      expect_any_instance_of(Chef::Recipe).not_to receive(:include_recipe).with('package::runit_systemd')
      expect_any_instance_of(Chef::Recipe).not_to receive(:include_recipe).with('package::runit_upstart')
      expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('package::runit_sysvinit')

      chef_run
    end
  end

  context 'explicitly disabled' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

    before do
      stub_gitlab_rb(
        package: {
          detect_init: false
        }
      )
    end

    it 'does not run any recipe' do
      expect_any_instance_of(Chef::Recipe).not_to receive(:include_recipe).with('package::runit_upstart')
      expect_any_instance_of(Chef::Recipe).not_to receive(:include_recipe).with('package::runit_systemd')
      expect_any_instance_of(Chef::Recipe).not_to receive(:include_recipe).with('package::runit_sysvinit')

      chef_run
    end

    it 'informs the user about skipping init detection' do
      expect(Chef::Log).to receive(:info).with('Skipped selecting an init system because it was explicitly disabled')

      chef_run
    end
  end
end
