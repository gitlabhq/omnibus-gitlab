require 'chef_helper'

RSpec.shared_examples 'Postgres helpers' do |service_name, service_cmd, edition|
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.normal['gitlab'][service_name]['data_dir'] = '/fakedir'
      node.normal['package']['install-dir'] = '/fake/install/dir'
    end.converge("#{edition}::config")
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

RSpec.describe PgHelper do
  include_examples 'Postgres helpers', 'postgresql', 'gitlab-psql', 'gitlab'
end

RSpec.describe GeoPgHelper do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      'geo_postgresql' => {
        'data_dir' => '/fakedir'
      }
    )
  end

  include_examples 'Postgres helpers', 'geo-postgresql', 'gitlab-geo-psql', 'gitlab-ee'
end

RSpec.describe OmnibusHelper do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:node) { chef_run.node }
  let(:services) do
    %w(
      unicorn
      puma
      actioncable
      sidekiq
      sidekiq-cluster
      gitlab-workhorse
      postgresql
      redis
      nginx
      logrotate
      prometheus
      alertmanager
      grafana
      node-exporter
      redis-exporter
      postgres-exporter
      gitlab-exporter
      gitlab-pages
      gitaly
    ).freeze
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(File).to receive(:symlink?).with(any_args).and_call_original
  end

  context 'service is currently enabled, bootstrapped and is running' do
    before do
      services.each do |service|
        stub_should_notify?(service, true)
      end
      stub_gitlab_rb(nginx: { enable: true })
    end

    it 'notifies the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).to notify('runit_service[nginx]').to(:restart).delayed
    end
  end

  context 'disabling a service that was bootstrapped and is currently running' do
    before do
      services.each do |service|
        stub_should_notify?(service, true)
      end
      stub_gitlab_rb(nginx: { enable: false })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('runit_service[nginx]').to(:restart).delayed
    end
  end

  context 'enabling a service that was bootstrapped but not currently running' do
    before do
      services.each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(true)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/init/#{service} status").and_return(false)
      end
      stub_gitlab_rb(nginx: { enable: true })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('runit_service[nginx]').to(:restart).delayed
    end
  end

  context 'disabling a service that was bootstrapped but not currently running' do
    before do
      services.each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(true)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/init/#{service} status").and_return(false)
      end
      stub_gitlab_rb(nginx: { enable: false })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('runit_service[nginx]').to(:restart).delayed
    end
  end

  context 'enabling a service that was disabled but currently running' do
    before do
      services.each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(false)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/init/#{service} status").and_return(true)
      end
      stub_gitlab_rb(nginx: { enable: true })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('runit_service[nginx]').to(:restart).delayed
    end
  end

  context 'disabling a service that was disabled but currently running' do
    before do
      services.each do |service|
        allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(false)
        allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/init/#{service} status").and_return(true)
      end
      stub_gitlab_rb(nginx: { enable: false })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('runit_service[nginx]').to(:restart).delayed
    end
  end

  context 'enabling a service that was disabled and not currently running' do
    before do
      services.each do |service|
        stub_should_notify?(service, false)
      end
      stub_gitlab_rb(nginx: { enable: true })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('runit_service[nginx]').to(:restart).delayed
    end
  end

  context 'disabling a service that was disabled and not currently running' do
    before do
      services.each do |service|
        stub_should_notify?(service, false)
      end
      stub_gitlab_rb(nginx: { enable: false })
    end

    it 'does not notify the service' do
      expect(chef_run.template('/var/opt/gitlab/nginx/conf/gitlab-http.conf')).not_to notify('runit_service[nginx]').to(:restart).delayed
    end
  end

  context 'expected_owner?' do
    let(:oh) { OmnibusHelper.new(chef_run.node) }
    before do
      allow_any_instance_of(OmnibusHelper).to receive(:expected_owner?)
        .and_call_original
      allow_any_instance_of(OmnibusHelper).to receive(
        :expected_user?).and_return(false)
      allow_any_instance_of(OmnibusHelper).to receive(
        :expected_user?
      ).with('/tmp/fakefile', 'fakeuser').and_return(true)
      allow_any_instance_of(OmnibusHelper).to receive(
        :expected_group?).and_return(false)
      allow_any_instance_of(OmnibusHelper).to receive(
        :expected_group?
      ).with('/tmp/fakefile', 'fakegroup').and_return(true)
    end

    it 'should return false if the group is wrong' do
      expect(oh.expected_owner?('/tmp/fakefile', 'fakeuser', 'wronggroup'))
        .to be false
    end

    it 'should return false if the user is wrong' do
      expect(oh.expected_owner?('/tmp/fakefile', 'wronguser', 'fakegroup'))
        .to be false
    end

    it 'should return true if user and group is correct' do
      expect(oh.expected_owner?('/tmp/fakefile', 'fakeuser', 'fakegroup'))
        .to be true
    end
  end
end
