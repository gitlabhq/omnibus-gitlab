require 'spec_helper'
require 'tmpdir'
require 'gitlab/build/selinux_policy'

RSpec.describe Build::SELinuxPolicy do
  # Compiled from files/gitlab-selinux/gitlab-7.2.0-ssh-keygen.te on
  # AlmaLinux 10 (checkpolicy 3.10) with `checkmodule -M -m -c 19`.
  let(:fixture) { File.expand_path('../../../fixtures/selinux/gitlab-7.2.0-ssh-keygen.pp', __dir__) }

  def policy_package(version, package_magic: described_class::PACKAGE_MAGIC, module_magic: described_class::MODULE_MAGIC)
    name = 'SE Linux Module'
    [package_magic, 1, 1, 16].pack('V4') + [module_magic, name.bytesize].pack('V2') + name + [2, version].pack('V2')
  end

  def write_package(dir, contents)
    File.join(dir, 'test.pp').tap { |path| File.binwrite(path, contents) }
  end

  describe '.checkmodule_flags' do
    using RSpec::Parameterized::TableSyntax

    where(:platform, :version, :flags) do
      'el'     | '7'    | ''
      'el'     | '8'    | ''
      'el'     | nil    | ''
      'el'     | '9'    | '-c 19'
      'el'     | '10'   | '-c 19'
      'amazon' | '2023' | '-c 19'
    end

    with_them do
      before do
        allow(OhaiHelper).to receive(:os_platform).and_return(platform)
        allow(OhaiHelper).to receive(:os_platform_version).and_return(version)
      end

      it 'pins the module format wherever checkmodule accepts -c' do
        expect(described_class.checkmodule_flags).to eq(flags)
      end
    end
  end

  describe '.module_policy_version' do
    it 'reads the format from a package built by semodule_package' do
      expect(described_class.module_policy_version(fixture)).to eq(19)
    end

    it 'reads the format from a synthetic package' do
      Dir.mktmpdir do |dir|
        expect(described_class.module_policy_version(write_package(dir, policy_package(24)))).to eq(24)
      end
    end

    it 'rejects a file that is not a policy package' do
      Dir.mktmpdir do |dir|
        path = write_package(dir, policy_package(19, package_magic: 0))

        expect { described_class.module_policy_version(path) }.to raise_error(/is not an SELinux policy package/)
      end
    end

    it 'rejects a package whose first section is not a module' do
      Dir.mktmpdir do |dir|
        path = write_package(dir, policy_package(19, module_magic: 0))

        expect { described_class.module_policy_version(path) }.to raise_error(/does not start with a policy module/)
      end
    end

    it 'rejects a truncated package' do
      Dir.mktmpdir do |dir|
        path = write_package(dir, policy_package(19)[0, 45])

        expect { described_class.module_policy_version(path) }.to raise_error(/is truncated at byte 43/)
      end
    end
  end

  describe '.verify!' do
    it 'accepts a package in the pinned format' do
      expect { described_class.verify!(fixture) }.not_to raise_error
    end

    it 'rejects a package in any other format' do
      Dir.mktmpdir do |dir|
        path = write_package(dir, policy_package(24))

        expect { described_class.verify!(path) }.to raise_error(/uses SELinux module format 24, expected 19/)
      end
    end
  end
end
