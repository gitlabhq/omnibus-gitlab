require 'spec_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')

require 'gitlab_ctl'

RSpec.describe GitlabCtl::PgUpgrade do
  let(:ctl) { double(base_path: '/fakebasedir', data_path: '/fake/data') }

  describe '.parse_options' do
    subject(:pg_upgrade) { described_class }

    it 'defaults :skip_multi_node to false' do
      options = pg_upgrade.parse_options([])

      expect(options[:skip_multi_node]).to eq(false)
    end

    it 'accepts --skip-multi-node and sets :skip_multi_node to true' do
      options = pg_upgrade.parse_options(['--skip-multi-node'])

      expect(options[:skip_multi_node]).to eq(true)
    end

    it 'leaves existing options unchanged when --skip-multi-node is passed' do
      options = pg_upgrade.parse_options(%w[-w --skip-disk-check --skip-multi-node])

      expect(options[:wait]).to eq(false)
      expect(options[:skip_disk_check]).to eq(true)
      expect(options[:skip_multi_node]).to eq(true)
    end
  end

  before do
    allow(GitlabCtl::Util).to receive(:get_command_output).with(
      "/fakebasedir/embedded/bin/pg_ctl --version"
    ).and_return('fakeoldverision')
    allow(GitlabCtl::Util).to receive(:roles).and_return([])
  end

  context 'with a default configuration' do
    let(:fake_default_dir) { '/fake/data/postgresql/data' }

    subject(:dbw) { GitlabCtl::PgUpgrade.new(ctl, 'fakenewversion', nil, 123) }

    before do
      stub_postgresql_json_attributes
    end

    it 'should create a new object' do
      expect(dbw).to be_instance_of(GitlabCtl::PgUpgrade)
    end

    it 'should use the specified timeout' do
      expect(dbw.timeout).to eq(123)
    end

    it 'should set tmp_data_dir to data_dir if tmp_dir is nil on initialization' do
      allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return({})

      expect(dbw.tmp_data_dir).to eq(dbw.data_dir)
    end

    it 'should return the appropriate data version' do
      stub_postgresql_json_attributes
      allow(File).to receive(:read).with(
        File.join(fake_default_dir, 'PG_VERSION')
      ).and_return("99.99\n")

      expect(dbw.fetch_data_version).to eq('99.99')
    end

    context 'when determining if there is enough free space to perform an upgrade' do
      before do
        stub_postgresql_json_attributes
      end

      it 'detects when there is not enough available disk space for upgrade' do
        allow(GitlabCtl::Util).to receive(:get_command_output).with(
          "du -s --block-size=1m #{dbw.data_dir}", nil, 123
        ).and_return("200000\n#{dbw.data_dir}")

        allow(GitlabCtl::Util).to receive(:get_command_output).with(
          "df -P --block-size=1m #{dbw.data_dir} | awk '{print $4}'", nil, 123
        ).and_return("Available\n220000")

        expect(dbw.enough_free_space?(dbw.data_dir, 440000)).to eq(false)
      end

      it 'detects when there is enough available disk space for upgrade' do
        allow(GitlabCtl::Util).to receive(:get_command_output).with(
          "du -s --block-size=1m #{dbw.data_dir}", nil, 123
        ).and_return("200000\n#{dbw.data_dir}")

        allow(GitlabCtl::Util).to receive(:get_command_output).with(
          "df -P --block-size=1m #{dbw.data_dir} | awk '{print $4}'", nil, 123
        ).and_return("Available\n250000")

        expect(dbw.enough_free_space?(dbw.data_dir, 100000)).to eq(true)
      end
    end

    describe '#pg_upgrade_disabled?' do
      it 'returns true when the disable file exists' do
        allow(File).to receive(:exist?).with('/etc/gitlab/disable-postgresql-upgrade').and_return(true)

        expect(dbw.pg_upgrade_disabled?).to be true
      end

      it 'returns false when the disable file does not exist' do
        allow(File).to receive(:exist?).with('/etc/gitlab/disable-postgresql-upgrade').and_return(false)

        expect(dbw.pg_upgrade_disabled?).to be false
      end
    end

    context 'when a failed upgrade attempt happened' do
      let(:target_data_dir) { "future_data_dir" }

      before do
        allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return({})
      end

      describe '#upgrade_artifact_exists?' do
        it 'returns false when the directory does not exist' do
          expect(dbw.upgrade_artifact_exists?(target_data_dir)).to be false
        end

        it 'returns false when the directory exists with no data' do
          allow(File).to receive(:exist?).with(target_data_dir).and_return(true)
          allow(Dir).to receive(:empty?).with(target_data_dir).and_return(true)

          expect(dbw.upgrade_artifact_exists?(target_data_dir)).to be false
        end

        it 'returns true when the directory exists with data' do
          allow(File).to receive(:exist?).with(target_data_dir).and_return(true)
          allow(Dir).to receive(:empty?).with(target_data_dir).and_return(false)

          expect(dbw.upgrade_artifact_exists?(target_data_dir)).to be true
        end
      end
    end
  end

  it 'should use the configured port when running pg_upgrade' do
    stub_postgresql_json_attributes({ 'port' => '1959' })
    dbw = GitlabCtl::PgUpgrade.new(ctl, 'fakenewversion', nil, 123)

    expect(dbw.port).to eq('1959')
  end

  it 'should call pg_command with the appropriate command' do
    stub_postgresql_json_attributes({ 'username' => 'arbitrary-user-name' })
    dbw = GitlabCtl::PgUpgrade.new(ctl, 'fakenewversion', nil, 123)

    expect(GitlabCtl::Util).to receive(
      :get_command_output
    ).with('su - arbitrary-user-name -c "fake command"', nil, 123)

    dbw.run_pg_command('fake command')
  end

  context 'when an explicit data directory is specified' do
    it 'should use it as data_dir' do
      stub_postgresql_json_attributes({ 'dir' => 'randomdir' })
      dbw = GitlabCtl::PgUpgrade.new(ctl, 'fakenewversion', nil, 123)

      expect(dbw.data_dir).to eq('randomdir/data')
    end
  end

  context 'when an explicit data directory is not specified' do
    it 'should use find data_dir using dir/data' do
      stub_postgresql_json_attributes({ 'dir' => 'parentdir' })
      dbw = GitlabCtl::PgUpgrade.new(ctl, 'fakenewversion', nil, 123)

      expect(dbw.data_dir).to eq('parentdir/data')
    end
  end

  describe '#geo_primary_role?' do
    subject(:dbw) { GitlabCtl::PgUpgrade.new(ctl, 'fakenewversion', nil, 123) }

    before do
      stub_postgresql_json_attributes
    end

    context 'when geo_primary role is enabled' do
      before do
        allow(GitlabCtl::Util).to receive(:roles).and_return(['geo_primary'])
      end

      it 'returns true' do
        expect(dbw.geo_primary_role?).to be true
      end
    end

    context 'when geo_primary role is not enabled' do
      before do
        allow(GitlabCtl::Util).to receive(:roles).and_return([])
      end

      it 'returns false' do
        expect(dbw.geo_primary_role?).to be false
      end
    end
  end

  describe '#geo_secondary_role?' do
    subject(:dbw) { GitlabCtl::PgUpgrade.new(ctl, 'fakenewversion', nil, 123) }

    before do
      stub_postgresql_json_attributes
    end

    context 'when geo_secondary role is enabled' do
      before do
        allow(GitlabCtl::Util).to receive(:roles).and_return(['geo_secondary'])
      end

      it 'returns true' do
        expect(dbw.geo_secondary_role?).to be true
      end
    end

    context 'when geo_secondary role is not enabled' do
      before do
        allow(GitlabCtl::Util).to receive(:roles).and_return([])
      end

      it 'returns false' do
        expect(dbw.geo_secondary_role?).to be false
      end
    end
  end

  describe '#patroni_service_enabled?' do
    subject(:dbw) { GitlabCtl::PgUpgrade.new(ctl, 'fakenewversion', nil, 123) }

    before { stub_postgresql_json_attributes }

    context 'when patroni service is enabled' do
      before { allow(ctl).to receive(:service_enabled?).with('patroni').and_return(true) }

      it 'returns true' do
        expect(dbw.patroni_service_enabled?).to be true
      end
    end

    context 'when patroni service is not enabled' do
      before { allow(ctl).to receive(:service_enabled?).with('patroni').and_return(false) }

      it 'returns false' do
        expect(dbw.patroni_service_enabled?).to be false
      end
    end
  end

  describe '#postgres_service_enabled?' do
    subject(:dbw) { GitlabCtl::PgUpgrade.new(ctl, 'fakenewversion', nil, 123) }

    before { stub_postgresql_json_attributes }

    context 'when postgresql service is enabled' do
      before { allow(ctl).to receive(:service_enabled?).with('postgresql').and_return(true) }

      it 'returns true' do
        expect(dbw.postgres_service_enabled?).to be true
      end
    end

    context 'when postgresql service is not enabled' do
      before { allow(ctl).to receive(:service_enabled?).with('postgresql').and_return(false) }

      it 'returns false' do
        expect(dbw.postgres_service_enabled?).to be false
      end
    end
  end

  describe '#geo_postgres_service_enabled?' do
    subject(:dbw) { GitlabCtl::PgUpgrade.new(ctl, 'fakenewversion', nil, 123) }

    before { stub_postgresql_json_attributes }

    context 'when geo-postgresql service is enabled' do
      before { allow(ctl).to receive(:service_enabled?).with('geo-postgresql').and_return(true) }

      it 'returns true' do
        expect(dbw.geo_postgres_service_enabled?).to be true
      end
    end

    context 'when geo-postgresql service is not enabled' do
      before { allow(ctl).to receive(:service_enabled?).with('geo-postgresql').and_return(false) }

      it 'returns false' do
        expect(dbw.geo_postgres_service_enabled?).to be false
      end
    end
  end

  def stub_postgresql_json_attributes(config = nil)
    options = config || {}
    options['port'] ||= '5432'
    node_data = { postgresql: options.transform_keys(&:to_sym) }
    public_data = { 'postgresql' => options }
    allow(GitlabCtl::Util).to receive(:get_node_attributes).and_return(node_data)
    allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return(public_data)
  end
end
