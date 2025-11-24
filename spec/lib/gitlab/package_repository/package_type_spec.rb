require 'spec_helper'
require 'gitlab/package_repository/package_type'

RSpec.describe PackageRepository::PulpRepository::PackageType do
  describe '#initialize' do
    it 'sets file_extension' do
      package_type = described_class.new('.test')
      expect(package_type.file_extension).to eq('.test')
    end
  end

  describe '.from_filename' do
    context 'with deb package' do
      it 'returns DebPackage instance' do
        package_type = described_class.from_filename('gitlab-ce.deb')
        expect(package_type).to be_a(PackageRepository::PulpRepository::DebPackage)
      end
    end

    context 'with unknown package type' do
      it 'raises an error' do
        expect { described_class.from_filename('gitlab-ce.tar.gz') }.to raise_error(/Unknown package type/)
      end
    end
  end
end

RSpec.describe PackageRepository::PulpRepository::DebPackage do
  let(:package_type) { described_class.new }

  describe '#initialize' do
    it 'sets file_extension to .deb' do
      expect(package_type.file_extension).to eq('.deb')
    end
  end

  describe '#type_name' do
    it 'returns deb' do
      expect(package_type.type_name).to eq('deb')
    end
  end

  describe '#transform_platform' do
    it 'strips architecture suffix from platform name' do
      expect(package_type.transform_platform('ubuntu-focal_aarch64')).to eq('ubuntu-focal')
    end

    it 'strips fips suffix from platform name' do
      expect(package_type.transform_platform('ubuntu-focal_fips')).to eq('ubuntu-focal')
    end

    it 'returns platform name unchanged if no suffix' do
      expect(package_type.transform_platform('ubuntu-focal')).to eq('ubuntu-focal')
    end
  end

  describe '#build_upload_command' do
    it 'builds correct deb upload command' do
      cmd = package_type.build_upload_command(
        file_path: 'pkg/ubuntu-focal/gitlab-ce.deb',
        repository_name: 'gitlab-unstable-ubuntu-focal',
        distribution: 'gitlab-unstable-ubuntu-focal',
        component: 'main',
        chunk_size: 10_000_000
      )

      expect(cmd).to eq(['pulp', 'deb', 'content', 'upload',
                         '--file', 'pkg/ubuntu-focal/gitlab-ce.deb',
                         '--repository', 'gitlab-unstable-ubuntu-focal',
                         '--distribution', 'gitlab-unstable-ubuntu-focal',
                         '--component', 'main',
                         '--chunk-size', '10000000'])
    end
  end
end
