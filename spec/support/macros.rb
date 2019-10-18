require 'openssl'

module GitlabSpec
  module Macros
    def stub_gitlab_rb(config)
      config.each do |key, value|
        value = Mash.from_hash(value) if value.is_a?(Hash)
        allow(Gitlab).to receive(:[]).with(key.to_s).and_return(value)
      end
    end

    def stub_default_should_notify?(value)
      allow(File).to receive(:symlink?).and_return(value)
      allow_any_instance_of(OmnibusHelper).to receive(:success?).and_return(value)
    end

    # @param [String] service internal name of the service (on-disk)
    # @param [Boolean] value status command succeed?
    def stub_service_success_status(service, value)
      allow_any_instance_of(OmnibusHelper).to receive(:success?).with("/opt/gitlab/init/#{service} status").and_return(value)
    end

    # @param [String] service internal name of the service (on-disk)
    # @param [Boolean] value status command failed?
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
      allow(File).to receive(:read).with('VERSION').and_return(value ? '1.2.3-ee' : '1.2.3')
    end

    def stub_is_ee_env(value)
      stub_env_var('ee', value.nil? ? '' : value.to_s)
    end

    def stub_is_ee(value)
      stub_is_ee_version(value)
      stub_is_ee_env(value)
      # Auto-deploys can not be non-EE. So, stubbing it to false for CE builds.
      # However, since not all EE builds need to be auto-deploys, stubbing it
      # to true needs to be done in a case-by-case manner.
      stub_is_auto_deploy(value) unless value
    end

    def stub_is_auto_deploy(value)
      allow(Build::Check).to receive(:is_auto_deploy?).and_return(value)
    end

    def converge_config(*recipes, is_ee: false)
      Gitlab[:node] = nil
      Services.add_services('gitlab-ee', Services::EEServices.list) if is_ee
      config_recipe = is_ee ? 'gitlab-ee::config' : 'gitlab::config'
      ChefSpec::SoloRunner.converge(config_recipe, *recipes)
    end
  end
end
