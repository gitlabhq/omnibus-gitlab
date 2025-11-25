require 'spec_helper'
require 'gitlab/package_repository/base'
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

    context 'with rpm package' do
      it 'returns RpmPackage instance' do
        package_type = described_class.from_filename('gitlab-ce.rpm')
        expect(package_type).to be_a(PackageRepository::PulpRepository::RpmPackage)
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

  before do
    # Prevent any real pulp command execution in all tests
    allow(Gitlab::Util).to receive(:shellout_stdout).and_return('') if defined?(Gitlab::Util)
  end

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

  describe '#extract_distribution' do
    it 'extracts distribution from platform with architecture suffix' do
      expect(package_type.extract_distribution('ubuntu-focal_aarch64')).to eq('ubuntu/focal')
    end

    it 'extracts distribution from platform with fips suffix' do
      expect(package_type.extract_distribution('ubuntu-focal_fips')).to eq('ubuntu/focal')
    end

    it 'extracts distribution from platform without suffix' do
      expect(package_type.extract_distribution('ubuntu-focal')).to eq('ubuntu/focal')
    end

    it 'extracts distribution from ubuntu-jammy' do
      expect(package_type.extract_distribution('ubuntu-jammy')).to eq('ubuntu/jammy')
    end

    it 'extracts distribution from debian-bullseye' do
      expect(package_type.extract_distribution('debian-bullseye')).to eq('debian/bullseye')
    end

    context 'with various platform directory formats' do
      it 'handles ubuntu-focal_aarch64 (gitlab-ce)' do
        expect(package_type.extract_distribution('ubuntu-focal_aarch64')).to eq('ubuntu/focal')
      end

      it 'handles ubuntu-focal (gitlab-ee)' do
        expect(package_type.extract_distribution('ubuntu-focal')).to eq('ubuntu/focal')
      end

      it 'handles ubuntu-focal (nightly-builds)' do
        expect(package_type.extract_distribution('ubuntu-focal')).to eq('ubuntu/focal')
      end

      it 'handles ubuntu-focal (pre-release)' do
        expect(package_type.extract_distribution('ubuntu-focal')).to eq('ubuntu/focal')
      end

      it 'handles ubuntu-focal_fips (pre-release)' do
        expect(package_type.extract_distribution('ubuntu-focal_fips')).to eq('ubuntu/focal')
      end

      it 'handles ubuntu-focal_fips (nightly-fips-builds)' do
        expect(package_type.extract_distribution('ubuntu-focal_fips')).to eq('ubuntu/focal')
      end

      it 'handles ubuntu-focal_fips (gitlab-fips)' do
        expect(package_type.extract_distribution('ubuntu-focal_fips')).to eq('ubuntu/focal')
      end
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

    it 'uses repository_name as distribution' do
      cmd = package_type.build_upload_command(
        file_path: 'pkg/ubuntu-focal/gitlab-ce.deb',
        repository_name: 'gitlab-gitlab-ee-ubuntu-focal',
        distribution: 'gitlab-gitlab-ee-ubuntu-focal',
        component: 'main',
        chunk_size: 10_000_000
      )

      expect(cmd[7]).to eq('gitlab-gitlab-ee-ubuntu-focal') # --repository value
      expect(cmd[9]).to eq('gitlab-gitlab-ee-ubuntu-focal') # --distribution value
    end
  end
end

