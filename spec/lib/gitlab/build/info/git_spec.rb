require 'spec_helper'
require 'gitlab/build/info/git'

RSpec.describe Build::Info::Git do
  before do
    stub_default_package_version

    ce_tags = "16.1.1+ce.0\n16.0.0+rc42.ce.0\n15.11.1+ce.0\n15.11.0+ce.0\n15.10.0+ce.0\n15.10.0+rc42.ce.0"
    ee_tags = "16.1.1+ee.0\n16.0.0+rc42.ee.0\n15.11.1+ee.0\n15.11.0+ee.0\n15.10.0+ee.0\n15.10.0+rc42.ee.0"
    allow(Gitlab::Util).to receive(:shellout_stdout).with(/git -c versionsort.*ce/).and_return(ce_tags)
    allow(Gitlab::Util).to receive(:shellout_stdout).with(/git -c versionsort.*ee/).and_return(ee_tags)
  end

  describe '.branch_name' do
    context 'in tags' do
      context 'in CI' do
        before do
          stub_tag('16.1.1+ee.0')
        end

        it 'returns nil' do
          expect(described_class.branch_name).to be_nil
        end
      end

      context 'not in CI' do
        before do
          stub_env_var('CI_COMMIT_BRANCH', '')
          stub_env_var('CI_MERGE_REQUEST_SOURCE_BRANCH_NAME', '')
          allow(Gitlab::Util).to receive(:shellout_stdout).with('git rev-parse --abbrev-ref HEAD').and_return('HEAD')
        end

        it 'returns nil' do
          expect(described_class.branch_name).to be_nil
        end
      end
    end

    context 'in branches' do
      context 'in CI' do
        context 'in MR pipelines' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '')
            stub_env_var('CI_MERGE_REQUEST_SOURCE_BRANCH_NAME', 'my-feature-branch')
          end

          it 'returns branch name from CI variable' do
            expect(described_class.branch_name).to eq('my-feature-branch')
          end
        end

        context 'in regular branch pipelines' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', 'my-feature-branch')
            stub_env_var('CI_MERGE_REQUEST_SOURCE_BRANCH_NAME', '')
          end

          it 'returns branch name from CI variable' do
            expect(described_class.branch_name).to eq('my-feature-branch')
          end
        end
      end

      context 'not in CI' do
        before do
          stub_env_var('CI_COMMIT_BRANCH', '')
          stub_env_var('CI_COMMIT_TAG', '')
          stub_env_var('CI_MERGE_REQUEST_SOURCE_BRANCH_NAME', '')
          allow(Gitlab::Util).to receive(:shellout_stdout).with('git rev-parse --abbrev-ref HEAD').and_return('my-feature-branch')
        end

        it 'computes branch name from git' do
          expect(described_class.branch_name).to eq('my-feature-branch')
        end
      end
    end
  end

  describe '.tag_name' do
    context 'in tags' do
      context 'in CI' do
        before do
          stub_env_var('CI_COMMIT_BRANCH', '')
          stub_env_var('CI_COMMIT_TAG', '16.1.1+ee.0')
        end

        it 'returns tag name from CI variables' do
          expect(described_class.tag_name).to eq('16.1.1+ee.0')
        end

        context 'not in CI' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '')
            stub_env_var('CI_COMMIT_TAG', '')
            allow(Gitlab::Util).to receive(:shellout_stdout).with('git describe --tags --exact-match').and_return('16.1.1+ee.0')
          end

          it 'computes tag name from git' do
            expect(described_class.tag_name).to eq('16.1.1+ee.0')
          end
        end
      end
    end

    context 'in branches' do
      before do
        stub_branch('my-feature-branch')
      end

      it 'returns nil' do
        expect(described_class.tag_name).to be_nil
      end
    end

    context 'if some other error is raised' do
      before do
        stub_env_var('CI_COMMIT_BRANCH', '')
        stub_env_var('CI_COMMIT_TAG', '')
        allow(Gitlab::Util).to receive(:shellout_stdout).with('git describe --tags --exact-match').and_raise(Gitlab::Util::ShellOutExecutionError.new("", 100, "", "Some Other Error"))
      end

      it 'raises the error' do
        expect { described_class.tag_name }.to raise_error(/Some Other Error/)
      end
    end
  end

  describe '.commit_sha' do
    context 'from CI' do
      before do
        stub_env_var('CI_COMMIT_SHA', '3cd8e712ccd3c3f356108ec1a5cbeecbf3d3be88')
        allow(Gitlab::Util).to receive(:shellout_stdout).with('git rev-parse HEAD').and_return('some-other-sha')
      end

      it 'returns truncated commit sha from CI variable' do
        expect(described_class.commit_sha).to eq('3cd8e712')
      end
    end

    context 'not from CI' do
      before do
        stub_env_var('CI_COMMIT_SHA', '')
        allow(Gitlab::Util).to receive(:shellout_stdout).with('git rev-parse HEAD').and_return('3cd8e712ccd3c3f356108ec1a5cbeecbf3d3be88')
      end

      it 'returns truncated commit sha from CI variable' do
        expect(described_class.commit_sha).to eq('3cd8e712')
      end
    end
  end

  describe '.latest_tag' do
    context 'on CE edition' do
      before do
        stub_is_ee(false)
      end

      context 'on stable branch' do
        context 'when tags already exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '15-10-stable')
          end

          it 'returns the latest tag in the stable version series' do
            expect(described_class.latest_tag).to eq('15.10.0+ce.0')
          end
        end

        context 'when tags does not exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-5-stable')
          end

          it 'returns the latest available tag' do
            expect(described_class.latest_tag).to eq('16.1.1+ce.0')
          end
        end

        context 'when latest tag in the series is an RC tag' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-0-stable')
          end

          it 'returns the RC tag' do
            expect(described_class.latest_tag).to eq('16.0.0+rc42.ce.0')
          end
        end
      end

      context 'on feature branch' do
        before do
          stub_env_var('CI_COMMIT_BRANCH', 'my-feature-branch')
        end

        it 'returns the latest available tag' do
          expect(described_class.latest_tag).to eq('16.1.1+ce.0')
        end
      end
    end

    context 'on EE edition' do
      before do
        stub_is_ee(true)
      end

      context 'on stable branch' do
        context 'when tags already exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '15-10-stable')
          end

          it 'returns the latest tag in the stable version series' do
            expect(described_class.latest_tag).to eq('15.10.0+ee.0')
          end
        end

        context 'when tags does not exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-5-stable')
          end

          it 'returns the latest available tag' do
            expect(described_class.latest_tag).to eq('16.1.1+ee.0')
          end
        end

        context 'when latest tag in the series is an RC tag' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-0-stable')
          end

          it 'returns the RC tag' do
            expect(described_class.latest_tag).to eq('16.0.0+rc42.ee.0')
          end
        end
      end

      context 'on feature branch' do
        before do
          stub_env_var('CI_COMMIT_BRANCH', 'my-feature-branch')
        end

        it 'returns the latest available tag' do
          expect(described_class.latest_tag).to eq('16.1.1+ee.0')
        end
      end
    end
  end

  describe '.latest_stable_tag' do
    context 'on CE edition' do
      before do
        stub_is_ee(false)
      end

      context 'on stable branch' do
        context 'when tags already exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '15-10-stable')
          end

          it 'returns the latest tag in the stable version series' do
            expect(described_class.latest_stable_tag).to eq('15.10.0+ce.0')
          end
        end

        context 'when tags does not exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-5-stable')
          end

          it 'returns the latest available tag' do
            expect(described_class.latest_stable_tag).to eq('16.1.1+ce.0')
          end
        end

        context 'when latest tag in the series is an RC tag' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-0-stable')
          end

          it 'skips the RC tag and returns the latest available tag' do
            expect(described_class.latest_stable_tag).to eq('16.1.1+ce.0')
          end
        end
      end

      context 'on feature branch' do
        before do
          stub_env_var('CI_COMMIT_BRANCH', 'my-feature-branch')
        end

        it 'returns the latest available tag' do
          expect(described_class.latest_stable_tag).to eq('16.1.1+ce.0')
        end
      end
    end

    context 'on EE edition' do
      before do
        stub_is_ee(true)
      end

      context 'on stable branch' do
        context 'when tags already exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '15-10-stable')
          end

          it 'returns the latest tag in the stable version series' do
            expect(described_class.latest_stable_tag).to eq('15.10.0+ee.0')
          end
        end

        context 'when tags does not exist in the stable version series' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-5-stable')
          end

          it 'returns the latest available tag' do
            expect(described_class.latest_stable_tag).to eq('16.1.1+ee.0')
          end
        end

        context 'when latest tag in the series is an RC tag' do
          before do
            stub_env_var('CI_COMMIT_BRANCH', '16-0-stable')
          end

          it 'skips the RC tag and returns the latest available tag' do
            expect(described_class.latest_stable_tag).to eq('16.1.1+ee.0')
          end
        end
      end

      context 'on feature branch' do
        before do
          stub_env_var('CI_COMMIT_BRANCH', 'my-feature-branch')
        end

        it 'returns the latest available tag' do
          expect(described_class.latest_stable_tag).to eq('16.1.1+ee.0')
        end
      end
    end

    context 'when a level is specified' do
      before do
        stub_is_ee(true)
        stub_env_var('CI_COMMIT_BRANCH', 'my-feature-branch')
      end

      it 'returns recent tag at specified position' do
        expect(described_class.latest_stable_tag(level: 2)).to eq('15.11.1+ee.0')
      end
    end
  end
end
