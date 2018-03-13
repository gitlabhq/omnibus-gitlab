require 'spec_helper'
require 'gitlab/build/info'

describe Build::Info do
  describe '.package' do
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

  describe '.release_version' do
    before do
      allow(Build::Check).to receive(:on_tag?).and_return(true)
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

        expect(described_class.release_version).to eq('12.121.12-ce.1')
      end
    end
  end

  describe '.docker_tag' do
    before do
      allow(Build::Check).to receive(:on_tag?).and_return(true)
      allow_any_instance_of(Omnibus::BuildVersion).to receive(:semver).and_return('12.121.12')
      allow_any_instance_of(Gitlab::BuildIteration).to receive(:build_iteration).and_return('ce.1')
    end

    it 'returns package version when regular build' do
      expect(described_class.docker_tag).to eq('12.121.12-ce.1')
    end
  end

  # Specs for latest_tag and for latest_stable_tag are really useful since we
  # are stubbing out shell out to git.
  # However, they are showing what we expect to see.
  describe '.latest_tag' do
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

  describe '.latest_stable_tag' do
    describe 'for CE' do
      before do
        stub_is_ee(nil)
        allow(described_class).to receive(:`).with("git -c versionsort.prereleaseSuffix=rc tag -l '*[+.]ce.*' --sort=-v:refname | awk '!/rc/' | head -1").and_return('12.121.12+ce.0')
      end

      it 'returns the version of correct edition' do
        expect(described_class.latest_stable_tag).to eq('12.121.12+ce.0')
      end
    end

    describe 'for EE' do
      before do
        stub_is_ee(true)
        allow(described_class).to receive(:`).with("git -c versionsort.prereleaseSuffix=rc tag -l '*[+.]ee.*' --sort=-v:refname | awk '!/rc/' | head -1").and_return('12.121.12+ee.0')
      end

      it 'returns the version of correct edition' do
        expect(described_class.latest_stable_tag).to eq('12.121.12+ee.0')
      end
    end
  end

  describe '.gitlab_version' do
    describe 'GITLAB_VERSION variable specified' do
      it 'returns passed value' do
        allow(ENV).to receive(:[]).with("GITLAB_VERSION").and_return("9.0.0")
        expect(described_class.gitlab_version).to eq('9.0.0')
      end
    end

    describe 'GITLAB_VERSION variable not specified' do
      it 'returns content of VERSION' do
        allow(File).to receive(:read).with("VERSION").and_return("8.5.6")
        expect(described_class.gitlab_version).to eq('8.5.6')
      end
    end
  end

  describe '.previous_version' do
    it 'detects previous version correctly' do
      allow(Build::Info).to receive(:`).with(/git -c versionsort/).and_return("10.4.0+ee.0\n10.3.5+ee.0")

      expect(described_class.previous_version).to eq("10.3.5-ee.0")
    end
  end

  describe '.gitlab_rails repo' do
    describe 'ALTERNATIVE_SOURCES variable specified' do
      before do
        allow(ENV).to receive(:[]).with("ALTERNATIVE_SOURCES").and_return("true")
      end

      it 'returns public mirror for GitLab CE' do
        allow(Build::Info).to receive(:package).and_return("gitlab-ce")
        expect(described_class.gitlab_rails_repo).to eq("https://gitlab.com/gitlab-org/gitlab-ce.git")
      end
      it 'returns public mirror for GitLab EE' do
        allow(Build::Info).to receive(:package).and_return("gitlab-ee")
        expect(described_class.gitlab_rails_repo).to eq("https://gitlab.com/gitlab-org/gitlab-ee.git")
      end
    end

    describe 'ALTERNATIVE_SOURCES variable not specified' do
      it 'returns dev repo for GitLab CE' do
        allow(Build::Info).to receive(:package).and_return("gitlab-ce")
        expect(described_class.gitlab_rails_repo).to eq("git@dev.gitlab.org:gitlab/gitlabhq.git")
      end
      it 'returns dev repo for GitLab EE' do
        allow(Build::Info).to receive(:package).and_return("gitlab-ee")
        expect(described_class.gitlab_rails_repo).to eq("git@dev.gitlab.org:gitlab/gitlab-ee.git")
      end
    end
  end
end
