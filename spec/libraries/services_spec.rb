require 'chef_helper'

RSpec.describe Services do
  before { allow(Gitlab).to receive(:[]).and_call_original }

  describe 'when using the gitlab cookbook' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

    it 'returns the gitlab service list' do
      chef_run
      expect(Services.service_list).to have_key('puma')
      expect(Services.service_list).not_to have_key('sentinel')
    end
  end

  describe 'when using the gitlab-ee cookbook' do
    let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

    it 'returns the gitlab service list including gitlab-ee items' do
      chef_run
      expect(Services.service_list).to have_key('puma')
      expect(Services.service_list).to have_key('sentinel')
    end
  end

  it 'uses the default template when populating service information' do
    expect(Services::Config.send(:service, ['test_service'])).to eq({ groups: [] })
  end

  describe 'service' do
    let(:runner) { ChefSpec::SoloRunner.new }
    let(:chef_run) { runner.converge('gitlab::config') }
    let(:node) { runner.node }

    before { Services.add_services('gitlab', Services::BaseServices.list) }

    context 'when using user values that conflict with service settings' do
      let!(:runner) { ChefSpec::SoloRunner.new { |node| Gitlab[:node] = node } }

      it 'node service settings are overridden by gitlab.rb changes' do
        stub_gitlab_rb(redis: { enable: true }, mattermost: { enable: false })
        Services.disable('redis')
        Services.enable('mattermost')
        runner.converge('gitlab::config')

        expect(node['redis']['enable']).to be true
        expect(node['mattermost']['enable']).to be false
      end
    end

    context 'when enable/disable is passed a single service' do
      it 'sets the correct values' do
        chef_run
        Services.disable('redis')
        expect(node['redis']['enable']).to be false

        Services.enable('mattermost')
        expect(node['mattermost']['enable']).to be true
      end

      it 'supports exceptions' do
        chef_run
        Services.disable('mattermost')
        Services.enable('mattermost', except: 'mattermost')
        expect(node['mattermost']['enable']).to be false

        Services.enable('redis')
        Services.disable('redis', except: 'redis')
        expect(node['redis']['enable']).to be true
      end
    end

    context 'when enable/disable is passed multiple services' do
      before { chef_run }

      it 'sets the correct values' do
        Services.disable('redis', 'postgresql', 'gitaly')
        expect(node['redis']['enable']).to be false
        expect(node['postgresql']['enable']).to be false
        expect(node['gitaly']['enable']).to be false

        Services.enable('mattermost', 'registry', 'mailroom')
        expect(node['mattermost']['enable']).to be true
        expect(node['registry']['enable']).to be true
        expect(node['gitlab']['mailroom']['enable']).to be true
      end

      it 'supports single exceptions' do
        Services.disable('registry')
        Services.enable('mattermost', 'registry', 'mailroom', except: 'registry')
        expect(node['mattermost']['enable']).to be true
        expect(node['registry']['enable']).to be false
        expect(node['gitlab']['mailroom']['enable']).to be true

        Services.enable('postgresql')
        Services.disable('redis', 'postgresql', 'gitaly', except: 'postgresql')
        expect(node['redis']['enable']).to be false
        expect(node['postgresql']['enable']).to be true
        expect(node['gitaly']['enable']).to be false
      end

      it 'supports multiple exceptions' do
        Services.disable('registry', 'mailroom')
        Services.enable('mattermost', 'registry', 'mailroom', except: %w(registry mailroom))
        expect(node['mattermost']['enable']).to be true
        expect(node['registry']['enable']).to be false
        expect(node['gitlab']['mailroom']['enable']).to be false

        Services.enable('postgresql', 'gitaly')
        Services.disable('redis', 'postgresql', 'gitaly', except: %w(postgresql gitaly))
        expect(node['redis']['enable']).to be false
        expect(node['postgresql']['enable']).to be true
        expect(node['gitaly']['enable']).to be true
      end

      it 'ignores disable on system services' do
        Services.disable('node_exporter')
        expect(node['monitoring']['node-exporter']['enable']).to be true
      end

      it 'allows forced disable on system services' do
        Services.disable('node_exporter', include_system: true)
        expect(node['monitoring']['node-exporter']['enable']).to be false
      end
    end

    context 'when passed single exception' do
      before { chef_run }

      it 'enables all others' do
        Services.disable('registry')
        Services.enable(Services::ALL_SERVICES, except: 'registry')
        expect(node['redis']['enable']).to be true
        expect(node['postgresql']['enable']).to be true
        expect(node['mattermost']['enable']).to be true
        expect(node['registry']['enable']).to be false
      end

      it 'disables all others' do
        Services.enable('redis')
        Services.disable(Services::ALL_SERVICES, except: 'redis')
        expect(node['redis']['enable']).to be true
        expect(node['postgresql']['enable']).to be false
        expect(node['mattermost']['enable']).to be false
        expect(node['registry']['enable']).to be false
      end
    end

    context 'when passed multiple exceptions' do
      before { chef_run }

      it 'enables all others' do
        Services.disable('registry', 'mailroom')
        Services.enable(Services::ALL_SERVICES, except: %w(registry mailroom))
        expect(node['redis']['enable']).to be true
        expect(node['postgresql']['enable']).to be true
        expect(node['gitaly']['enable']).to be true
        expect(node['mattermost']['enable']).to be true
        expect(node['gitlab']['mailroom']['enable']).to be false
        expect(node['registry']['enable']).to be false
      end

      it 'disables all others' do
        Services.enable('postgresql', 'gitaly')
        Services.disable(Services::ALL_SERVICES, except: %w(postgresql gitaly))
        expect(node['redis']['enable']).to be false
        expect(node['postgresql']['enable']).to be true
        expect(node['gitaly']['enable']).to be true
        expect(node['mattermost']['enable']).to be false
        expect(node['gitlab']['mailroom']['enable']).to be false
        expect(node['registry']['enable']).to be false
      end
    end
  end

  describe 'group' do
    let(:runner) { ChefSpec::SoloRunner.new }
    let(:chef_run) { runner.converge('gitlab::config') }
    let(:node) { runner.node }

    before { Services.add_services('gitlab', Services::BaseServices.list) }

    context 'when using user values that conflict with service settings' do
      cached!(:runner) { ChefSpec::SoloRunner.new { |node| Gitlab[:node] = node } }

      it 'node service settings are overridden by gitlab.rb changes' do
        stub_gitlab_rb(redis: { enable: true }, postgresql: { enable: false })
        Services.disable_group('redis')
        Services.enable_group('postgres')
        runner.converge('gitlab::config')

        expect(node['redis']['enable']).to be true
        expect(node['mattermost']['enable']).to be false
      end
    end

    context 'when enable_group/disable_group is passed a single group' do
      before { chef_run }

      it 'sets the correct values' do
        Services.disable_group('redis')
        expect(node['redis']['enable']).to be false
        expect(node['monitoring']['redis-exporter']['enable']).to be false

        Services.enable_group('rails')
        expect(node['gitlab']['puma']['enable']).to be true
        expect(node['monitoring']['gitlab-exporter']['enable']).to be true
      end

      it 'supports exceptions' do
        Services.disable_group('monitoring')
        Services.enable_group('rails', except: 'monitoring')
        expect(node['monitoring']['gitlab-exporter']['enable']).to be false
        expect(node['gitlab']['puma']['enable']).to be true

        Services.enable_group('monitoring')
        Services.disable_group('redis', except: 'monitoring')
        expect(node['redis']['enable']).to be false
        expect(node['monitoring']['redis-exporter']['enable']).to be true
      end
    end

    context 'when enable/disable is passed multiple groups' do
      before { chef_run }
      it 'sets the correct values' do
        Services.disable_group('redis', 'postgres')
        expect(node['redis']['enable']).to be false
        expect(node['postgresql']['enable']).to be false

        Services.enable_group('rails', 'monitoring')
        expect(node['monitoring']['redis-exporter']['enable']).to be true
        expect(node['gitlab']['puma']['enable']).to be true
      end

      it 'supports single exceptions' do
        Services.disable_group('monitoring')
        Services.enable_group('redis', 'rails', except: 'monitoring')
        expect(node['redis']['enable']).to be true
        expect(node['gitlab']['puma']['enable']).to be true
        expect(node['monitoring']['gitlab-exporter']['enable']).to be false
        expect(node['monitoring']['redis-exporter']['enable']).to be false

        Services.enable_group('postgres')
        Services.disable_group('redis', 'monitoring', except: 'postgres')
        expect(node['redis']['enable']).to be false
        expect(node['monitoring']['postgres-exporter']['enable']).to be true
        expect(node['monitoring']['prometheus']['enable']).to be false
      end

      it 'supports multiple exceptions' do
        Services.disable_group('redis', Services::SYSTEM_GROUP, include_system: true)
        Services.enable_group('rails', 'monitoring', except: ['redis', Services::SYSTEM_GROUP])
        expect(node['monitoring']['redis-exporter']['enable']).to be false
        expect(node['monitoring']['node-exporter']['enable']).to be false
        expect(node['gitlab']['puma']['enable']).to be true

        Services.enable_group('sidekiq', 'monitoring')
        Services.disable_group('rails', 'postgres', except: %w(sidekiq monitoring))
        expect(node['gitlab']['gitlab-workhorse']['enable']).to be false
        # The sidekiq group enables sidekiq-cluster by default
        expect(node['gitlab']['sidekiq-cluster']['enable']).to be true
        expect(node['postgresql']['enable']).to be false
        expect(node['monitoring']['postgres-exporter']['enable']).to be true
      end

      it 'ignores disable on system services' do
        Services.enable_group(Services::SYSTEM_GROUP)
        Services.disable_group(Services::SYSTEM_GROUP)
        expect(node['gitlab']['logrotate']['enable']).to be true
      end

      it 'allows forced disable on system services' do
        Services.enable_group(Services::SYSTEM_GROUP)
        Services.disable_group(Services::SYSTEM_GROUP, include_system: true)
        expect(node['gitlab']['logrotate']['enable']).to be false
      end
    end

    context 'when passed single exception' do
      before { chef_run }

      it 'enables all others' do
        Services.disable_group('monitoring')
        Services.enable_group(Services::ALL_GROUPS, except: 'monitoring')
        expect(node['gitlab']['puma']['enable']).to be true
        expect(node['monitoring']['gitlab-exporter']['enable']).to be false
      end

      it 'disables all others' do
        Services.enable_group('monitoring')
        Services.disable_group(Services::ALL_GROUPS, except: 'monitoring')
        expect(node['monitoring']['postgres-exporter']['enable']).to be true
        expect(node['postgresql']['enable']).to be false
      end
    end

    context 'when passed multiple exceptions' do
      before { chef_run }

      it 'enables all others' do
        Services.disable_group('redis', 'rails')
        Services.enable_group(Services::ALL_GROUPS, except: %w(redis rails))
        expect(node['gitlab']['puma']['enable']).to be false
        expect(node['monitoring']['node-exporter']['enable']).to be true
        expect(node['monitoring']['redis-exporter']['enable']).to be false
      end

      it 'disables all others' do
        Services.enable_group('redis', 'rails')
        Services.disable_group(Services::ALL_GROUPS, except: %w(redis rails))
        expect(node['monitoring']['prometheus']['enable']).to be false
        expect(node['redis']['enable']).to be true
        # Sidekiq enables sidekiq-cluster by default
        expect(node['gitlab']['sidekiq-cluster']['enable']).to be true
      end
    end
  end
end
