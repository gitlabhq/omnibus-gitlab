require 'spec_helper'

RSpec.describe SystemdHelper do
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
end
