require 'openssl'

module GitlabSpec
  module Macros
    def stub_gitlab_rb(config)
      config.each do |key, value|
        value = Mash.from_hash(value) if value.is_a?(Hash)
        allow(Gitlab).to receive(:[]).with(key.to_s).and_return(value)
      end
    end

    def stub_should_notify?(service, value)
      allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(value)
      allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/embedded/bin/sv status #{service}").and_return(value)
    end

    def stub_env_var(var, value)
      allow(ENV).to receive(:[]).with(var).and_return(value)
    end

    # a small helper function that creates a SHA1 fingerprint from a private or
    # public key.
    def create_fingerprint_from_key(key, passphrase = nil)
      new_key = OpenSSL::PKey::RSA.new(key, passphrase)
      new_key_digest = OpenSSL::Digest::SHA1.new(new_key.public_key.to_der).to_s.scan(/../).join(':')
      new_key_digest
    end

    def create_fingerprint_from_public_key(public_key)
      ::SSHKeygen::PublicKeyReader.new(public_key).key_fingerprint
    end
  end
end
