require 'spec_helper'
require_relative '../../../files/gitlab-cookbooks/package/libraries/helpers/gitlab_cluster_helper'

RSpec.describe GitlabClusterHelper do
  let(:gitlab_cluster_config_path) { described_class::JSON_FILE }

  describe '.config_available?' do
    context 'when cluster configuration file exists' do
      it 'returns true' do
        allow(File).to receive(:exist?).with(gitlab_cluster_config_path).and_return(true)

        expect(described_class.config_available?).to eq(true)
      end
    end

    context 'when cluster configuration file does not exist' do
      it 'returns false' do
        expect(described_class.config_available?).to eq(false)
      end
    end
  end

  describe '#config' do
    context 'when the cluster configuration file does not exist' do
      it 'returns an empty hash' do
        expect(subject.config).to be_empty
      end
    end

    context 'when the cluster configuration file exists' do
      it 'parses the file content' do
        stub_file_content(gitlab_cluster_config_path, foo: 'bar')

        expect(subject.config).to eq('foo' => 'bar')
      end
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
        .not_to receive(:warning)
        .with("The geo_primary_role is defined in #{gitlab_cluster_config_path} as primary and takes priority over the role in the /etc/gitlab/gitlab.rb")

      expect(LoggingHelper)
        .to receive(:warning)
        .with("The geo_secondary_role is defined in #{gitlab_cluster_config_path} as secondary and takes priority over the role in the /etc/gitlab/gitlab.rb")
        .once

      subject.load_roles!
    end
  end

  describe '#write_to_file!' do
    let(:config_path) { Dir.mktmpdir }
    let(:gitlab_cluster_config_path) { File.join(config_path, 'gitlab-cluster.json') }

    before do
      stub_const('GitlabClusterHelper::CONFIG_PATH', config_path)
      stub_const('GitlabClusterHelper::JSON_FILE', gitlab_cluster_config_path)
    end

    after do
      FileUtils.rm_rf(config_path)
    end

    context 'when the config directory does not exist' do
      it 'does not create the configuration file' do
        FileUtils.rm_rf(config_path)

        subject.write_to_file!

        expect(File.exist?(gitlab_cluster_config_path)).to eq(false)
      end
    end

    context 'when the cluster configuration file does not exist' do
      it 'creates the configuration file' do
        FileUtils.rm_rf(gitlab_cluster_config_path)

        subject.write_to_file!

        expect(File.exist?(gitlab_cluster_config_path)).to eq(true)
        expect(read_file_content(gitlab_cluster_config_path)).to be_empty
      end
    end

    context 'when the cluster configuration file exists' do
      it 'overrides previous settings' do
        write_file_content(gitlab_cluster_config_path, foo: 'bar', zoo: true)
        subject.config['zoo'] = false

        subject.write_to_file!

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
