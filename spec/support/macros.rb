require 'openssl'

module GitlabSpec
  module Macros
    def stub_gitlab_rb(config)
      config.each do |key, value|
        value = Mash.from_hash(value) if value.is_a?(Hash)
        allow(Gitlab).to receive(:[]).with(key.to_s).and_return(value)
      end
    end

    def stub_service_success_status(service, value)
      allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/init/#{service} status").and_return(value)
    end

    def stub_service_failure_status(service, value)
      allow_any_instance_of(OmnibusHelper).to receive(:failure?).with("/opt/gitlab/init/#{service} status").and_return(value)
    end

    def stub_should_notify?(service, value)
      allow(File).to receive(:symlink?).with("/opt/gitlab/service/#{service}").and_return(value)
      stub_service_success_status(service, value)
    end

    def stub_expected_owner?
      allow_any_instance_of(OmnibusHelper).to receive(:expected_owner?).and_return(true)
    end

    def stub_env_var(var, value)
      allow(ENV).to receive(:[]).with(var).and_return(value)
    end

    def stub_is_ee_version(value)
      allow(Build::Check).to receive(:system).with('grep -q -E "\-ee" VERSION').and_return(value)
    end

    def stub_is_ee_env(value)
      stub_env_var('ee', value.nil? ? '' : value.to_s)
    end

    def stub_is_ee(value)
      stub_is_ee_version(value)
      stub_is_ee_env(value)
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

    def converge_config(*recipes, ee: false)
      Gitlab[:node] = nil
      Services.add_services('gitlab-ee', Services::EEServices.list) if ee
      ChefSpec::SoloRunner.converge('gitlab::config', *recipes)
    end
  end
end