RSpec.describe PackageRepository::PulpRepository::RpmPackage do
  let(:package_type) { described_class.new }

  before do
    # Prevent any real pulp command execution in all tests
    allow(Gitlab::Util).to receive(:shellout_stdout).and_return('') if defined?(Gitlab::Util)
  end

  describe '#initialize' do
    it 'sets file_extension to .rpm' do
      expect(package_type.file_extension).to eq('.rpm')
    end
  end

  describe '#type_name' do
    it 'returns rpm' do
      expect(package_type.type_name).to eq('rpm')
    end
  end

  describe '#extract_distribution' do
    it 'extracts distribution with architecture from platform' do
      expect(package_type.extract_distribution('el-8_aarch64')).to eq('el/8/aarch64')
    end

    it 'extracts distribution with x86_64 default when no architecture suffix' do
      expect(package_type.extract_distribution('el-9')).to eq('el/9/x86_64')
    end

    it 'extracts distribution from platform with fips suffix' do
      expect(package_type.extract_distribution('el-9_fips')).to eq('el/9/x86_64')
    end

    it 'extracts distribution from amazon platform' do
      expect(package_type.extract_distribution('amazon-2023_aarch64')).to eq('amazon/2023/aarch64')
    end

    it 'extracts distribution from opensuse platform' do
      expect(package_type.extract_distribution('opensuse-15.6')).to eq('opensuse/15.6/x86_64')
    end

    it 'extracts distribution from opensuse platform with architecture' do
      expect(package_type.extract_distribution('opensuse-15.6_aarch64')).to eq('opensuse/15.6/aarch64')
    end

    context 'with various platform directory formats' do
      it 'handles el-8_aarch64 (gitlab-ce)' do
        expect(package_type.extract_distribution('el-8_aarch64')).to eq('el/8/aarch64')
      end

      it 'handles amazon-2023_aarch64 (gitlab-ce)' do
        expect(package_type.extract_distribution('amazon-2023_aarch64')).to eq('amazon/2023/aarch64')
      end

      it 'handles el-8 (gitlab-ee) - defaults to x86_64' do
        expect(package_type.extract_distribution('el-8')).to eq('el/8/x86_64')
      end

      it 'handles amazon-2023_aarch64 (gitlab-ee)' do
        expect(package_type.extract_distribution('amazon-2023_aarch64')).to eq('amazon/2023/aarch64')
      end

      it 'handles opensuse-15.6 (pre-release) - defaults to x86_64' do
        expect(package_type.extract_distribution('opensuse-15.6')).to eq('opensuse/15.6/x86_64')
      end

      it 'handles amazon-2023_fips (nightly-fips-builds)' do
        expect(package_type.extract_distribution('amazon-2023_fips')).to eq('amazon/2023/x86_64')
      end

      it 'handles el-9_fips (gitlab-fips)' do
        expect(package_type.extract_distribution('el-9_fips')).to eq('el/9/x86_64')
      end
    end
  end

  describe '#build_upload_command' do
    it 'builds correct rpm upload command' do
      cmd = package_type.build_upload_command(
        file_path: 'pkg/el-9/gitlab-ce.rpm',
        repository_name: 'gitlab-unstable-el-9-x86_64',
        distribution: 'gitlab-unstable-el-9-x86_64',
        component: 'main',
        chunk_size: 10_000_000
      )

      expect(cmd).to eq(['pulp', 'rpm', 'content', '-t', 'package', 'upload',
                         '--file', 'pkg/el-9/gitlab-ce.rpm',
                         '--repository', 'gitlab-unstable-el-9-x86_64',
                         '--chunk-size', '10000000'])
    end

    it 'builds correct rpm upload command with architecture' do
      cmd = package_type.build_upload_command(
        file_path: 'pkg/el-9_aarch64/gitlab-ce.rpm',
        repository_name: 'gitlab-unstable-el-9-aarch64',
        distribution: 'gitlab-unstable-el-9-aarch64',
        component: 'main',
        chunk_size: 10_000_000
      )

      expect(cmd).to eq(['pulp', 'rpm', 'content', '-t', 'package', 'upload',
                         '--file', 'pkg/el-9_aarch64/gitlab-ce.rpm',
                         '--repository', 'gitlab-unstable-el-9-aarch64',
                         '--chunk-size', '10000000'])
    end

    it 'does not include distribution and component flags' do
      cmd = package_type.build_upload_command(
        file_path: 'pkg/el-9/gitlab-ce.rpm',
        repository_name: 'gitlab-unstable-el-9-x86_64',
        distribution: 'gitlab-unstable-el-9-x86_64',
        component: 'main',
        chunk_size: 10_000_000
      )

      expect(cmd).not_to include('--distribution')
      expect(cmd).not_to include('--component')
    end
  end
end
