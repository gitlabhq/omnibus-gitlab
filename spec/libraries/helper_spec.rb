require 'chef_helper'

shared_examples 'Postgres helpers' do |service_name, service_cmd|
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['gitlab'][service_name]['data_dir'] = '/fakedir'
      node.set['package']['install-dir'] = '/fake/install/dir'
    end.converge('gitlab::config')
  end

  let(:node) { chef_run.node }

  let!(:helper) do
    described_class.new(node)
  end

  before do
    allow(VersionHelper).to receive(:version).with('/opt/gitlab/embedded/bin/psql --version') { 'YYYYYYYY XXXXXXX' }
  end


  it 'is associated with a valid service' do
    # this is a validation to make sure we are passing a valid/existing service_name to the shared example
    expect(node['gitlab'][service_name].to_h).not_to be_empty
  end

  describe '#version' do
    it 'returns a valid version' do
      expect(helper.version).to eq('XXXXXXX')
    end
  end

  describe '#database_version' do
    it 'returns a valid database_version' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/fakedir/PG_VERSION') { true }
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with('/fakedir/PG_VERSION') { '111.222' }
      allow(Dir).to receive(:glob).with('/fake/install/dir/embedded/postgresql/*') { %w(111.222.18 222.333.11) }

      # We mock this in chef_helper.rb. Override the mock to call the original
      allow_any_instance_of(described_class).to receive(:database_version).and_call_original
      expect(helper.database_version).to eq('111.222')
    end
  end

  describe '#extension_exists?' do
    it 'returns whether an extension exists' do
      expect(helper).to receive(:success?).with("/opt/gitlab/bin/#{service_cmd} -d 'template1' -c 'select name from pg_available_extensions' -A | grep -x myextension")
      helper.extension_exists?('myextension')
    end
  end

  describe '#extension_enabled?' do
    it 'returns whether an extension exists' do
      expect(helper).to receive(:success?).with("/opt/gitlab/bin/#{service_cmd} -d 'mydatabase' -c 'select extname from pg_extension' -A | grep -x myextension")
      helper.extension_enabled?('myextension', 'mydatabase')
    end
  end

  describe '#database_exists?' do
    it 'returns whether a database exists' do
      expect(helper).to receive(:success?).with("/opt/gitlab/bin/#{service_cmd} -d 'template1' -c 'select datname from pg_database' -A | grep -x mydatabase")
      helper.database_exists?('mydatabase')
    end
  end
end

describe PgHelper do
  include_examples 'Postgres helpers', 'postgresql', 'gitlab-psql'
end

describe GeoPgHelper do
  include_examples 'Postgres helpers', 'geo-postgresql', 'gitlab-geo-psql'
end

describe OmnibusHelper do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:node) { chef_run.node }
  let(:services) {
    %w(
      unicorn
      sidekiq
      gitlab-workhorse
      postgresql
      redis
      nginx
      logrotate
      prometheus
      node-exporter
      redis-exporter
      postgres-exporter
      gitlab-monitor
      gitaly
    ).freeze
  }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'service is currently enabled, bootstrapped and is running' do
    before do
      services.each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(true)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/bin/gitlab-ctl status #{service}").and_return(true)
      end
      stub_gitlab_rb(nginx: { enable: true })
    end

    it 'notifies the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'disabling a service that was bootstrapped and is currently running' do
    before do
      services.each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(true)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/bin/gitlab-ctl status #{service}").and_return(true)
      end
      stub_gitlab_rb(nginx: { enable: false })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'enabling a service that was bootstrapped but not currently running' do
    before do
      services.each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(true)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/bin/gitlab-ctl status #{service}").and_return(false)
      end
      stub_gitlab_rb(nginx: { enable: true })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'disabling a service that was bootstrapped but not currently running' do
    before do
      services.each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(true)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/bin/gitlab-ctl status #{service}").and_return(false)
      end
      stub_gitlab_rb(nginx: { enable: false })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'enabling a service that was disabled but currently running' do
    before do
      services.each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(false)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/bin/gitlab-ctl status #{service}").and_return(true)
      end
      stub_gitlab_rb(nginx: { enable: true })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'disabling a service that was disabled but currently running' do
    before do
      services.each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(false)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/bin/gitlab-ctl status #{service}").and_return(true)
      end
      stub_gitlab_rb(nginx: { enable: false })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'enabling a service that was disabled and not currently running' do
    before do
      services.each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(false)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/bin/gitlab-ctl status #{service}").and_return(false)
      end
      stub_gitlab_rb(nginx: { enable: true })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end

  context 'disabling a service that was disabled and not currently running' do
    before do
      services.each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(false)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/bin/gitlab-ctl status #{service}").and_return(false)
      end
      stub_gitlab_rb(nginx: { enable: false })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('service[nginx]').to(:restart).delayed
    end
  end
end
