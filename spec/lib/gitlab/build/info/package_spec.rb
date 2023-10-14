require 'spec_helper'
require 'gitlab/build/info/package'

RSpec.describe Build::Info::Package do
  before do
    stub_default_package_version
    stub_env_var('GITLAB_ALTERNATIVE_REPO', nil)
    stub_env_var('ALTERNATIVE_PRIVATE_TOKEN', nil)
  end

  describe '.name' do
    describe 'shows EE' do
      it 'when ee=true' do
        stub_is_ee_env(true)
        expect(described_class.name).to eq('gitlab-ee')
      end

      it 'when env var is not present, checks VERSION file' do
        stub_is_ee_version(true)
        expect(described_class.name).to eq('gitlab-ee')
      end
    end

    describe 'shows CE' do
      it 'by default' do
        stub_is_ee(false)
        expect(described_class.name).to eq('gitlab-ce')
      end
    end
  end

  describe '.semver_version' do
    context 'on tags' do
      before do
        allow(Build::Check).to receive(:on_tag?).and_return(true)
        allow_any_instance_of(Omnibus::BuildVersion).to receive(:semver).and_return('12.121.12')
      end

      it 'returns tag version as expected' do
        expect(described_class.semver_version).to eq('12.121.12')
      end
    end

    context 'on branches' do
      before do
        allow(Build::Check).to receive(:on_tag?).and_return(false)
        allow(Build::Info::Git).to receive(:latest_tag).and_return('16.2.0+ee.0')
        allow(Build::Info::Git).to receive(:commit_sha).and_return('a53418a1')
        stub_env_var('CI_PIPELINE_ID', '12345')
      end

      context 'on nightlies' do
        before do
          allow(Build::Check).to receive(:is_nightly?).and_return(true)
          allow(Build::Check).to receive(:use_system_ssl?).and_return(false)
        end

        it 'returns computed version as expected' do
          expect(described_class.semver_version).to eq('16.2.0+rnightly.12345.a53418a1')
        end
      end

      context 'on FIPS nightlies' do
        before do
          allow(Build::Check).to receive(:is_nightly?).and_return(true)
          allow(Build::Check).to receive(:use_system_ssl?).and_return(true)
        end

        it 'returns computed version as expected' do
          expect(described_class.semver_version).to eq('16.2.0+rnightly.fips.12345.a53418a1')
        end
      end

      context 'on regular branches' do
        before do
          allow(Build::Check).to receive(:is_nightly?).and_return(false)
          allow(Build::Check).to receive(:use_system_ssl?).and_return(false)
        end

        it 'returns computed version as expected' do
          expect(described_class.semver_version).to eq('16.2.0+rfbranch.12345.a53418a1')
        end
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

    it 'defaults to an initial build version when there are no matching tags' do
      allow(Build::Check).to receive(:on_tag?).and_return(false)
      allow(Build::Check).to receive(:is_nightly?).and_return(false)
      allow(Build::Info::Git).to receive(:latest_tag).and_return('')
      allow(Build::Info::Git).to receive(:commit_sha).and_return('ffffffff')
      stub_env_var('CI_PIPELINE_ID', '5555')

      expect(described_class.release_version).to eq('0.0.1+rfbranch.5555.ffffffff-ce.1')
    end

    describe 'with env variables' do
      it 'returns build version and iteration with env variable' do
        stub_env_var('USE_S3_CACHE', 'false')
        stub_env_var('CACHE_AWS_ACCESS_KEY_ID', 'NOT-KEY')
        stub_env_var('CACHE_AWS_SECRET_ACCESS_KEY', 'NOT-SECRET-KEY')
        stub_env_var('CACHE_AWS_BUCKET', 'bucket')
        stub_env_var('CACHE_AWS_S3_REGION', 'moon-west1')
        stub_env_var('CACHE_AWS_S3_ENDPOINT', 'endpoint')
        stub_env_var('CACHE_S3_ACCELERATE', 'sure')

        stub_env_var('NIGHTLY', 'true')
        stub_env_var('CI_PIPELINE_ID', '5555')

        expect(described_class.release_version).to eq('12.121.12-ce.1')
      end
    end
  end
end
