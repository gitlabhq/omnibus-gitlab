require 'chef_helper'

describe BasePgHelper do
  cached(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  subject { described_class.new(node) }

  before do
    allow(subject).to receive(:service_name) { 'postgresql' }
    allow(subject).to receive(:service_cmd) { 'gitlab-psql' }
  end

  describe '#database_exists?' do
    it 'calls out to psql_cmd' do
      expect(subject).to receive(:psql_cmd).with(
        [
          "-d 'template1'",
          "-c 'select datname from pg_database' -A",
          '| grep -x example'
        ])
      subject.database_exists?('example')
    end

    context 'database present' do
      it 'truthy' do
        allow(subject).to receive(:psql_cmd) { true }
        expect(subject.database_exists?('example')).to be_truthy
      end

      it 'falsey' do
        allow(subject).to receive(:psql_cmd) { false }
        expect(subject.database_exists?('example')).to be_falsey
      end
    end
  end

  describe '#extension_enabled?' do
    it 'will check with psql_cmd when database present' do
      expect(subject).to receive(:psql_cmd).with(
        [
          "-d 'database'",
          "-c 'select extname from pg_extension' -A",
          '| grep -x extension'
        ])
      subject.extension_enabled?('extension', 'database')
    end

    context 'extension present' do
      it 'truthy' do
        allow(subject).to receive(:psql_cmd) { true }
        expect(subject.extension_enabled?('extension', 'database')).to be_truthy
      end

      it 'falsey' do
        allow(subject).to receive(:psql_cmd) { false }
        expect(subject.extension_enabled?('extension', 'database')).to be_falsey
      end
    end
  end

  describe '#extension_can_be_enabled?' do
    before do
      allow(subject).to receive(:is_running?).and_return(true)
      allow(subject).to receive(:is_slave?).and_return(false)
      allow(subject).to receive(:extension_exists?).and_return(true)
      allow(subject).to receive(:database_exists?).and_return(true)
      allow(subject).to receive(:extension_enabled?).and_return(false)
    end

    it 'can be enabled' do
      expect(subject.extension_can_be_enabled?('extension', 'db')).to be_truthy
    end

    it 'needs to be running' do
      allow(subject).to receive(:is_running?).and_return(false)
      expect(subject.extension_can_be_enabled?('extension', 'db')).to be_falsey
    end

    it 'cannot be done on a slave' do
      allow(subject).to receive(:is_slave?).and_return(true)
      expect(subject.extension_can_be_enabled?('extension', 'db')).to be_falsey
    end

    it 'needs to have the extension available' do
      allow(subject).to receive(:extension_exists?).and_return(false)
      expect(subject.extension_can_be_enabled?('extension', 'db')).to be_falsey
    end

    it 'needs the database to load the extension into' do
      allow(subject).to receive(:database_exists?).and_return(false)
      expect(subject.extension_can_be_enabled?('extension', 'db')).to be_falsey
    end

    it 'should not enable twice' do
      allow(subject).to receive(:extension_enabled?).and_return(true)
      expect(subject.extension_can_be_enabled?('extension', 'db')).to be_falsey
    end
  end

  describe '#user_options' do
    before do
      result = spy('shellout')
      allow(result).to receive(:stdout).and_return("f|f|t|f\n")
      allow(subject).to receive(:do_shell_out).and_return(result)
    end

    it 'returns hash from query' do
      expect(subject.user_options('')).to eq(
        {
          'SUPERUSER' => false,
          'CREATEDB' => false,
          'REPLICATION' => true,
          'BYPASSRLS' => false
        }
      )
    end
  end

  describe '#user_options_set?' do
    let(:default_options) do
      {
        'SUPERUSER' => false,
        'CREATEDB' => false,
        'REPLICATION' => true,
        'BYPASSRLS' => false
      }
    end

    context 'default user options' do
      before do
        allow(subject).to receive(:user_options).and_return(default_options)
      end

      it 'returns true when no options are asked about' do
        expect(subject.user_options_set?('', [])).to be_truthy
      end

      it 'returns true when options are set to their defaults' do
        expect(subject.user_options_set?('', ['NOSUPERUSER'])).to be_truthy
      end

      it 'returns false when options are set away from their defaults' do
        expect(subject.user_options_set?('', ['SUPERUSER'])).to be_falsey
      end
    end

    context 'modified user' do
      before do
        allow(subject).to receive(:user_options).and_return(default_options.merge({ 'SUPERUSER' => true }))
      end

      it 'returns false when options is not what we expect' do
        expect(subject.user_options_set?('', ['NOSUPERUSER'])).to be_falsey
      end
    end
  end

  describe '#user_password_match?' do
    before do
      # user: gitlab pass: test123
      allow(subject).to receive(:user_hashed_password) { 'md5b56573ef0d94cff111898c63ec259f3f' }
    end

    it 'returns true when same password is in plain-text' do
      expect(subject.user_password_match?('gitlab', 'test123')).to be_truthy
    end

    it 'returns true when same password is in MD5 format' do
      expect(subject.user_password_match?('gitlab', 'md5b56573ef0d94cff111898c63ec259f3f')).to be_truthy
    end

    it 'returns false when wrong password is in plain-text' do
      expect(subject.user_password_match?('gitlab', 'wrong')).to be_falsey
    end

    it 'returns false when wrong password is in MD5 format' do
      expect(subject.user_password_match?('gitlab', 'md5b599de4332636c03a60fca13be1edb5f')).to be_falsey
    end

    it 'returns false when password is not supplied' do
      expect(subject.user_password_match?('gitlab', nil)).to be_falsey
    end

    context 'nil password' do
      before do
        # user: gitlab pass: unset
        allow(subject).to receive(:user_hashed_password) { '' }
      end

      it 'returns true when the password is nil' do
        expect(subject.user_password_match?('gitlab', nil)).to be_truthy
      end
    end
  end

  describe '#parse_pghash' do
    let(:payload) { '{host=127.0.0.1,dbname=gitlabhq_production,port=5432,user=gitlab,"password=foo}bar\"zoo\\cat"}' }

    it 'returns a hash' do
      expect(subject.parse_pghash(payload)).to be_a(Hash)
    end

    it 'when content is empty still return a hash' do
      expect(subject.parse_pghash('')).to be_a(Hash)
      expect(subject.parse_pghash('{}')).to be_a(Hash)
    end

    it 'returns hash with expected keys' do
      hash = subject.parse_pghash(payload)

      expect(hash.keys).to contain_exactly(:host, :dbname, :port, :user, :password)
    end

    it 'returns hash with expected values' do
      hash = subject.parse_pghash(payload)

      expect(hash.values).to contain_exactly('127.0.0.1', 'gitlabhq_production', '5432', 'gitlab', 'foo}bar"zoo\cat')
    end
  end

  describe '#is_running?' do
    it 'returns true when postgres is running' do
      stub_service_success_status('postgresql', true)

      expect(subject.is_running?).to be_truthy
    end

    it 'returns false when postgres is not running' do
      stub_service_success_status('postgresql', false)

      expect(subject.is_running?).to be_falsey
    end
  end

  describe '#is_managed_and_offline?' do
    it 'returns true when conditions are met' do
      chef_run.node.normal['postgresql']['enable'] = true
      stub_service_failure_status('postgresql', true)

      expect(subject.is_managed_and_offline?).to be_truthy
    end

    it 'returns false when conditions are not met' do
      chef_run.node.normal['postgresql']['enable'] = true
      stub_service_failure_status('postgresql', false)

      expect(subject.is_managed_and_offline?).to be_falsey

      chef_run.node.normal['postgresql']['enable'] = false
      stub_service_failure_status('postgresql', false)

      expect(subject.is_managed_and_offline?).to be_falsey

      stub_service_failure_status('postgresql', true)
      expect(subject.is_managed_and_offline?).to be_falsey
    end
  end

  describe '#fdw_external_password_exists?' do
    it 'returns true when the password exists in the options hash' do
      expect(subject).to receive(:psql_query).and_return('{user=gitlab,password=foo}')

      expect(subject.fdw_external_password_exists?('gitlab_geo', 'gitlab_secondary', 'gitlabhq_geo_production')).to be_truthy
    end

    it 'returns false when the password does not exist in the options hash' do
      expect(subject).to receive(:psql_query).and_return('{user=gitlab}')

      expect(subject.fdw_external_password_exists?('gitlab_geo', 'gitlab_secondary', 'gitlabhq_geo_production')).to be_falsey
    end
  end

  describe '#fdw_user_mapping_update_options' do
    let(:resource) { double(:resource, db_user: 'gitlab_geo', server_name: 'gitlab_secondary', db_name: 'gitlabhq_geo_production', external_user: 'gitlab', external_password: 'mypass') }

    it 'SETs the desired password when the password exists' do
      expect(subject).to receive(:fdw_external_password_exists?).and_return(true)

      result = subject.fdw_user_mapping_update_options(resource)
      expect(result).to eq("SET user 'gitlab', SET password 'mypass'")
    end

    it 'ADDs the desired password when the password does not exist' do
      expect(subject).to receive(:fdw_external_password_exists?).and_return(false)

      result = subject.fdw_user_mapping_update_options(resource)
      expect(result).to eq("SET user 'gitlab', ADD password 'mypass'")
    end
  end
end
