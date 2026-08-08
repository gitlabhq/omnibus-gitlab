require 'spec_helper'
require 'gitlab/version'

RSpec.describe Gitlab::Version do
  before do
    allow(ENV).to receive(:[]).and_call_original
    stub_env_var('GITLAB_ALTERNATIVE_REPO', nil)
    stub_env_var('ALTERNATIVE_PRIVATE_TOKEN', nil)
  end

  describe '.sources_channel' do
    subject { described_class }
    using RSpec::Parameterized::TableSyntax
    where(:alternative_sources, :security_sources, :source_channel) do
      nil | nil | "alternative"
      nil | 'true' | "security"
      nil | 'false' | "alternative"
      'true' | nil | "alternative"
      'true' | 'true' | "security"
      'true' | 'false' | "alternative"
      'false' | nil | "remote"
      'false' | 'true' | "security"
      'false' | 'false' | "remote"
    end

    with_them do
      before do
        stub_env_var('ALTERNATIVE_SOURCES', alternative_sources)
        stub_env_var('SECURITY_SOURCES', security_sources)
      end

      context 'when checking the source channel environment variables' do
        it 'uses the correct source channel' do
          expect(subject.sources_channel).to eq(source_channel)
        end
      end
    end
  end

  describe '.fallback_sources_channel' do
    subject { described_class }

    context 'with ALTERNATIVE_SOURCES=true' do
      it 'returns "alternative"' do
        stub_env_var('ALTERNATIVE_SOURCES', 'true')

        expect(subject.fallback_sources_channel).to eq('alternative')
      end
    end

    context 'with ALTERNATIVE_SOURCES not set true' do
      it 'returns "remote"' do
        stub_env_var('ALTERNATIVE_SOURCES', 'false')

        expect(subject.fallback_sources_channel).to eq('remote')
      end
    end
  end

  describe '.security_channel?' do
    subject { described_class }

    it 'returns true when sources_channel is set for security' do
      mock_sources_channel('security')

      expect(subject.security_channel?).to be_truthy
    end

    it 'returns false when sources_channel is not set for security' do
      mock_sources_channel

      expect(subject.security_channel?).to be_falsey
    end
  end

  describe :remote do
    subject { Gitlab::Version.new(software) }

    context 'with a valid software name' do
      let(:software) { 'gitlab-rails-ee' }

      it 'returns a link from custom_sources yml' do
        mock_sources_channel

        expect(subject.remote).to eq('git@dev.gitlab.org:gitlab/gitlab-ee.git')
      end
    end

    context 'with an invalid software name' do
      let(:software) { 'not a valid software' }

      it 'outputs an empty string' do
        expect(subject.remote).to eq('')
      end
    end

    context 'with default fallback' do
      let(:software) { 'gitlab-rails-ee' }

      it 'returns "remote" link from custom_sources yml' do
        mock_sources_channel

        expect(subject.remote).to eq('git@dev.gitlab.org:gitlab/gitlab-ee.git')
      end
    end

    context 'with alternative fallback' do
      let(:software) { 'gitlab-rails-ee' }

      it 'returns "alternative" link from custom_sources yml' do
        mock_sources_channel('alternative')

        expect(subject.remote).to eq('https://gitlab.com/gitlab-org/gitlab.git')
      end
    end

    context 'with alternative env override' do
      let(:software) { 'gitlab-rails-ee' }

      it 'returns "alternative" link from the environment whenever present' do
        stub_env_var('GITLAB_ALTERNATIVE_REPO', 'https://gitlab.example.com/gitlab.git')

        expect(subject.remote).to eq('https://gitlab.example.com/gitlab.git')
      end

      it 'attaches credentials to alternative env links when present' do
        stub_env_var('GITLAB_ALTERNATIVE_REPO', 'https://gitlab.example.com/gitlab.git')
        stub_env_var('ALTERNATIVE_PRIVATE_TOKEN', 'APT')

        expect(subject.remote).to eq('https://gitlab-ci-token:APT@gitlab.example.com/gitlab.git')
      end
    end

    context 'with security source channel selected' do
      before do
        stub_env_var('CI_JOB_TOKEN', 'CJT')
        mock_sources_channel('security')
      end

      context 'when security source is defined for the software' do
        let(:software) { 'gitlab-rails-ee' }

        it 'returns "security" link attached with credential from custom_sources yml' do
          expect(subject.remote).to eq('https://gitlab-ci-token:CJT@gitlab.com/gitlab-org/security/gitlab.git')
        end

        context 'with SECURITY_PRIVATE_TOKEN' do
          it 'returns "security" link attached with credential from custom_sources yml' do
            stub_env_var('SECURITY_PRIVATE_TOKEN', 'APT')

            expect(subject.remote).to eq('https://gitlab-ci-token:APT@gitlab.com/gitlab-org/security/gitlab.git')
          end
        end

        context 'when "security" link is in not URI compliant' do
          before do
            allow(YAML).to receive(:load_file)
              .and_return(software => { "security" => "git@dev.gitlab.org:gitlab/gitlab-ee.git" })
          end

          it 'returns "security" link without attaching credential' do
            expect(subject.remote).to eq("git@dev.gitlab.org:gitlab/gitlab-ee.git")
          end
        end
      end

      context 'when security source is not defined for the software' do
        let(:software) { 'prometheus' }

        it 'returns "remote" link from custom_sources yml' do
          mock_fallback_channel

          expect(subject.remote).to eq('git@dev.gitlab.org:omnibus-mirror/prometheus.git')
        end

        it 'returns expected link from custom_sources yml when asked for a specific remote' do
          mock_fallback_channel

          expect(subject.remote('alternative')).to eq('https://gitlab.com/gitlab-org/build/omnibus-mirror/prometheus.git')
        end

        context 'with alternative fallback' do
          it 'returns "alternative" link from custom_sources yml' do
            mock_fallback_channel('alternative')

            expect(subject.remote).to eq('https://gitlab.com/gitlab-org/build/omnibus-mirror/prometheus.git')
          end
        end
      end
    end
  end

  describe :read_version_from_file do
    context 'when build facts exist' do
      before do
        allow(::File).to receive(:exist?).with(/build_facts.*_version/).and_return(true)
        allow(::File).to receive(:read).with(/build_facts.*_version/).and_return('version-from-build-facts')
        allow(::File).to receive(:read).with(/.*VERSION/).and_return('version-from-version-file')
      end

      it 'uses the version from build_facts' do
        components = %w[
          gitlab-rails
          gitlab-rails-ee
          gitlab-shell
          gitlab-pages
          gitaly
          gitlab-elasticsearch-indexer
          gitlab-kas
        ]

        components.each do |software|
          expect(Gitlab::Version.new(software).read_version_from_file).to eq('version-from-build-facts')
        end
      end
    end

    context 'when build facts do not exist' do
      before do
        allow(::File).to receive(:exist?).with(/build_facts.*_version/).and_return(false)
        allow(::File).to receive(:read).with(/.*VERSION/).and_return('version-from-version-file')
      end

      it 'uses the version from version files' do
        components = %w[
          gitlab-rails
          gitlab-rails-ee
          gitlab-shell
          gitlab-pages
          gitaly
          gitlab-elasticsearch-indexer
          gitlab-kas
        ]

        components.each do |software|
          expect(Gitlab::Version.new(software).read_version_from_file).to eq('version-from-version-file')
        end
      end
    end
  end

  describe :print do
    subject { Gitlab::Version.new(software, version) }

    context 'with a valid software name and version' do
      let(:software) { 'gitlab-rails' }
      let(:version) { '12.34.567' }

      it 'returns correct version with v appended' do
        expect(subject.print).to eq('v12.34.567')
      end
    end

    context 'with a valid software name and version' do
      let(:software) { 'gitlab-rails-ee' }
      let(:version) { '12.34.567-ee' }

      it 'returns correct version with v appended' do
        expect(subject.print).to eq('v12.34.567-ee')
      end
    end

    context 'with a valid software name and no version' do
      let(:software) { 'ruby' }
      let(:version) { nil }

      it 'outputs an empty string' do
        expect(subject.print).to eq(nil)
      end
    end

    context 'with a valid software name and a version' do
      let(:software) { 'ruby' }
      let(:version) { '2.3.1' }

      it 'adds a v prefix' do
        expect(subject.print).to eq("v2.3.1")
      end

      it 'does not add a v prefix if explicitly set' do
        expect(subject.print(false)).to eq("2.3.1")
      end
    end

    context 'with a valid software name and a branch name' do
      let(:software) { 'gitlab-rails' }
      let(:version) { '9-0-stable' }

      it 'does not add a v prefix' do
        expect(subject.print).to eq("9-0-stable")
      end
    end

    context 'with a valid software name and a branch name' do
      let(:software) { 'gitlab-rails' }
      let(:version) { 'master' }

      it 'does not add a v prefix' do
        expect(subject.print).to eq("master")
      end
    end

    context 'with a valid software name and an rc tag ' do
      let(:software) { 'gitlab-rails' }
      let(:version) { '9.1.0-rc1' }

      it 'add a v prefix' do
        expect(subject.print).to eq("v9.1.0-rc1")
      end
    end

    context 'with a valid software name and an rc tag ' do
      let(:software) { 'gitlab-rails' }
      let(:version) { '9.1.0-rc2-ee' }

      it 'add a v prefix' do
        expect(subject.print).to eq("v9.1.0-rc2-ee")
      end
    end

    context 'with a valid software name and a branch name' do
      let(:software) { 'gitlab-rails' }
      let(:version) { '9.1.0-fix' }

      it 'does not add a v prefix' do
        expect(subject.print).to eq("9.1.0-fix")
      end
    end

    context 'with a valid software name and a branch name' do
      let(:software) { 'gitlab-rails' }
      let(:version) { 'fix-9.1.0' }

      it 'does not add a v prefix' do
        expect(subject.print).to eq("fix-9.1.0")
      end
    end

    context 'with a valid software name and a commit sha' do
      let(:software) { 'gitlab-rails' }
      let(:version) { '1076385cb57a03fa254be5604f6c6ceb6e39987f' }

      it 'does not add a v prefix' do
        expect(subject.print).to eq("1076385cb57a03fa254be5604f6c6ceb6e39987f")
      end
    end
  end

  describe :version do
    subject { Gitlab::Version.new(software) }

    context 'env variable for setting version' do
      let(:software) { 'gitlab-rails' }

      it 'identifies correct version from env variable' do
        stub_env_var('GITLAB_VERSION', '5.6.7')
        allow(File).to receive(:read).and_return("1.2.3")
        expect(subject.print).to eq("v5.6.7")
      end

      it 'falls back to VERSION file if env variable not found' do
        allow(File).to receive(:read).and_return("1.2.3")
        expect(subject.print).to eq("v1.2.3")
      end
    end
  end

  describe '.load_versions_file' do
    it 'reads every scalar as a String, without coercing versions to floats' do
      require 'tempfile'

      file = Tempfile.new(['versions', '.yml'])
      file.write(<<~YAML)
        go:
          version: 1.20
          patch: 3.4.9
      YAML
      file.close

      data = described_class.load_versions_file(file.path)

      expect(data.dig('go', 'version')).to eq('1.20')
      expect(data.dig('go', 'version')).to be_a(String)
      expect(data.dig('go', 'patch')).to eq('3.4.9')
    ensure
      file&.unlink
    end
  end

  describe 'software_versions.yml accessors' do
    let(:software_versions) do
      {
        'ruby' => {
          'current' => '3.3.11',
          'next' => '3.4.9',
          'checksums' => {
            '3.3.11' => 'aaa',
            '3.4.9' => 'bbb'
          }
        },
        'libffi' => {
          'version' => '3.2.1',
          'sha256' => 'ccc',
          'ubt' => { 'revision' => '3ubt', 'sha256' => 'ddd' }
        },
        'libyaml' => {
          'version' => '0.2.5',
          'sha256' => 'eee',
          'env_var' => 'LIBYAML_VERSION'
        }
      }
    end

    before do
      allow(described_class).to receive(:software_versions).and_return(software_versions)
    end

    describe '#[]' do
      it 'reads raw values for components with bespoke policy' do
        subject = described_class.new('ruby')

        expect(subject['current']).to eq('3.3.11')
        expect(subject['next']).to eq('3.4.9')
      end

      it 'returns nil for an absent key' do
        expect(described_class.new('ruby')['nope']).to be_nil
      end
    end

    describe '#fetch' do
      it 'reads a required value' do
        expect(described_class.new('ruby').fetch('next')).to eq('3.4.9')
      end

      it 'raises a descriptive error when a required key is missing' do
        expect { described_class.new('libffi').fetch('next') }
          .to raise_error(KeyError, /'libffi' is missing required key 'next'/)
      end
    end

    describe '#upstream_version' do
      it 'returns the pinned version' do
        expect(described_class.new('libffi').upstream_version).to eq('3.2.1')
      end

      it 'raises a helpful error for a checksums-map component' do
        expect { described_class.new('ruby').upstream_version }
          .to raise_error(KeyError, /'ruby' uses a checksums map.*read its 'current'\/'next' pins via #\[\]/)
      end

      it 'lets an env var override the pin' do
        stub_env_var('LIBYAML_VERSION', '0.2.6')

        expect(described_class.new('libyaml').upstream_version).to eq('0.2.6')
      end

      it 'ignores the env var when unset' do
        stub_env_var('LIBYAML_VERSION', nil)

        expect(described_class.new('libyaml').upstream_version).to eq('0.2.5')
      end
    end

    describe '#source_sha256' do
      it 'returns the sha256 for a single-version component' do
        expect(described_class.new('libffi').source_sha256).to eq('ccc')
      end

      it 'looks up the sha256 in a checksums map' do
        subject = described_class.new('ruby')

        expect(subject.source_sha256('3.3.11')).to eq('aaa')
        expect(subject.source_sha256('3.4.9')).to eq('bbb')
      end

      it 'raises a helpful error for an unknown version' do
        expect { described_class.new('ruby').source_sha256('9.9.9') }
          .to raise_error(KeyError, /No sha256 for ruby 9.9.9/)
      end
    end

    describe '#ubt_version and #ubt_sha256' do
      subject { described_class.new('libffi') }

      it 'returns the pre-built bundle version and checksum' do
        expect(subject.ubt_version).to eq('3.2.1-3ubt')
        expect(subject.ubt_sha256).to eq('ddd')
      end

      it 'raises when the component has no ubt entry' do
        expect { described_class.new('ruby').ubt_version }
          .to raise_error(KeyError, /No 'ubt' entry for 'ruby'/)
      end
    end

    describe '#software_data' do
      it 'raises a helpful error for an unknown component' do
        expect { described_class.new('nope').software_data }
          .to raise_error(KeyError, /No entry for 'nope'/)
      end
    end
  end

  def mock_sources_channel(channel = 'remote')
    allow(::Gitlab::Version).to receive(:sources_channel).and_return(channel)
  end

  def mock_fallback_channel(channel = 'remote')
    allow(::Gitlab::Version).to receive(:fallback_sources_channel).and_return(channel)
  end
end
