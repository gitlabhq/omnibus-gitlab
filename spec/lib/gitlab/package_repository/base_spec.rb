require 'spec_helper'
require 'gitlab/package_repository/base'

RSpec.describe PackageRepository::Base do
  let(:base_instance) { described_class.new }

  describe 'abstract methods' do
    it 'raises NotImplementedError for #upload' do
      expect { base_instance.upload }.to raise_error(NotImplementedError, /must implement #upload/)
    end

    it 'raises NotImplementedError for #target' do
      expect { base_instance.target }.to raise_error(NotImplementedError, /must implement #target/)
    end

    it 'raises NotImplementedError for #user' do
      expect { base_instance.user }.to raise_error(NotImplementedError, /must implement #user/)
    end
  end

  describe '#repository_for_rc' do
    context 'on master' do
      # Example:
      # on non stable branch: 8.1.0+rc1.ce.0-1685-gd2a2c51
      # on tag: 8.12.0+rc1.ee.0
      before do
        allow(IO).to receive(:popen).with(%w[git describe]).and_return("8.12.0+rc1.ee.0\n")
      end

      it 'returns unstable' do
        expect(base_instance.repository_for_rc).to eq 'unstable'
      end
    end

    context 'on stable branch' do
      # Example:
      # on non stable branch: 8.12.8+ce.0-1-gdac92d4
      # on tag: 8.12.8+ce.0
      before do
        allow(IO).to receive(:popen).with(%w[git describe]).and_return("8.12.8+ce.0\n")
      end

      it 'returns nil' do
        expect(base_instance.repository_for_rc).to eq nil
      end
    end
  end

  describe '#validate' do
    context 'with artifacts available' do
      before do
        allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/el-6/gitlab-ce.rpm'])
      end

      it 'in dry run mode prints the checksum commands' do
        expect { base_instance.validate(true) }.to output("sha256sum -c pkg/el-6/gitlab-ce.rpm.sha256\n").to_stdout
      end

      it 'raises an exception when there is a mismatch' do
        expect(base_instance).to receive(:verify_checksum).with('pkg/el-6/gitlab-ce.rpm.sha256', true).and_return(false)

        expect { base_instance.validate(true) }.to raise_error(%r{Aborting, package .* has an invalid checksum!})
      end
    end

    context 'with artifacts unavailable' do
      before do
        allow(Build::Info::Package).to receive(:file_list).and_return([])
      end

      it 'prints nothing' do
        expect { base_instance.validate(true) }.to output('').to_stdout
      end
    end
  end
end
