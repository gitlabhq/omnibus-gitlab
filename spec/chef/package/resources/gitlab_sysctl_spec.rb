require 'chef_helper'

RSpec.describe 'sysctl' do
  let(:runner) { ChefSpec::SoloRunner.new(step_into: %w(gitlab_sysctl)) }
  let(:chef_run) { runner.converge("package::sysctl", "test_package::gitlab_sysctl_create") }
  let(:conf) { '90-omnibus-gitlab-foo.conf' }

  context 'with default values' do
    it 'creates sysctl.d directory for the service' do
      expect(chef_run).to create_directory('/etc/sysctl.d').with(mode: '0755', recursive: true)
    end

    it 'creates conf file for the service and loads it' do
      expect(chef_run).to create_file("create /opt/gitlab/embedded/etc/#{conf} foo").with_content("foo = 15000\n")

      resource = chef_run.file("create /opt/gitlab/embedded/etc/#{conf} foo")
      expect(resource).to notify("execute[load sysctl conf foo]").to(:run).delayed
    end

    it 'links conf file to /etc/sysctl.d location' do
      expect(chef_run).to create_link("/etc/sysctl.d/#{conf}")
    end

    it 'loaded the settings' do
      resource = chef_run.execute('load sysctl conf foo')
      expect(resource.command).to eq("sysctl -e -p /opt/gitlab/embedded/etc/#{conf}")
      expect(resource).to do_nothing
    end
  end

  context 'when modify_kernel_parameters is false' do
    let(:chef_run) { runner.converge("gitlab::config", "package::sysctl", "test_package::gitlab_sysctl_create") }

    before do
      allow(Gitlab).to receive(:[]).and_call_original

      stub_gitlab_rb(
        package: {
          modify_kernel_parameters: false
        }
      )
    end

    it 'do not create sysctl.d directory' do
      expect(chef_run).not_to create_directory('/etc/sysctl.d')
    end

    it 'does not create conf file' do
      expect(chef_run).not_to create_file("create /opt/gitlab/embedded/etc/#{conf} foo")
    end

    it 'do not link conf file to /etc/sysctl.d location' do
      expect(chef_run).not_to create_link("/etc/sysctl.d/#{conf}")
    end
  end
end
