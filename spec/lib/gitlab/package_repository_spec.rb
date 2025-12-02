require 'spec_helper'
require 'gitlab/package_repository'

RSpec.describe PackageRepository do
  before do
    allow(ENV).to receive(:[]).and_call_original
  end

  describe '.new (factory method)' do
    context 'when REPOSITORY_TYPE is packagecloud' do
      before do
        stub_env_var('REPOSITORY_TYPE', 'packagecloud')
      end

      it 'returns a PackageCloudRepository instance' do
        expect(PackageRepository.new).to be_a(PackageRepository::PackageCloudRepository)
      end
    end

    context 'when REPOSITORY_TYPE is pulp' do
      before do
        stub_env_var('REPOSITORY_TYPE', 'pulp')
      end

      it 'returns a PulpRepository instance' do
        expect(PackageRepository.new).to be_a(PackageRepository::PulpRepository)
      end
    end

    context 'when REPOSITORY_TYPE is not set' do
      before do
        stub_env_var('REPOSITORY_TYPE', nil)
      end

      it 'defaults to PackageCloudRepository' do
        expect(PackageRepository.new).to be_a(PackageRepository::PackageCloudRepository)
      end
    end

    context 'when REPOSITORY_TYPE is unknown' do
      before do
        stub_env_var('REPOSITORY_TYPE', 'unknown')
      end

      it 'raises an error' do
        expect { PackageRepository.new }.to raise_error(/Unknown repository type: unknown/)
      end
    end
  end

  describe '.repository_type' do
    context 'when REPOSITORY_TYPE is set to packagecloud' do
      before do
        stub_env_var('REPOSITORY_TYPE', 'packagecloud')
      end

      it 'returns packagecloud' do
        expect(PackageRepository.repository_type).to eq 'packagecloud'
      end
    end

    context 'when REPOSITORY_TYPE is set to pulp' do
      before do
        stub_env_var('REPOSITORY_TYPE', 'pulp')
      end

      it 'returns pulp' do
        expect(PackageRepository.repository_type).to eq 'pulp'
      end
    end

    context 'when REPOSITORY_TYPE is not set' do
      before do
        stub_env_var('REPOSITORY_TYPE', nil)
      end

      it 'defaults to packagecloud' do
        expect(PackageRepository.repository_type).to eq 'packagecloud'
      end
    end

    context 'when REPOSITORY_TYPE is empty string' do
      before do
        stub_env_var('REPOSITORY_TYPE', '')
      end

      it 'defaults to packagecloud' do
        expect(PackageRepository.repository_type).to eq 'packagecloud'
      end
    end
  end
end
