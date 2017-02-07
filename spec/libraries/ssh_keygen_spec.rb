require 'chef_helper'

describe SSHKeygen::Generator do
  context 'default options with a bit strength of 2048' do
    key = ::SSHKeygen::Generator.new(2048, 'rsa', nil, 'test@rspec')

    it 'has a valid PEM-encoded private key' do
      generator_key_digest = key.key_fingerprint
      validator_key_digest = create_fingerprint_from_key(key.private_key)

      expect(generator_key_digest).to eq(validator_key_digest)
    end

    it 'has a valid OpenSSH-style formatted-public key' do
      expect(key.ssh_public_key).to match(%r{^ssh-rsa [a-zA-Z0-9=/+]+ test@rspec})
    end

    it 'has a valid public key for the private key' do
      generator_key_digest = key.key_fingerprint
      public_key = key.ssh_public_key
      public_key_digest = create_fingerprint_from_public_key(public_key)

      expect(generator_key_digest).to eq(public_key_digest)
    end
  end

  context 'with passphrase and a bit strength of 2048' do
    key = ::SSHKeygen::Generator.new(2048, 'rsa', 'onetwothreefour', 'test@rspec')

    it 'has a valid PEM-encoded private key' do
      generator_key_digest = key.key_fingerprint
      validator_key_digest = create_fingerprint_from_key(key.private_key, 'onetwothreefour')

      expect(generator_key_digest).to eq(validator_key_digest)
    end

    it 'has a valid OpenSSH-style formatted-public key' do
      expect(key.ssh_public_key).to match(%r{^ssh-rsa [a-zA-Z0-9=/+]+ test@rspec})
    end

    it 'has a valid public key for the private key' do
      generator_key_digest = key.key_fingerprint
      public_key = key.ssh_public_key
      public_key_digest = create_fingerprint_from_public_key(public_key)

      expect(generator_key_digest).to eq(public_key_digest)
    end
  end
end

describe SSHKeygen::Helper do
  subject { (Class.new { include SSHKeygen::Helper }).new }

  describe '#key_exists?' do
    let(:keypath) { '/var/opt/gitlab/.ssh/id_rsa' }

    before do
      allow(subject).to receive_message_chain(:new_resource, :path) { keypath }
    end

    it 'returns true when file exists' do
      allow(::File).to receive(:exists?).with(keypath) { true }
    end
  end

  describe '#user_and_group_exists?' do
    before do
      allow(subject).to receive_message_chain(:new_resource, :owner) { 'git' }
      allow(subject).to receive_message_chain(:new_resource, :group) { 'gitlab' }
    end

    it 'delegates check to user_exists? and group_exists?' do
      expect_any_instance_of(OmnibusHelper).to receive(:user_exists?) { true }
      expect_any_instance_of(OmnibusHelper).to receive(:group_exists?) { true }

      expect(subject.user_and_group_exists?).to be_truthy
    end
  end
end
