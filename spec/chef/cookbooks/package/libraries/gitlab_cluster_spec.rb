require 'spec_helper'

RSpec.describe GitlabCluster, :cluster_config do
  let(:gitlab_cluster_config_path) { described_class::JSON_FILE }
  subject { described_class.config }

  describe '#all' do
    context 'when the cluster configuration file does not exist' do
      it 'returns an empty hash' do
        expect(subject.all).to be_empty
      end
    end

    context 'when the cluster configuration file exists' do
      it 'parses the file content' do
        stub_file_content(gitlab_cluster_config_path, foo: 'bar')

        expect(subject.all).to eq('foo' => 'bar')
      end
    end
  end

  describe '#set' do
    it 'set the value of a single config option' do
      subject.set('primary', true)

      expect(subject.all).to eq('primary' => true)
    end

    it 'sets the value of a nested config option' do
      subject.set('patroni', 'standby_cluster', 'enable', true)

      expect(subject.all).to eq('patroni' => { 'standby_cluster' => { 'enable' => true } })
    end

    it 'overrides the key value if it already set' do
      stub_file_content(gitlab_cluster_config_path, patroni: { standby_cluster: { enable: false } })

      subject.set('patroni', 'standby_cluster', 'enable', true)

      expect(subject.all).to eq('patroni' => { 'standby_cluster' => { 'enable' => true } })
    end
  end

  describe '#get' do
    before do
      stub_file_content(gitlab_cluster_config_path, primary: false, patroni: { standby_cluster: { enable: true } })
    end

    it 'get the value of a single config option if the key exists' do
      expect(subject.get('primary')).to eq(false)
    end

    it 'get the value of a nested config option if the key exists' do
      expect(subject.get('patroni', 'standby_cluster', 'enable')).to eq(true)
    end

    it 'returns nil if the key does not exist' do
      expect(subject.get('foo', 'bar')).to be_nil
    end
  end

  describe '#load_roles!' do
    before do
      stub_gitlab_rb(application_role: { enable: true }, geo_primary_role: { enable: nil }, geo_secondary_role: { enable: true })
    end

    it 'overrides roles defined in the configuration file' do
      stub_file_content(gitlab_cluster_config_path, secondary: false)

      subject.load_roles!

      expect(Gitlab['application_role']['enable']).to eq(true)
      expect(Gitlab['geo_secondary_role']['enable']).to eq(false)
    end

    it 'does not override roles not defined in the configuration file' do
      stub_file_content(gitlab_cluster_config_path, {})

      subject.load_roles!

      expect(Gitlab['application_role']['enable']).to eq(true)
      expect(Gitlab['geo_secondary_role']['enable']).to eq(true)
    end

    it 'prints a warning message for each enabled role defined in the configuration file' do
      stub_file_content(gitlab_cluster_config_path, primary: true, secondary: false)

      expect(LoggingHelper)
        .to receive(:warning)
        .with("The 'geo_primary_role' is defined in #{gitlab_cluster_config_path} as 'true' and overrides the setting in the /etc/gitlab/gitlab.rb")

      expect(LoggingHelper)
        .to receive(:warning)
        .with("The 'geo_secondary_role' is defined in #{gitlab_cluster_config_path} as 'false' and overrides the setting in the /etc/gitlab/gitlab.rb")
        .once

      subject.load_roles!
    end
  end

  describe '#write_to_file!' do
    let(:config_path) { Dir.mktmpdir }
    let(:gitlab_cluster_config_path) { File.join(config_path, 'gitlab-cluster.json') }

    before do
      stub_const('GitlabCluster::CONFIG_PATH', config_path)
      stub_const('GitlabCluster::JSON_FILE', gitlab_cluster_config_path)
    end

    after do
      FileUtils.rm_rf(config_path)
    end

    context 'when the config directory does not exist' do
      it 'does not create the configuration file' do
        FileUtils.rm_rf(config_path)

        subject.save

        expect(File.exist?(gitlab_cluster_config_path)).to eq(false)
      end
    end

    context 'when the cluster configuration file does not exist' do
      it 'creates the configuration file' do
        FileUtils.rm_rf(gitlab_cluster_config_path)

        subject.save

        expect(File.exist?(gitlab_cluster_config_path)).to eq(true)
        expect(read_file_content(gitlab_cluster_config_path)).to be_empty
      end
    end

    context 'when the cluster configuration file exists' do
      it 'overrides previous settings' do
        write_file_content(gitlab_cluster_config_path, foo: 'bar', zoo: true)
        subject.set('zoo', false)

        subject.save

        expect(read_file_content(gitlab_cluster_config_path)).to eq("foo" => "bar", "zoo" => false)
      end
    end
  end

  def stub_file_content(fullpath, content)
    allow(File).to receive(:exist?).with(fullpath).and_return(true)
    allow(IO).to receive(:read).with(fullpath).and_return(content.to_json)
  end

  def read_file_content(fullpath)
    JSON.parse(File.read(fullpath))
  end

  def write_file_content(fullpath, content)
    File.open(fullpath, 'w') do |f|
      f.write(content.to_json)
      f.chmod(0600)
    end
  end
end
