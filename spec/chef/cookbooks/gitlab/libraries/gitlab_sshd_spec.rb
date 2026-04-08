require 'chef_helper'

RSpec.describe GitlabSshd do
  describe '.parse_variables' do
    it 'delegates to validate_trusted_user_ca_keys' do
      expect(described_class).to receive(:validate_trusted_user_ca_keys)

      described_class.parse_variables
    end
  end

  describe '.validate_trusted_user_ca_keys' do
    context 'when trusted_user_ca_keys is nil' do
      before do
        stub_gitlab_rb(gitlab_sshd: { trusted_user_ca_keys: nil })
      end

      it 'does not raise an error' do
        expect { described_class.validate_trusted_user_ca_keys }.not_to raise_error
      end
    end

    context 'when trusted_user_ca_keys is an array' do
      before do
        stub_gitlab_rb(gitlab_sshd: { trusted_user_ca_keys: ['/etc/gitlab/ssh_user_ca.pub'] })
      end

      it 'does not raise an error' do
        expect { described_class.validate_trusted_user_ca_keys }.not_to raise_error
      end
    end

    context 'when trusted_user_ca_keys is a string' do
      before do
        stub_gitlab_rb(gitlab_sshd: { trusted_user_ca_keys: '/etc/gitlab/ssh_user_ca.pub' })
      end

      it 'raises an error' do
        expect { described_class.validate_trusted_user_ca_keys }.to raise_error(
          RuntimeError, /trusted_user_ca_keys.*must be an Array/
        )
      end
    end

    context 'when trusted_user_ca_keys is not set' do
      it 'does not raise an error' do
        expect { described_class.validate_trusted_user_ca_keys }.not_to raise_error
      end
    end
  end
end
