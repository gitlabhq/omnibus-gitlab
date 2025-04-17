require 'spec_helper'

$LOAD_PATH << File.join(__dir__, '../../../../files/gitlab-ctl-commands-ee/lib')

require 'gitlab_ctl/pgbouncer'

RSpec.describe GitlabCtl::Pgbouncer::Databases do
  let(:fake_ohai) do
    {
      'gitlab' => {
        'gitlab_rails' => {
          'db_database' => 'fake_database',
          'databases' => {
            'main' => 'fake_database',
            'ci' => 'fake_database_ci'
          },
        },
      },
      'pgbouncer' => {
        'databases_ini' => '/fakedata/pgbouncer/databases.ini',
        'databases_json' => '/fakedata/pgbouncer/databases.json'
      }
    }
  end

  let(:fake_databases_json) do
    {
      fakedb: {
        host: 'fakehost',
        user: 'fakeuser',
        port: 9999,
        password: 'dslgkjdfgklfsd'
      }
    }.to_json.to_s
  end

  before do
    allow(GitlabCtl::Util).to receive(:get_fqdn).and_return('fakehost')
    allow(Dir).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).with('/fakedata/pgbouncer').and_return(true)
    allow(File).to receive(:exist?).with('/fakedata/pgbouncer/databases.json').and_return(true)
    allow(File).to receive(:read).and_call_original
    allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return(fake_ohai)
    allow(File).to receive(:read).with('/fakedata/pgbouncer/databases.json').and_return(fake_databases_json)
    @obj = GitlabCtl::Pgbouncer::Databases.new({}, '/fakeinstall', '/fakedata')
  end

  context 'default behavior' do
    it 'allows creating a new object' do
      expect(@obj.class).to be(GitlabCtl::Pgbouncer::Databases)
    end

    it 'creates the database object' do
      results = {
        "fakedb" => "host=fakehost port=9999 auth_user=fakeuser"
      }
      expect(@obj.databases).to eq(results)
    end

    it 'renders the template' do
      expect(@obj.render).to eq(
        "[databases]\n\nfakedb = host=fakehost port=9999 auth_user=fakeuser\n\n"
      )
    end
  end

  context 'with options' do
    before do
      options = {
        'databases_ini' => '/another/databases.ini',
        'databases_json' => '/another/databases.json',
        'port' => 8888,
        'user' => 'fakeuser',
        'database' => 'fakedb'
      }
      allow(File).to receive(:exist?).with('/another/databases.json').and_return(true)
      allow(File).to receive(:read).with('/another/databases.json').and_return(fake_databases_json)
      @obj = GitlabCtl::Pgbouncer::Databases.new(options, '/fakeinstall', '/fakedata')
    end

    it 'sets the custom options' do
      expect(@obj.ini_file).to eq('/another/databases.ini')
      expect(@obj.json_file).to eq('/another/databases.json')
    end

    it 'renders the template' do
      expect(@obj.render).to eq(
        "[databases]\n\nfakedb = host=fakehost port=8888 auth_user=fakeuser\n\n"
      )
    end
  end

  context 'with empty databases.json' do
    before do
      allow(File).to receive(:read).with('/fakedata/pgbouncer/databases.json').and_return({}.to_s)
      @obj = GitlabCtl::Pgbouncer::Databases.new({}, '/fakeinstall', '/fakedata')
    end

    it 'should generate an databases.ini with the default rails database' do
      expect(@obj.render).to eq(
        "[databases]\n\nfake_database = dbname=fake_database\n\nfake_database_ci = dbname=fake_database_ci\n\n"
      )
    end
  end

  context 'with empty databases.json AND component_databases registered (regression)' do
    # When databases.json is empty (bootstrap / recovery), the fallback
    # must seed from the full Patroni-replicated set, not just the Rails
    # DBs. Without this, registered component DBs are silently absent from
    # the failover update path even though they belong on the cluster.
    let(:logical_ohai) do
      fake_ohai.merge(
        'postgresql' => {
          'component_databases' => {
            'gate' => { 'enable' => true, 'user' => 'gate', 'database' => 'gate_production' }
          }
        }
      )
    end

    before do
      allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return(logical_ohai)
      allow(File).to receive(:read).with('/fakedata/pgbouncer/databases.json').and_return({}.to_s)
    end

    it 'includes the component database in the fallback-seeded set' do
      obj = GitlabCtl::Pgbouncer::Databases.new({ 'newhost' => 'newhost.local' }, '/fakeinstall', '/fakedata')
      expect(obj.databases).to have_key('gate_production')
      expect(obj.databases['gate_production']).to include('host=newhost.local')
      expect(obj.databases['gate_production']).to include('dbname=gate_production')
    end
  end

  context 'with pgbouncer listening' do
    before do
      allow(@obj).to receive(:show_databases).and_return("nyan")
    end

    it 'should be running' do
      expect(@obj.running?).to be true
    end
  end

  context 'with pgbouncer not listening' do
    before do
      allow(@obj).to receive(:show_databases).and_raise(GitlabCtl::Errors::ExecutionError.new("nya", "nya", "neko"))
    end

    it 'should not be running' do
      expect(@obj.running?).to be false
    end
  end

  context 'with component_databases registered' do
    let(:logical_ohai) do
      fake_ohai.merge(
        'postgresql' => {
          'component_databases' => {
            'gate' => { 'enable' => true, 'user' => 'gate', 'database' => 'gate_production' },
            'disabled_one' => { 'enable' => false, 'user' => 'nope' }
          }
        }
      )
    end

    let(:json_with_logical) do
      {
        fakedb: { host: 'fakehost', user: 'fakeuser', port: 9999 },
        gate_production: { host: 'oldhost', auth_user: 'pgbouncer', port: 5432 }
      }.to_json.to_s
    end

    before do
      allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return(logical_ohai)
      allow(File).to receive(:read).with('/fakedata/pgbouncer/databases.json').and_return(json_with_logical)
    end

    it 'propagates --newhost to enabled component databases' do
      obj = GitlabCtl::Pgbouncer::Databases.new({ 'newhost' => 'newhost.local' }, '/fakeinstall', '/fakedata')
      expect(obj.databases['gate_production']).to include('host=newhost.local')
    end

    it 'returns only enabled entries from component_database_names' do
      obj = GitlabCtl::Pgbouncer::Databases.new({}, '/fakeinstall', '/fakedata')
      expect(obj.component_database_names).to eq(['gate_production'])
    end
  end

  context 'with multiple component databases (regression: dbname cross-contamination)' do
    let(:multi_ohai) do
      fake_ohai.merge(
        'postgresql' => {
          'component_databases' => {
            'gate' => { 'enable' => true, 'user' => 'gate',    'database' => 'gate_production' },
            'openbao' => { 'enable' => true, 'user' => 'openbao', 'database' => 'openbao' }
          }
        }
      )
    end

    let(:multi_json) do
      {
        gate_production: { host: 'oldhost', auth_user: 'pgbouncer', port: 5432 },
        openbao: { host: 'oldhost', auth_user: 'pgbouncer', port: 5432 }
      }.to_json.to_s
    end

    before do
      allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return(multi_ohai)
      allow(File).to receive(:read).with('/fakedata/pgbouncer/databases.json').and_return(multi_json)
    end

    it 'sets dbname to each entry name, not the --pg-database target' do
      options = { 'pg_database' => 'gate_production', 'newhost' => 'newhost.local' }
      obj = GitlabCtl::Pgbouncer::Databases.new(options, '/fakeinstall', '/fakedata')

      expect(obj.databases['gate_production']).to include('dbname=gate_production')
      expect(obj.databases['openbao']).to include('dbname=openbao')
      expect(obj.databases['openbao']).not_to include('dbname=gate_production')
    end
  end

  context 'with malformed component_databases entries' do
    let(:malformed_ohai) do
      fake_ohai.merge(
        'postgresql' => {
          'component_databases' => {
            'bogus' => 'not a hash',
            'nilval' => nil,
            'ok' => { 'enable' => true, 'user' => 'ok' }
          }
        }
      )
    end

    before do
      allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return(malformed_ohai)
    end

    it 'ignores non-Hash entries' do
      obj = GitlabCtl::Pgbouncer::Databases.new({}, '/fakeinstall', '/fakedata')
      expect(obj.component_database_names).to eq(['ok'])
    end
  end

  context 'when postgresql.component_databases is absent' do
    let(:no_logical_ohai) { fake_ohai.merge('postgresql' => {}) }

    before do
      allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return(no_logical_ohai)
    end

    it 'returns an empty list' do
      obj = GitlabCtl::Pgbouncer::Databases.new({}, '/fakeinstall', '/fakedata')
      expect(obj.component_database_names).to eq([])
    end
  end
end
