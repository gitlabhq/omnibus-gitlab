require 'spec_helper'
require_relative '../../files/gitlab-cookbooks/package/libraries/helpers/systemd_helper'

describe SystemdHelper do
  describe '#systemd_version' do
    context 'when systemctl returns valid output' do
      before do
        valid_output = <<~OUTPUT
          systemd 242 (242)
          +PAM +AUDIT +SELINUX +IMA +APPARMOR +SMACK +SYSVINIT
        OUTPUT

        allow(IO).to receive(:popen).with(%w[systemctl --version]).and_return(valid_output)
      end

      it 'returns correct version' do
        expect(described_class.systemd_version).to eq(242)
      end
    end

    context 'when systemctl returns invalid output' do
      before do
        invalid_output = <<~OUTPUT
          some invalid output
        OUTPUT

        allow(IO).to receive(:popen).with(%w[systemctl --version]).and_return(invalid_output)
      end

      it 'returns an insanely low version' do
        expect(described_class.systemd_version).to eq(-999)
      end
    end
  end

  describe '#get_tasks_max_value' do
    context 'when systemd_version greater than 227' do
      before do
        allow(described_class).to receive(:systemd_version).and_return(242)
      end

      it 'returns correct value for TasksMax setting' do
        expect(described_class.get_tasks_max_value). to eq(5000)
      end
    end

    context 'when systemd_version less than 227' do
      before do
        allow(described_class).to receive(:systemd_version).and_return(219)
      end

      it 'returns correct value for TasksMax setting' do
        expect(described_class.get_tasks_max_value). to be_nil
      end
    end
  end
end
