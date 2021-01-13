require 'chef_helper'

RSpec.describe Services do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  subject(:services) { described_class }

  describe '.enable_group' do
    before do
      chef_run.converge('gitlab::default')
    end

    it 'enables services in provide groups list' do
      expect do
        services.enable_group('pages_role')
      end.to change { services.enabled?('gitlab_pages') }.from(false).to(true)
    end

    it 'skips services that dont `exist?`' do
      expect do
        services.enable_group('monitoring')
      end.not_to change { services.enabled?('pgbouncer_exporter') }
    end
  end

  describe '.disable_group' do
    before do
      chef_run.converge('gitlab::default')
    end

    it 'disables services in the provide groups list when setting to false' do
      expect do
        services.disable_group('redis')
      end.to change { services.enabled?('redis') }.from(true).to(false)
    end

    it 'it allows disabling services in system group when setting to false and include_system: true' do
      expect do
        services.disable_group('system', include_system: true)
      end.to change { services.enabled?('logrotate') }.from(true).to(false)
    end
  end

  describe '.enable' do
    before do
      chef_run.converge('gitlab::default')
    end

    it 'enables provide service' do
      expect do
        services.enable('gitlab_pages')
      end.to change { services.enabled?('gitlab_pages') }.from(false).to(true)
    end

    it 'skips services that dont `exist?`' do
      expect do
        services.enable('pgbouncer_exporter')
      end.not_to change { services.enabled?('pgbouncer_exporter') }
    end
  end

  describe '.disable' do
    before do
      chef_run.converge('gitlab::default')
    end

    it 'disables provide service' do
      expect do
        services.disable('puma')
      end.to change { services.enabled?('puma') }.from(true).to(false)
    end

    it 'allows disabling service in system group when include_system: true' do
      expect do
        services.disable('logrotate', include_system: true)
      end.to change { services.enabled?('logrotate') }.from(true).to(false)
    end
  end

  describe '.set_status' do
    before do
      chef_run.converge('gitlab::default')
    end

    it 'enables provide service when setting to true' do
      expect do
        services.set_status('gitlab_pages', true)
      end.to change { services.enabled?('gitlab_pages') }.from(false).to(true)
    end

    it 'disables provide service when setting to false' do
      expect do
        services.set_status('puma', false)
      end.to change { services.enabled?('puma') }.from(true).to(false)
    end

    it 'allows disabling service in system group when setting to false and include_system: true' do
      expect do
        services.set_status('logrotate', false, include_system: true)
      end.to change { services.enabled?('logrotate') }.from(true).to(false)
    end
  end

  describe '.set_group_status' do
    before do
      chef_run.converge('gitlab::default')
    end

    it 'enables services in provide groups list when setting to true' do
      expect do
        services.set_group_status('pages_role', true)
      end.to change { services.enabled?('gitlab_pages') }.from(false).to(true)
    end

    it 'disables services in the provide groups list when setting to false' do
      expect do
        services.set_group_status('redis', false)
      end.to change { services.enabled?('redis') }.from(true).to(false)
    end

    it 'it allows disabling services in system group when setting to false and include_system: true' do
      expect do
        services.set_group_status('system', false, include_system: true)
      end.to change { services.enabled?('logrotate') }.from(true).to(false)
    end
  end

  describe '.system_services' do
    it 'returns a list of services that are in the SYSTEM_GROUP' do
      service_list = {
        'redis' => { groups: %w[redis] },
        'logrotate' => { groups: %w[system] }
      }
      services.add_services('test', service_list)

      expect(services.system_services).to include('logrotate')
    end
  end

  describe '.find_by_group' do
    before do
      service_list = {
        'redis' => { groups: %w[redis] },
        'redis_exporter' => { groups: %w[redis monitoring] }
      }

      services.add_services('test', service_list)
    end

    it 'returns a list of services that matches provided groups' do
      expect(services.find_by_group('monitoring')).to eq(['redis_exporter'])
    end

    it 'returns an empty list when no provide groups match' do
      expect(services.find_by_group('non_existent')).to eq([])
    end
  end

  describe '.service_list' do
    it 'returns a list of loaded known services by existing cookbooks' do
      chef_run.converge('gitlab::default')

      expect(services.service_list).to include(Services::BaseServices.list)
    end
  end

  describe '.add_services' do
    it 'adds provided services and register associated cookbook' do
      services.add_services('gitlab', Services::BaseServices.list)

      expect(services.service_list).to include(Services::BaseServices.list)
      expect(services.send(:cookbook_services).keys).to include('gitlab')
    end
  end

  describe '.enabled?' do
    before do
      chef_run.converge('gitlab::default')
    end

    context 'when status is set via configuration file' do
      it 'returns true if set as enabled' do
        Gitlab['mailroom']['enable'] = true

        expect(services.enabled?('mailroom')).to be_truthy
      end

      it 'returns false if set as disabled' do
        Gitlab['puma']['enable'] = false

        expect(services.enabled?('puma')).to be_falsey
      end
    end

    context 'when status is not set via configuration file' do
      it 'returns true when its enabled via cookbooks' do
        expect(services.enabled?('puma')).to be_truthy
      end

      it 'returns false when disabled via cookbooks' do
        expect(services.enabled?('mailroom')).to be_falsey
      end
    end
  end

  describe '.exist?' do
    it 'returns false for non existing service' do
      expect(services.exist?('inexistent_service')).to be_falsey
    end

    context 'with only CE services registered' do
      it 'returns true for CE services and false for EE services' do
        chef_run.converge('gitlab::default')

        expect(services.exist?('logrotate')).to be_truthy
        expect(services.exist?('pgbouncer_exporter')).to be_falsey
      end
    end

    context 'with CE and EE services registered' do
      it 'returns true for EE services registered via add_service' do
        chef_run.converge('gitlab::default', 'gitlab-ee::default')

        expect(services.exist?('logrotate')).to be_truthy
        expect(services.exist?('pgbouncer_exporter')).to be_truthy
      end
    end
  end
end
