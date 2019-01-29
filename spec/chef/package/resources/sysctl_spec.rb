require 'chef_helper'

describe 'sysctl' do
  let(:runner) { ChefSpec::SoloRunner.new(step_into: %w(sysctl)) }
  let(:chef_run) { runner.converge("test_package::sysctl_create") }
  let(:conf) { '90-omnibus-gitlab-foo.conf' }

  it 'creates sysctl.d directory for the service' do
    expect(chef_run).to create_directory('/etc/sysctl.d').with(mode: '0755', recursive: true)
  end

  it 'creates conf file for the service and loads it' do
    expect(chef_run).to create_file("create /opt/gitlab/embedded/etc/#{conf} foo").with_content("foo = 15000\n")

    resource = chef_run.file("create /opt/gitlab/embedded/etc/#{conf} foo")
    expect(resource).to notify("execute[load sysctl conf foo]").to(:run).immediately
  end

  it 'links conf file to /etc/sysctl.d location' do
    expect(chef_run).to create_link("/etc/sysctl.d/#{conf}")
  end

  it 'removed old configs' do
    allow(::File).to receive(:exist?).and_call_original
    allow(::File).to receive(:exist?).with('/opt/gitlab/embedded/etc/90-omnibus-gitlab.conf').and_return(true)
    expect(chef_run).to delete_file('delete /opt/gitlab/embedded/etc/90-omnibus-gitlab.conf foo')
  end

  it 'loaded the settings' do
    resource = chef_run.execute('load sysctl conf foo')
    expect(resource.command).to eq('cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p -')
    expect(resource).to do_nothing
  end
end
