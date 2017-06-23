require_relative '../../lib/gitlab/build.rb'

describe Build do
  describe 'cmd' do
    describe 'by default' do
      it 'runs build command with log level info' do
        expect(described_class.cmd('gitlab')).to eq 'bundle exec omnibus build gitlab --log-level info'
      end
    end

    describe 'with different log level' do
      it 'runs build command with custom log level' do
        stub_env_var('BUILD_LOG_LEVEL', 'debug')
        expect(described_class.cmd('gitlab')).to eq 'bundle exec omnibus build gitlab --log-level debug'
      end
    end
  end

  describe 'is_ee?' do
    describe 'with environment variables' do
      it 'when ee=true' do
        stub_is_ee_env(true)
        expect(described_class.is_ee?).to be_truthy
      end

      it 'when ee=false' do
        stub_is_ee(false)
        expect(described_class.is_ee?).to be_falsy
      end

      it 'when env variable is not set' do
        stub_is_ee_version(false)
        expect(described_class.is_ee?).to be_falsy
      end
    end

    describe 'without environment variables' do
      it 'checks the VERSION file' do
        stub_is_ee_version(true)
        expect(described_class.is_ee?).to be_truthy
      end
    end
  end

  describe 'package' do
    describe 'shows EE' do
      it 'when ee=true' do
        stub_is_ee_env(true)
        expect(described_class.package).to eq('gitlab-ee')
      end

      it 'when env var is not present, checks VERSION file' do
        stub_is_ee_version(true)
        expect(described_class.package).to eq('gitlab-ee')
      end
    end

    describe 'shows CE' do
      it 'by default' do
        stub_is_ee(false)
        expect(described_class.package).to eq('gitlab-ce')
      end
    end
  end

  describe 'release_version' do
    before do
      allow_any_instance_of(Omnibus::BuildVersion).to receive(:semver).and_return('12.121.12')
      allow_any_instance_of(Gitlab::BuildIteration).to receive(:build_iteration).and_return('ce.1')
    end

    it 'returns build version and iteration' do
      expect(described_class.release_version).to eq('12.121.12-ce.1')
    end

    describe 'with env variables' do
      it 'returns build version and iteration with env variable' do
        stub_env_var('USE_S3_CACHE', 'false')
        stub_env_var('CACHE_AWS_ACCESS_KEY_ID', 'NOT-KEY')
        stub_env_var('CACHE_AWS_SECRET_ACCESS_KEY', 'NOT-SECRET-KEY')
        stub_env_var('CACHE_AWS_BUCKET', 'bucket')
        stub_env_var('CACHE_AWS_S3_REGION', 'moon-west1')
        stub_env_var('CACHE_S3_ACCELERATE', 'sure')

        stub_env_var('NIGHTLY', 'true')
        stub_env_var('CI_PIPELINE_ID', '5555')

        expect(described_class.release_version).to eq('12.121.12.5555-ce.1')
      end
    end
  end

  describe 'docker_tag' do
    before do
      allow_any_instance_of(Omnibus::BuildVersion).to receive(:semver).and_return('12.121.12')
      allow_any_instance_of(Gitlab::BuildIteration).to receive(:build_iteration).and_return('ce.1')
    end

    it 'returns package version when regular build' do
      expect(described_class.docker_tag).to eq('12.121.12-ce.1')
    end
  end

  describe 'add tag methods' do
    describe 'add_nightly_tag?' do
      it 'returns true if it is a nightly build' do
        stub_env_var('NIGHTLY', 'true')
        expect(described_class.add_nightly_tag?).to be_truthy
      end

      it 'returns false if it is not a nightly build' do
        expect(described_class.add_nightly_tag?).to be_falsey
      end
    end

    describe 'add_rc_tag?' do
      it 'returns true if it is an rc release' do
        # This will be the case if latest_tag is eg. 9.3.0+rc6.ce.0
        # or 9.3.0+ce.0
        allow(described_class).to receive(:latest_tag).and_return('9.3.0+rc6.ce.0') # This line only is only an example, stubbing is not needed.
        allow(described_class).to receive(:match_tag).and_return(true)
        expect(described_class.add_rc_tag?).to be_truthy
      end

      it 'returns true if it is not an rc release' do
        allow(described_class).to receive(:latest_tag).and_return('9.3.0+ce.0') # This line only is only an example, stubbing is not needed.
        allow(described_class).to receive(:match_tag).and_return(false)
        expect(described_class.add_rc_tag?).to be_falsey
      end
    end

    describe 'add_latest_tag?' do
      it 'returns true if it is a stable release' do
        # This will be the case if latest_tag is eg. 9.3.0+ce.0
        # It will not be the case if the tag is 9.3.0+rc6.ce.0
        allow(described_class).to receive(:latest_stable_tag).and_return('9.3.0+ce.0') # This line only is only an example, stubbing is not needed.
        allow(described_class).to receive(:match_tag).and_return(true)
        expect(described_class.add_latest_tag?).to be_truthy
      end

      it 'returns true if it is not a stable release' do
        allow(described_class).to receive(:latest_stable_tag).and_return('9.3.0+rc6.ce.0') # This line only is only an example, stubbing is not needed.
        allow(described_class).to receive(:match_tag).and_return(false)
        expect(described_class.add_latest_tag?).to be_falsey
      end
    end
  end

  describe 'write_release_file' do
    describe 'with triggered build' do
      let(:release_file) do
        [
          "PACKAGECLOUD_REPO=download-package",
          "RELEASE_VERSION=12.121.12-ce.1",
          "DOWNLOAD_URL=https://gitlab.example.com/project/repository/builds/1/artifacts/raw/pkg/ubuntu-16.04/gitlab.deb",
          "TRIGGER_PRIVATE_TOKEN=NOT-PRIVATE-TOKEN\n"
        ]
      end

      before do
        stub_env_var('PACKAGECLOUD_REPO', 'download-package')
        stub_env_var('TRIGGER_PRIVATE_TOKEN', 'NOT-PRIVATE-TOKEN')
        stub_env_var('CI_PROJECT_URL', 'https://gitlab.example.com/project/repository')
        stub_env_var('CI_PROJECT_ID', '1')
        stub_env_var('CI_PIPELINE_ID', '2')
        allow(described_class).to receive(:release_version).and_return('12.121.12-ce.1')
        allow(described_class).to receive(:fetch_artifact_url).with('1', '2').and_return('1')
      end

      describe 'for CE' do
        before do
          allow(described_class).to receive(:package).and_return('gitlab-ce')
        end

        it 'returns build version and iteration with env variable' do
          release_file_content = release_file.insert(1, 'RELEASE_PACKAGE=gitlab-ce').join("\n")
          expect(described_class.write_release_file).to eq(release_file_content)
        end
      end

      describe 'for EE' do
        before do
          allow(described_class).to receive(:package).and_return('gitlab-ee')
        end

        it 'returns build version and iteration with env variable' do
          release_file_content = release_file.insert(1, 'RELEASE_PACKAGE=gitlab-ee').join("\n")
          expect(described_class.write_release_file).to eq(release_file_content)
        end
      end

      describe 'with regular build' do
        let(:s3_download_link) { 'https://release-bucket.s3.amazonaws.com/ubuntu-xenial/gitlab-ee_12.121.12-ce.1_amd64.deb' }

        let(:release_file) do
          [
            "RELEASE_VERSION=12.121.12-ce.1",
            "DOWNLOAD_URL=#{s3_download_link}\n",
          ]
        end

        before do
          stub_env_var('PACKAGECLOUD_REPO', '')
          stub_env_var('TRIGGER_PRIVATE_TOKEN', '')
          stub_env_var('CI_PROJECT_ID', '')
          stub_env_var('CI_PIPELINE_ID', '')
          stub_env_var('RELEASE_BUCKET', 'release-bucket')
          allow(described_class).to receive(:package).and_return('gitlab-ee')
          allow(described_class).to receive(:release_version).and_return('12.121.12-ce.1')
        end

        it 'returns build version and iteration with env variable' do
          release_file_content = release_file.insert(0, 'RELEASE_PACKAGE=gitlab-ee').join("\n")
          expect(described_class.write_release_file).to eq(release_file_content)
        end
      end
    end
  end

  # Specs for latest_tag and for latest_stable_tag are really useful since we
  # are stubbing out shell out to git.
  # However, they are showing what we expect to see.
  describe 'latest_tag' do
    describe 'for CE' do
      before do
        stub_is_ee(false)
        allow(described_class).to receive(:`).with("git -c versionsort.prereleaseSuffix=rc tag -l '*[+.]ce.*' --sort=-v:refname | head -1").and_return('12.121.12+rc7.ce.0')
      end

      it 'returns the version of correct edition' do
        expect(described_class.latest_tag).to eq('12.121.12+rc7.ce.0')
      end
    end

    describe 'for EE' do
      before do
        stub_is_ee(true)
        allow(described_class).to receive(:`).with("git -c versionsort.prereleaseSuffix=rc tag -l '*[+.]ee.*' --sort=-v:refname | head -1").and_return('12.121.12+rc7.ee.0')
      end

      it 'returns the version of correct edition' do
        expect(described_class.latest_tag).to eq('12.121.12+rc7.ee.0')
      end
    end
  end

  describe 'with different log level' do
    it 'runs build command with custom log level' do
      allow(ENV).to receive(:[]).with('BUILD_LOG_LEVEL').and_return('debug')
      expect(described_class.cmd('gitlab')).to eq 'bundle exec omnibus build gitlab --log-level debug'
    end
  end
end
