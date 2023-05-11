# frozen_string_literal: true
require 'chef_helper'

RSpec.describe SELinuxDistroHelper do
  context 'when the system is able to use selinux' do
    using RSpec::Parameterized::TableSyntax

    # Only test platforms we make guarantees against
    where(:platform, :platform_version, :is_supported) do
      'redhat' | '2.0' | false
      'redhat' | '7.0' | true
      'redhat' | '8.0' | true
      'almalinux' | '8.0' | true
      'almalinux' | '9.0' | true
      'centos' | '8.0' | true
      'centos' | '7.0' | true
      'amzn' | '2' | true
      'notadistro' | '42' | false
      nil | '7' | false
      'redhat' | nil | false
    end

    with_them do
      context 'when checking for selinux support' do
        before do
          allow(SELinuxDistroHelper).to receive(:platform).and_return(platform)
          allow(SELinuxDistroHelper).to receive(:platform_version).and_return(platform_version)
        end

        it 'correctly identifies whether SELinux is supported' do
          expect(SELinuxDistroHelper.selinux_supported?).to be(is_supported)
        end
      end
    end
  end

  context 'when a release file cannot be found' do
    before do
      allow(File).to receive(:exist?).and_return(false)
    end

    # each sub method within selinux_supported? is tested by this check thus
    # none of them are explicitly added here
    context 'when checking for selinux compatibility' do
      it 'expects selinux_supported? to be false' do
        expect(SELinuxDistroHelper.selinux_supported?).to be false
      end
    end
  end

  let(:os_release) do
    <<-EOF
ID="MyFavoriteDistro"
VERSION="42"
    EOF
  end
  let(:redhat_release) do
    <<-EOF
AlmaLinux release 8.4
    EOF
  end
  let(:unknown_release) do
    <<-EOF
LINUX_DISTRO_ID="Litterbox"
CURRENT_VERSION="5"
    EOF
  end

  context 'when a release file is found' do
    context 'when parsing standard os-release formatted files' do
      before do
        allow(SELinuxDistroHelper).to receive(:read_release_file).and_return(nil)
        allow(SELinuxDistroHelper).to receive(:read_release_file).with(SELinuxDistroHelper::OS_RELEASE_FILE).and_return(os_release)
      end

      it 'should find the distro identifier' do
        expect(SELinuxDistroHelper.platform).not_to be_nil
      end

      it 'should find the distro version' do
        expect(SELinuxDistroHelper.platform_version).not_to be_nil
      end
    end

    context 'when parsing redhat release formats' do
      before do
        allow(SELinuxDistroHelper).to receive(:read_release_file).and_return(nil)
        allow(SELinuxDistroHelper).to receive(:read_release_file).with(SELinuxDistroHelper::REDHAT_RELEASE_FILE).and_return(redhat_release)
      end

      it 'should find the distro identifier' do
        expect(SELinuxDistroHelper.platform).not_to be_nil
      end

      it 'should find the distro version' do
        expect(SELinuxDistroHelper.platform_version).not_to be_nil
      end
    end

    context 'when parsing unknown release formats' do
      before do
        allow(SELinuxDistroHelper).to receive(:read_release_file).and_return(nil)
        allow(SELinuxDistroHelper).to receive(:read_release_file).with(SELinuxDistroHelper::OS_RELEASE_FILE).and_return(unknown_release)
      end

      it 'should find the distro identifier' do
        expect(SELinuxDistroHelper.platform).to be_nil
      end

      it 'should find the distro version' do
        expect(SELinuxDistroHelper.platform_version).to be_nil
      end
    end
  end
end
