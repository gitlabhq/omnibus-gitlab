require 'chef_helper'

RSpec.describe 'GitLabRoles' do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(Services).to receive(:enable_group).and_call_original
  end

  after do
    # Disable all roles after each test to clean the environment
    Gitlab.available_roles.each { |name, _value| Gitlab["#{name}_role"]['enable'] = false }
  end

  describe 'roles config array' do
    it 'enables roles listed in the roles array' do
      stub_gitlab_rb(roles: %w(application_role geo_primary_role))

      Gitlab.load_roles

      expect(Gitlab['application_role']['enable']).to be true
      expect(Gitlab['geo_primary_role']['enable']).to be true
    end

    it 'supports providing a single role as a string' do
      stub_gitlab_rb(roles: 'application_role')

      Gitlab.load_roles

      expect(Gitlab['application_role']['enable']).to be true
    end

    it 'handles users specifying hyphens instead of underscores' do
      stub_gitlab_rb(roles: ['geo-primary-role'])

      Gitlab.load_roles

      expect(Gitlab['geo_primary_role']['enable']).to be true
    end

    it 'throws errors when an invalid role is used' do
      stub_gitlab_rb(roles: ['some_invalid_role'])

      expect { Gitlab.load_roles }.to raise_error(RuntimeError, /invalid roles have been set/)
    end
  end

  describe 'DefaultRole' do
    before do
      allow(DefaultRole).to receive(:load_role).and_call_original
      allow(GeoPrimaryRole).to receive(:load_role).and_call_original
    end

    it 'enables the default services when no other roles are active' do
      Gitlab.load_roles

      expect(Services).to have_received(:enable_group).with(Services::DEFAULT_GROUP, anything).once
    end

    it 'enables the default services when no "service managed" roles are active' do
      stub_gitlab_rb(geo_primary_role: { enable: true })

      Gitlab.load_roles

      expect(Services).to have_received(:enable_group).with(Services::DEFAULT_GROUP, anything).once
      expect(GeoPrimaryRole).to have_received(:load_role)
    end

    it 'leaves the default services disabled when another role is active' do
      stub_gitlab_rb(application_role: { enable: true })

      Gitlab.load_roles

      expect(DefaultRole).to have_received(:load_role)
      expect(Services).not_to have_received(:enable_group).with(Services::DEFAULT_GROUP, anything)
    end

    it 'leaves rails roles disabled when requested to maintain backward compat' do
      stub_gitlab_rb(gitlab_rails: { enable: false })

      Gitlab.load_roles

      expect(Services).to have_received(:enable_group).with(Services::DEFAULT_GROUP, hash_including(except: ['rails'])).once
    end

    it 'leaves skip_on_fips services disabled when on FIPS environment' do
      allow(OpenSSL).to receive(:fips_mode).and_return(true)

      Gitlab.load_roles

      expect(Services).to have_received(:enable_group).with(Services::DEFAULT_GROUP, hash_including(except: ['skip_on_fips'])).once
    end
  end

  describe 'ApplicationRole' do
    before do
      allow(ApplicationRole).to receive(:load_role).and_call_original
    end

    it 'enables the rails services' do
      stub_gitlab_rb(application_role: { enable: true })

      Gitlab.load_roles

      expect(ApplicationRole).to have_received(:load_role)
      expect(Gitlab['gitlab_rails']['enable']).to eq true
      expect(Services).to have_received(:enable_group).with('rails', except: []).once
    end

    it 'leaves skip_on_fips services disabled when on FIPS environment' do
      allow(OpenSSL).to receive(:fips_mode).and_return(true)

      stub_gitlab_rb(application_role: { enable: true })

      Gitlab.load_roles

      expect(Services).to have_received(:enable_group).with('rails', except: ['skip_on_fips']).once
    end
  end

  describe 'MonitoringRole' do
    before do
      allow(MonitoringRole).to receive(:load_role).and_call_original
    end

    it 'enables the monitoring services' do
      stub_gitlab_rb(roles: %w(monitoring_role))

      Gitlab.load_roles

      expect(MonitoringRole).to have_received(:load_role)
      expect(Services).to have_received(:enable_group).with('monitoring_role').once
    end
  end
end
