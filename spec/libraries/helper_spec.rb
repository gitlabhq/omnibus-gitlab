require 'chef_helper'

describe PgHelper do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['gitlab']['postgresql']['data_dir'] = '/fakedir'
      node.set['package']['install-dir'] = '/fake/install/dir'
    end.converge('gitlab::default')
  end
  let(:node) { chef_run.node }

  before do
    allow(VersionHelper).to receive(:version).with(
      '/opt/gitlab/embedded/bin/psql --version'
    ).and_return('YYYYYYYY XXXXXXX')
    @helper = PgHelper.new(node)
  end

  it 'returns a valid version' do
    expect(@helper.version).to eq('XXXXXXX')
  end

  it 'returns a valid database_version' do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(
      '/fakedir/PG_VERSION'
    ).and_return(true)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(
      '/fakedir/PG_VERSION'
    ).and_return('111.222')
    allow(Dir).to receive(:glob).with(
      '/fake/install/dir/embedded/postgresql/*'
    ).and_return(['111.222.18', '222.333.11'])
    # We mock this in chef_helper.rb. Overide the mock to call the original
    allow_any_instance_of(PgHelper).to receive(:database_version).and_call_original
    expect(@helper.database_version).to eq('111.222')
  end
end

describe OmnibusHelper do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:node) { chef_run.node }
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'service is currently enabled, bootstrapped and is running' do
    before do
      ["unicorn", "sidekiq", "gitlab-workhorse", "postgresql", "redis", "nginx", "logrotate"].each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(true)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/embedded/bin/sv status #{service}").and_return(true)
      end
      stub_gitlab_rb(nginx: {enable: true})
    end

    it 'notifies the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'disabling a service that was bootstrapped and is currently running' do
    before do
      ["unicorn", "sidekiq", "gitlab-workhorse", "postgresql", "redis", "nginx", "logrotate"].each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(true)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/embedded/bin/sv status #{service}").and_return(true)
      end
     stub_gitlab_rb(nginx: {enable: false})
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'enabling a service that was bootstrapped but not currently running' do
    before do
      ["unicorn", "sidekiq", "gitlab-workhorse", "postgresql", "redis", "nginx", "logrotate"].each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(true)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/embedded/bin/sv status #{service}").and_return(false)
      end
     stub_gitlab_rb(nginx: {enable: true})
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'disabling a service that was bootstrapped but not currently running' do
    before do
      ["unicorn", "sidekiq", "gitlab-workhorse", "postgresql", "redis", "nginx", "logrotate"].each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(true)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/embedded/bin/sv status #{service}").and_return(false)
      end
     stub_gitlab_rb(nginx: {enable: false})
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'enabling a service that was disabled but currently running' do
    before do
      ["unicorn", "sidekiq", "gitlab-workhorse", "postgresql", "redis", "nginx", "logrotate"].each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(false)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/embedded/bin/sv status #{service}").and_return(true)
      end
     stub_gitlab_rb(nginx: {enable: true})
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'disabling a service that was disabled but currently running' do
    before do
      ["unicorn", "sidekiq", "gitlab-workhorse", "postgresql", "redis", "nginx", "logrotate"].each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(false)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/embedded/bin/sv status #{service}").and_return(true)
      end
     stub_gitlab_rb(nginx: {enable: false})
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'enabling a service that was disabled and not currently running' do
    before do
      ["unicorn", "sidekiq", "gitlab-workhorse", "postgresql", "redis", "nginx", "logrotate"].each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(false)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/embedded/bin/sv status #{service}").and_return(false)
      end
     stub_gitlab_rb(nginx: {enable: true})
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'disabling a service that was disabled and not currently running' do
    before do
      ["unicorn", "sidekiq", "gitlab-workhorse", "postgresql", "redis", "nginx", "logrotate"].each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(false)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/embedded/bin/sv status #{service}").and_return(false)
      end
     stub_gitlab_rb(nginx: {enable: false})
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end
end
