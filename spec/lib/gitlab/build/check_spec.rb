require 'spec_helper'
require 'gitlab/build/check'

RSpec.describe Build::Check do
  before do
    stub_default_package_version
  end

  describe 'is_ee?' do
    describe 'with environment variables' do
      before do
        stub_is_ee_version(false)
      end

      describe 'ee variable' do
        it 'when ee=true' do
          stub_is_ee_env(true)
          expect(described_class.is_ee?).to be_truthy
        end

        it 'when ee=false' do
          stub_is_ee(false)
          expect(described_class.is_ee?).to be_falsy
        end

        it 'when env variable is not set' do
          stub_env_var('ee', nil)
          stub_is_ee_version(false)
          stub_is_auto_deploy(false)
          expect(described_class.is_ee?).to be_falsy
        end
      end

      describe 'GITLAB_VERSION variable' do
        it 'when GITLAB_VERSION ends with -ee' do
          stub_env_var('ee', nil)
          stub_env_var('GITLAB_VERSION', 'foo-ee')
          expect(described_class.is_ee?).to be_truthy
        end

        it 'when GITLAB_VERSION does not end with -ee' do
          stub_env_var('ee', nil)
          stub_env_var('GITLAB_VERSION', 'foo')
          stub_is_auto_deploy(false)
          expect(described_class.is_ee?).to be_falsy
        end

        it 'ee variable wins over GITLAB_VERSION variable' do
          stub_is_ee_env(true)
          stub_env_var('GITLAB_VERSION', 'foo')
          expect(described_class.is_ee?).to be_truthy
        end
      end
    end

    describe 'without environment variables' do
      it 'checks the VERSION file' do
        stub_is_ee_version(false)
        stub_env_var('GITLAB_VERSION', 'foo-ee')
        expect(described_class.is_ee?).to be_truthy
      end

      it 'GITLAB_VERSION variable wins over the file' do
        stub_env_var('GITLAB_VERSION', 'foo-ee')
        expect(described_class.is_ee?).to be_truthy
      end
    end
  end

  describe 'include_ee?' do
    it 'returns true when is_ee? is true' do
      allow(described_class).to receive(:is_ee?).and_return(true)
      expect(described_class.include_ee?).to be_truthy
    end

    it 'returns false when we are building a ce package' do
      allow(described_class).to receive(:is_ee?).and_return(false)
      expect(described_class.include_ee?).to be_falsey
    end
  end

  describe 'add tag methods' do
    describe 'is_nightly?' do
      it 'returns true if it is a nightly build' do
        stub_env_var('NIGHTLY', 'true')
        expect(described_class.is_nightly?).to be_truthy
      end

      it 'returns false if it is not a nightly build' do
        expect(described_class.is_nightly?).to be_falsey
      end
    end

    describe 'is_latest_tag?' do
      it 'returns true if it is an rc release' do
        # This will be the case if latest_tag is eg. 9.3.0+rc6.ce.0
        # or 9.3.0+ce.0
        allow(Build::Info::Git).to receive(:latest_tag).and_return('9.3.0+rc6.ce.0') # This line only is only an example, stubbing is not needed.
        allow(described_class).to receive(:match_tag?).and_return(true)
        expect(described_class.is_latest_tag?).to be_truthy
      end

      it 'returns true if it is not an rc release' do
        allow(Build::Info::Git).to receive(:latest_tag).and_return('9.3.0+ce.0') # This line only is only an example, stubbing is not needed.
        allow(described_class).to receive(:match_tag?).and_return(false)
        expect(described_class.is_latest_tag?).to be_falsey
      end
    end

    describe 'is_latest_stable_tag?' do
      it 'returns true if it is a stable release' do
        # This will be the case if latest_tag is eg. 9.3.0+ce.0
        # It will not be the case if the tag is 9.3.0+rc6.ce.0
        allow(Build::Info::Git).to receive(:latest_stable_tag).and_return('9.3.0+ce.0') # This line only is only an example, stubbing is not needed.
        allow(described_class).to receive(:match_tag?).and_return(true)
        expect(described_class.is_latest_stable_tag?).to be_truthy
      end

      it 'returns true if it is not a stable release' do
        allow(Build::Info::Git).to receive(:latest_stable_tag).and_return('9.3.0+rc6.ce.0') # This line only is only an example, stubbing is not needed.
        allow(described_class).to receive(:match_tag?).and_return(false)
        expect(described_class.is_latest_stable_tag?).to be_falsey
      end
    end
  end

  describe '.is_patch_release?' do
    it 'returns true for patch release' do
      allow(Build::Info::Package).to receive(:semver_version).and_return("10.0.3")
      expect(described_class.is_patch_release?).to be_truthy
    end

    it 'returns false for major/minor release' do
      allow(Build::Info::Package).to receive(:semver_version).and_return("10.0.0")
      expect(described_class.is_patch_release?).to be_falsey
    end
  end

  describe 'is_rc_tag?' do
    it 'returns true if it looks like an rc tag' do
      # It will be the case if the tag is 9.3.0+rc6.ce.0
      allow(Build::Info::Git).to receive(:tag_name).and_return('9.3.0+rc6.ce.0')
      expect(described_class.is_rc_tag?).to be_truthy
    end
    it 'returns false if it does not look like an rc tag' do
      # This not be the case if tag is eg. 9.3.0+ce.0
      allow(Build::Info::Git).to receive(:tag_name).and_return('9.3.0+ce.0')
      expect(described_class.is_rc_tag?).to be_falsey
    end
  end

  describe 'is_auto_deploy?' do
    it 'returns true if it looks like an auto-deploy tag' do
      # This is the case if the tag is 11.10.12345+5159f2949cb.59c9fa631
      allow(Build::Info::Git).to receive(:tag_name).and_return('11.10.12345+5159f2949cb.59c9fa631')
      expect(described_class.is_auto_deploy?).to be_truthy
    end

    it 'returns false if it does not look like an auto-deploy tag' do
      # This not be the case if ag is eg. 9.3.0+ce.0
      allow(Gitlab::Util).to receive(:get_env).with('CI_COMMIT_REF_NAME').and_return('a-random-branch')

      allow(Build::Info::Git).to receive(:tag_name).and_return('9.3.0+ce.0')
      expect(described_class.is_auto_deploy?).to be_falsey
    end
  end

  describe 'ci_commit_tag?' do
    it 'checks for the CI_COMMIT_TAG' do
      allow(Gitlab::Util).to receive(:get_env).with('CI_COMMIT_TAG').and_return('11.10.12345+5159f2949cb.59c9fa631')
      expect(described_class.ci_commit_tag?).to be_truthy
    end
  end

  describe 'run_on_ci?' do
    it 'returns true when GITLAB_CI environment variable is set' do
      allow(Gitlab::Util).to receive(:get_env).with('GITLAB_CI').and_return('true')
      expect(described_class.run_on_ci?).to be_truthy
    end

    it 'returns false when GITLAB_CI environment variable is not set' do
      allow(Gitlab::Util).to receive(:get_env).with('GITLAB_CI').and_return(nil)
      expect(described_class.run_on_ci?).to be_falsey
    end
  end

  describe 'on_tag?' do
    context 'when running on CI' do
      before do
        allow(described_class).to receive(:run_on_ci?).and_return(true)
      end

      it 'returns the correct value based on ci_commit_tag? result' do
        [
          { ci_commit_tag_result: true, expected: be_truthy },
          { ci_commit_tag_result: false, expected: be_falsey }
        ].each do |test_case|
          allow(described_class).to receive(:ci_commit_tag?).and_return(test_case[:ci_commit_tag_result])
          expect(described_class.on_tag?).to test_case[:expected]
        end
      end
    end

    context 'when not running on CI' do
      before do
        allow(described_class).to receive(:run_on_ci?).and_return(false)
      end

      it 'returns the correct value based on git describe --exact-match result' do
        [
          { git_result: true, expected: be_truthy },
          { git_result: false, expected: be_falsey }
        ].each do |test_case|
          allow(described_class).to receive(:system).with('git describe --exact-match > /dev/null 2>&1').and_return(test_case[:git_result])
          expect(described_class.on_tag?).to test_case[:expected]
        end
      end
    end
  end

  describe 'on_stable_branch?' do
    context 'when on a stable branch' do
      before do
        stub_branch('14-10-stable')
      end

      it 'returns true' do
        expect(described_class.on_stable_branch?).to be_truthy
      end
    end

    context 'when on a regular branch' do
      before do
        stub_branch('my-feature-branch')
      end

      it 'returns false' do
        expect(described_class.on_stable_branch?).to be_falsey
      end
    end

    context 'when using a tag' do
      before do
        stub_tag('1.2.3')
      end

      it 'returns false' do
        expect(described_class.on_stable_branch?).to be_falsey
      end
    end
  end

  describe 'on_regular_tag?' do
    context 'when on a regular branch' do
      before do
        stub_branch('my-feature-branch')
        allow(described_class).to receive(:system).with(/git describe --exact-match/).and_return(false)
      end

      it 'returns false' do
        expect(described_class.on_regular_tag?).to be_falsey
      end
    end

    context 'when on a stable branch' do
      before do
        stub_branch('15-6-stable')
        allow(described_class).to receive(:system).with(/git describe --exact-match/).and_return(false)
      end

      it 'returns false' do
        expect(described_class.on_regular_tag?).to be_falsey
      end
    end

    context 'when on RC tag' do
      before do
        stub_tag('15.8.0+rc42.ce.0')
        allow(described_class).to receive(:system).with(/git describe --exact-match/).and_return(true)
      end

      it 'returns true' do
        expect(described_class.on_regular_tag?).to be_truthy
      end
    end

    context 'when on stable tag' do
      before do
        stub_tag('15.8.0+ce.0')
        allow(described_class).to receive(:system).with(/git describe --exact-match/).and_return(true)
      end

      it 'returns true' do
        expect(described_class.on_regular_tag?).to be_truthy
      end
    end

    context 'when on auto-deploy tag' do
      before do
        stub_tag('15.8.202301050320+b251a9da107.0e5d6807f3a')
        allow(described_class).to receive(:system).with(/git describe --exact-match/).and_return(true)
      end

      it 'returns false' do
        expect(described_class.on_regular_tag?).to be_falsey
      end
    end
  end

  describe 'on_regular_branch?' do
    context 'when on a regular branch' do
      before do
        stub_branch('my-feature-branch')
      end

      it 'returns true' do
        expect(described_class.on_regular_branch?).to be_truthy
      end
    end

    context 'when on a feature branch MR pipeline' do
      before do
        stub_mr_branch('my-feature-branch')
      end

      it 'returns true' do
        expect(described_class.on_regular_branch?).to be_truthy
      end
    end

    context 'when on a stable branch' do
      before do
        stub_branch('15-6-stable')
      end

      it 'returns false' do
        expect(described_class.on_regular_branch?).to be_falsey
      end
    end

    context 'when on RC tag' do
      before do
        stub_tag('15.8.0+rc42.ce.0')
      end

      it 'returns true' do
        expect(described_class.on_regular_branch?).to be_falsey
      end
    end

    context 'when on stable tag' do
      before do
        stub_tag('15.8.0+ce.0')
      end

      it 'returns true' do
        expect(described_class.on_regular_branch?).to be_falsey
      end
    end

    context 'when on auto-deploy tag' do
      before do
        stub_tag('15.8.202301050320+b251a9da107.0e5d6807f3a')
      end

      it 'returns false' do
        expect(described_class.on_regular_branch?).to be_falsey
      end
    end
  end

  describe 'go_fips_module_version' do
    it 'defaults to the pinned module version' do
      stub_env_var('GO_FIPS_MODULE_VERSION', nil)
      expect(described_class.go_fips_module_version).to eq(Build::Check::GO_FIPS_MODULE_VERSION)
    end

    it 'honors the GO_FIPS_MODULE_VERSION environment variable' do
      stub_env_var('GO_FIPS_MODULE_VERSION', 'v1.2.3')
      expect(described_class.go_fips_module_version).to eq('v1.2.3')
    end
  end

  describe 'use_go_fips_module?' do
    before do
      allow(described_class).to receive_messages(fips?: false, use_system_ssl?: false)
      stub_env_var('USE_GO_FIPS_MODULE', nil)
    end

    it 'is false when nothing asks for the module' do
      expect(described_class.use_go_fips_module?).to be_falsey
    end

    it 'is true when USE_GO_FIPS_MODULE=true' do
      stub_env_var('USE_GO_FIPS_MODULE', 'true')

      expect(described_class.use_go_fips_module?).to be_truthy
    end

    it 'ignores any other USE_GO_FIPS_MODULE value' do
      stub_env_var('USE_GO_FIPS_MODULE', '1')

      expect(described_class.use_go_fips_module?).to be_falsey
    end

    it 'is true on a FIPS build' do
      allow(described_class).to receive(:fips?).and_return(true)

      expect(described_class.use_go_fips_module?).to be_truthy
    end

    it 'is not implied by building against system SSL' do
      allow(described_class).to receive(:use_system_ssl?).and_return(true)

      expect(described_class.use_go_fips_module?).to be_falsey
    end
  end

  describe 'export_go_fips_module_env!' do
    context 'on a FIPS build' do
      before do
        allow(described_class).to receive(:use_go_fips_module?).and_return(true)
        stub_env_var('GO_FIPS_MODULE_VERSION', nil)
      end

      it 'exports the pinned module version to the process environment' do
        expect(Gitlab::Util).to receive(:set_env).with('GOFIPS140', Build::Check::GO_FIPS_MODULE_VERSION)

        described_class.export_go_fips_module_env!
      end

      it 'honors an overridden module version' do
        stub_env_var('GO_FIPS_MODULE_VERSION', 'v1.2.3')

        expect(Gitlab::Util).to receive(:set_env).with('GOFIPS140', 'v1.2.3')

        described_class.export_go_fips_module_env!
      end
    end

    context 'on an ordinary build' do
      before do
        allow(described_class).to receive(:use_go_fips_module?).and_return(false)
      end

      it 'does not touch the process environment' do
        expect(Gitlab::Util).not_to receive(:set_env)

        described_class.export_go_fips_module_env!
      end
    end
  end

  describe 'verify_go_fips_toolchain!' do
    it 'does not look at the toolchain on an ordinary build' do
      allow(described_class).to receive(:use_go_fips_module?).and_return(false)

      expect(described_class).not_to receive(:go_fips_module_check)

      expect { described_class.verify_go_fips_toolchain! }.not_to raise_error
    end

    context 'on a FIPS build' do
      before do
        allow(described_class).to receive(:use_go_fips_module?).and_return(true)
      end

      it 'passes when the toolchain supplies the module' do
        allow(described_class).to receive(:go_fips_module_check).and_return([true, ''])

        expect { described_class.verify_go_fips_toolchain! }.not_to raise_error
      end

      it 'fails when the toolchain does not supply the module' do
        allow(described_class).to receive(:go_fips_module_check).and_return([false, ''])

        expect { described_class.verify_go_fips_toolchain! }.to raise_error(/does not supply it/)
      end

      it 'includes the toolchain error in the failure message' do
        allow(described_class).to receive(:go_fips_module_check)
          .and_return([false, 'go: unknown GOFIPS140 version "v1.0.0"'])

        expect { described_class.verify_go_fips_toolchain! }.to raise_error(/unknown GOFIPS140 version/)
      end
    end
  end

  describe 'go_fips_module_check' do
    let(:probe_env) { { 'GOTOOLCHAIN' => 'local', 'GOFIPS140' => Build::Check::GO_FIPS_MODULE_VERSION } }

    before do
      stub_env_var('GO_FIPS_MODULE_VERSION', nil)
    end

    def stub_probe(success:, stderr:)
      allow(Open3).to receive(:capture3).with(probe_env, 'go', 'list', 'std')
        .and_return(['', stderr, instance_double(Process::Status, success?: success)])
    end

    it 'reports the module as available when the toolchain resolves it' do
      stub_probe(success: true, stderr: '')

      expect(described_class.go_fips_module_check).to eq([true, ''])
    end

    it 'reports the toolchain stderr when the module does not resolve' do
      stub_probe(success: false, stderr: %(go: unknown GOFIPS140 version "v1.1.0"\n))

      expect(described_class.go_fips_module_check).to eq([false, 'go: unknown GOFIPS140 version "v1.1.0"'])
    end

    it 'names the timeout when the toolchain check times out' do
      allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)

      available, error = described_class.go_fips_module_check

      expect(available).to be_falsey
      expect(error).to match(/did not respond within/)
    end

    it 'names the missing executable when no Go is installed' do
      allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)

      available, error = described_class.go_fips_module_check

      expect(available).to be_falsey
      expect(error).to match(/no `go` executable/)
    end
  end
end
