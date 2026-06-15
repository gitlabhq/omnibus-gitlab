require 'spec_helper'
require 'gitlab/build/info/components'

RSpec.describe Build::Info::Components::GitLabRails do
  before do
    stub_default_package_version
    stub_env_var('GITLAB_ALTERNATIVE_REPO', nil)
    stub_env_var('ALTERNATIVE_PRIVATE_TOKEN', nil)
  end

  describe '.version' do
    describe 'GITLAB_VERSION variable specified' do
      it 'returns passed value' do
        allow(ENV).to receive(:[]).with("GITLAB_VERSION").and_return("9.0.0")
        expect(described_class.version).to eq('9.0.0')
      end
    end

    describe 'GITLAB_VERSION variable not specified' do
      it 'returns content of VERSION' do
        allow(File).to receive(:read).with("VERSION").and_return("8.5.6")
        expect(described_class.version).to eq('8.5.6')
      end
    end
  end

  describe '.ref' do
    context 'with prepend_version true' do
      context 'when on tags and stable branches' do
        # On stable branches and tags, generate-facts will not populate version facts
        # So, the content of the VERSION file will be used as-is.
        it 'returns tag with v prefix' do
          allow(File).to receive(:exist?).with(/gitlab-rails.*version/).and_return(false)
          allow(File).to receive(:read).with(/VERSION/).and_return('15.7.0')
          expect(described_class.ref).to eq('v15.7.0')
        end
      end

      context 'when on feature branches' do
        it 'returns commit SHA without any prefix' do
          allow(File).to receive(:exist?).with(/gitlab-rails.*version/).and_return(true)
          allow(File).to receive(:read).with(/gitlab-rails.*version/).and_return('arandomcommit')
          expect(described_class.ref).to eq('arandomcommit')
        end
      end
    end

    context 'with prepend_version false' do
      context 'when on tags and stable branches' do
        # On stable branches and tags, generate-facts will not populate version facts
        # So, whatever is on VERSION file, will be used.
        it 'returns tag without v prefix' do
          allow(File).to receive(:exist?).with(/gitlab-rails.*version/).and_return(false)
          allow(File).to receive(:read).with(/VERSION/).and_return('15.7.0')
          expect(described_class.ref(prepend_version: false)).to eq('15.7.0')
        end
      end

      context 'when on feature branches' do
        it 'returns commit SHA without any prefix' do
          allow(File).to receive(:exist?).with(/gitlab-rails.*version/).and_return(true)
          allow(File).to receive(:read).with(/gitlab-rails.*version/).and_return('arandomcommit')
          expect(described_class.ref(prepend_version: false)).to eq('arandomcommit')
        end
      end
    end
  end

  describe '.repo' do
    context 'when alternative sources channel selected' do
      before do
        allow(::Gitlab::Version).to receive(:sources_channel).and_return('alternative')
      end

      it 'returns public mirror for GitLab CE' do
        allow(Build::Info::Package).to receive(:name).and_return("gitlab-ce")
        expect(described_class.repo).to eq("https://gitlab.com/gitlab-org/gitlab-foss.git")
      end

      it 'returns public mirror for GitLab EE' do
        allow(Build::Info::Package).to receive(:name).and_return("gitlab-ee")
        expect(described_class.repo).to eq("https://gitlab.com/gitlab-org/gitlab.git")
      end
    end

    context 'when default sources channel' do
      before do
        allow(::Gitlab::Version).to receive(:sources_channel).and_return('remote')
      end

      it 'returns dev repo for GitLab CE' do
        allow(Build::Info::Package).to receive(:name).and_return("gitlab-ce")
        expect(described_class.repo).to eq("git@dev.gitlab.org:gitlab/gitlabhq.git")
      end

      it 'returns dev repo for GitLab EE' do
        allow(Build::Info::Package).to receive(:name).and_return("gitlab-ee")
        expect(described_class.repo).to eq("git@dev.gitlab.org:gitlab/gitlab-ee.git")
      end
    end

    context 'when security sources channel selected' do
      before do
        allow(::Gitlab::Version).to receive(:sources_channel).and_return('security')
        stub_env_var('CI_JOB_TOKEN', 'CJT')
      end

      it 'returns security mirror for GitLab CE with attached credential' do
        allow(Build::Info::Package).to receive(:name).and_return("gitlab-ce")
        expect(described_class.repo).to eq("https://gitlab-ci-token:CJT@gitlab.com/gitlab-org/security/gitlab-foss.git")
      end
      it 'returns security mirror for GitLab EE with attached credential' do
        allow(Build::Info::Package).to receive(:name).and_return("gitlab-ee")
        expect(described_class.repo).to eq("https://gitlab-ci-token:CJT@gitlab.com/gitlab-org/security/gitlab.git")
      end
    end
  end

  describe '.project_path' do
    context 'when building CE' do
      before do
        stub_is_ee(false)
      end

      context 'when on the build mirror' do
        before do
          stub_env_var('CI_SERVER_HOST', 'dev.gitlab.org')
          stub_env_var('SECURITY_SOURCES', '')
        end

        it 'returns correct path for GitLab rails project' do
          expect(described_class.project_path).to eq("gitlab/gitlabhq")
        end
      end

      context 'when on running on the canonical project or QA mirror' do
        before do
          stub_env_var('CI_SERVER_HOST', 'gitlab.com')
          stub_env_var('SECURITY_SOURCES', '')
        end

        it 'returns correct path for GitLab rails project' do
          expect(described_class.project_path).to eq("gitlab-org/gitlab-foss")
        end
      end

      context 'when running on the security mirror' do
        before do
          stub_env_var('CI_SERVER_HOST', 'gitlab.com')
          stub_env_var('SECURITY_SOURCES', 'true')
        end

        it 'returns correct path for GitLab rails project' do
          expect(described_class.project_path).to eq("gitlab-org/security/gitlab-foss")
        end
      end
    end

    context 'when building EE' do
      before do
        stub_is_ee(true)
      end

      context 'when running on the build mirror' do
        before do
          stub_env_var('CI_SERVER_HOST', 'dev.gitlab.org')
          stub_env_var('SECURITY_SOURCES', '')
        end

        it 'returns correct path for GitLab rails project' do
          expect(described_class.project_path).to eq("gitlab/gitlab-ee")
        end
      end

      context 'when running on the canonical project or QA mirror' do
        before do
          stub_env_var('CI_SERVER_HOST', 'gitlab.com')
          stub_env_var('SECURITY_SOURCES', '')
        end

        it 'returns correct path for GitLab rails project' do
          expect(described_class.project_path).to eq("gitlab-org/gitlab")
        end
      end

      context 'when running on the security mirror' do
        before do
          stub_env_var('CI_SERVER_HOST', 'gitlab.com')
          stub_env_var('SECURITY_SOURCES', 'true')
        end

        it 'returns correct path for GitLab rails project' do
          expect(described_class.project_path).to eq("gitlab-org/security/gitlab")
        end
      end
    end
  end
end
