require 'chef_helper'

describe Services do
  before { allow(Gitlab).to receive(:[]).and_call_original }

  describe 'when using the gitlab cookbook' do
    cached(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

    it 'returns the gitlab service list' do
      chef_run
      expect(Services.service_list).to have_key('gitlab_rails')
      expect(Services.service_list).not_to have_key('sentinel')
    end
  end

  describe 'when using the gitlab-ee cookbook' do
    cached(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }

    it 'returns the gitlab service list including gitlab-ee items' do
      chef_run
      expect(Services.service_list).to have_key('gitlab_rails')
      expect(Services.service_list).to have_key('sentinel')
    end
  end

  it 'uses the default template when populating service information' do
    expect(Services::Config.send(:service, ['test_service'])).to eq({ groups: [] })
  end

  describe 'service' do
    context 'when enable/disable is passed a single service' do
      before do
        Services.add_services('gitlab', Services::BaseServices.list)
        stub_gitlab_rb(redis: { enable: true }, mattermost: { enable: false })
      end

      it 'sets the correct values' do
        Services.disable('redis')
        expect(Gitlab['redis']['enable']).to be false

        Services.enable('mattermost')
        expect(Gitlab['mattermost']['enable']).to be true
      end

      it 'supports exceptions' do
        Services.enable('mattermost', except: 'mattermost')
        expect(Gitlab['mattermost']['enable']).to be false

        Services.disable('redis', except: 'redis')
        expect(Gitlab['redis']['enable']).to be true
      end
    end

    context 'when enable/disable is passed multiple services' do
      before do
        Services.add_services('gitlab', Services::BaseServices.list)
        stub_gitlab_rb(
          node_exporter: { enable: true },
          redis: { enable: true },
          postgresql: { enable: true },
          gitaly: { enable: true },
          mattermost: { enable: false },
          registry: { enable: false },
          mailroom: { enable: false }
        )
      end

      it 'sets the correct values' do
        Services.disable('redis', 'postgresql', 'gitaly')
        expect(Gitlab['redis']['enable']).to be false
        expect(Gitlab['postgresql']['enable']).to be false
        expect(Gitlab['gitaly']['enable']).to be false

        Services.enable('mattermost', 'registry', 'mailroom')
        expect(Gitlab['mattermost']['enable']).to be true
        expect(Gitlab['registry']['enable']).to be true
        expect(Gitlab['mailroom']['enable']).to be true
      end

      it 'supports single exceptions' do
        Services.enable('mattermost', 'registry', 'mailroom', except: 'registry')
        expect(Gitlab['mattermost']['enable']).to be true
        expect(Gitlab['registry']['enable']).to be false
        expect(Gitlab['mailroom']['enable']).to be true

        Services.disable('redis', 'postgresql', 'gitaly', except: 'postgresql')
        expect(Gitlab['redis']['enable']).to be false
        expect(Gitlab['postgresql']['enable']).to be true
        expect(Gitlab['gitaly']['enable']).to be false
      end

      it 'supports multiple exceptions' do
        Services.enable('mattermost', 'registry', 'mailroom', except: %w(registry mailroom))
        expect(Gitlab['mattermost']['enable']).to be true
        expect(Gitlab['registry']['enable']).to be false
        expect(Gitlab['mailroom']['enable']).to be false

        Services.disable('redis', 'postgresql', 'gitaly', except: %w(postgresql gitaly))
        expect(Gitlab['redis']['enable']).to be false
        expect(Gitlab['postgresql']['enable']).to be true
        expect(Gitlab['gitaly']['enable']).to be true
      end

      it 'ignores disable on system services' do
        Services.disable('node_exporter')
        expect(Gitlab['node_exporter']['enable']).to be true
      end

      it 'allows forced disable on system services' do
        Services.disable('node_exporter', include_system: true)
        expect(Gitlab['node_exporter']['enable']).to be false
      end
    end

    context 'when passed single exception' do
      before do
        Services.add_services('gitlab', Services::BaseServices.list)
        stub_gitlab_rb(
          redis: { enable: true },
          postgresql: { enable: true },
          mattermost: { enable: false },
          registry: { enable: false }
        )
      end

      it 'enables all others' do
        Services.enable(except: 'registry')
        expect(Gitlab['redis']['enable']).to be true
        expect(Gitlab['postgresql']['enable']).to be true
        expect(Gitlab['mattermost']['enable']).to be true
        expect(Gitlab['registry']['enable']).to be false
      end

      it 'disables all others' do
        Services.disable(except: 'redis')
        expect(Gitlab['redis']['enable']).to be true
        expect(Gitlab['postgresql']['enable']).to be false
        expect(Gitlab['mattermost']['enable']).to be false
        expect(Gitlab['registry']['enable']).to be false
      end
    end

    context 'when passed multiple exceptions' do
      before do
        Services.add_services('gitlab', Services::BaseServices.list)
        stub_gitlab_rb(
          redis: { enable: true },
          postgresql: { enable: true },
          gitaly: { enable: true },
          mattermost: { enable: false },
          registry: { enable: false },
          mailroom: { enable: false }
        )
      end

      it 'enables all others' do
        Services.enable(except: %w(registry mailroom))
        expect(Gitlab['redis']['enable']).to be true
        expect(Gitlab['postgresql']['enable']).to be true
        expect(Gitlab['gitaly']['enable']).to be true
        expect(Gitlab['mattermost']['enable']).to be true
        expect(Gitlab['mailroom']['enable']).to be false
        expect(Gitlab['registry']['enable']).to be false
      end

      it 'disables all others' do
        Services.disable(except: %w(postgresql gitaly))
        expect(Gitlab['redis']['enable']).to be false
        expect(Gitlab['postgresql']['enable']).to be true
        expect(Gitlab['gitaly']['enable']).to be true
        expect(Gitlab['mattermost']['enable']).to be false
        expect(Gitlab['mailroom']['enable']).to be false
        expect(Gitlab['registry']['enable']).to be false
      end
    end
  end

  describe 'group' do
    context 'when enable_group/disable_group is passed a single group' do
      before do
        Services.add_services('gitlab', Services::BaseServices.list)
        stub_gitlab_rb(
          redis: { enable: true },
          redis_exporter: { enable: true },
          gitlab_monitor: { enable: false },
          unicorn: { enable: false }
        )
      end

      it 'sets the correct values' do
        Services.disable_group('redis')
        expect(Gitlab['redis']['enable']).to be false
        expect(Gitlab['redis_exporter']['enable']).to be false

        Services.enable_group('rails')
        expect(Gitlab['unicorn']['enable']).to be true
        expect(Gitlab['gitlab_monitor']['enable']).to be true
      end

      it 'supports exceptions' do
        Services.enable_group('rails', except: 'prometheus')
        expect(Gitlab['gitlab_monitor']['enable']).to be false
        expect(Gitlab['unicorn']['enable']).to be true

        Services.disable_group('redis', except: 'prometheus')
        expect(Gitlab['redis']['enable']).to be false
        expect(Gitlab['redis_exporter']['enable']).to be true
      end
    end

    context 'when enable/disable is passed multiple groups' do
      before do
        Services.add_services('gitlab', Services::BaseServices.list)
        stub_gitlab_rb(
          redis: { enable: true },
          redis_exporter: { enable: false },
          postgresql: { enable: true },
          postgres_exporter: { enable: true },
          sidekiq: { enable: true },
          gitlab_workhorse: { enable: true },
          gitlab_monitor: { enable: false },
          unicorn: { enable: false },
          prometheus: { enable: true },
          node_exporter: { enable: false },
          logrotate: { enable: true }
        )
      end

      it 'sets the correct values' do
        Services.disable_group('redis', 'postgres')
        expect(Gitlab['redis']['enable']).to be false
        expect(Gitlab['postgresql']['enable']).to be false

        Services.enable_group('rails', 'prometheus')
        expect(Gitlab['redis_exporter']['enable']).to be true
        expect(Gitlab['unicorn']['enable']).to be true
      end

      it 'supports single exceptions' do
        Services.enable_group('redis', 'rails', except: 'prometheus')
        expect(Gitlab['redis']['enable']).to be true
        expect(Gitlab['unicorn']['enable']).to be true
        expect(Gitlab['gitlab_monitor']['enable']).to be false
        expect(Gitlab['redis_exporter']['enable']).to be false

        Services.disable_group('redis', 'prometheus', except: 'postgres')
        expect(Gitlab['redis']['enable']).to be false
        expect(Gitlab['postgres_exporter']['enable']).to be true
        expect(Gitlab['prometheus']['enable']).to be false
      end

      it 'supports multiple exceptions' do
        Services.enable_group('rails', 'prometheus', except: ['redis', Services::Config::SYSTEM_GROUP])
        expect(Gitlab['redis_exporter']['enable']).to be false
        expect(Gitlab['node_exporter']['enable']).to be false
        expect(Gitlab['unicorn']['enable']).to be true

        Services.disable_group('rails', 'postgres', except: %w(sidekiq prometheus))
        expect(Gitlab['gitlab_workhorse']['enable']).to be false
        expect(Gitlab['sidekiq']['enable']).to be true
        expect(Gitlab['postgresql']['enable']).to be false
        expect(Gitlab['postgres_exporter']['enable']).to be true
      end

      it 'ignores disable on system services' do
        Services.disable_group(Services::Config::SYSTEM_GROUP)
        expect(Gitlab['logrotate']['enable']).to be true
      end

      it 'allows forced disable on system services' do
        Services.disable_group(Services::Config::SYSTEM_GROUP, include_system: true)
        expect(Gitlab['logrotate']['enable']).to be false
      end
    end

    context 'when passed single exception' do
      before do
        Services.add_services('gitlab', Services::BaseServices.list)
        stub_gitlab_rb(
          postgresql: { enable: true },
          postgres_exporter: { enable: true },
          gitlab_monitor: { enable: false },
          unicorn: { enable: false }
        )
      end

      it 'enables all others' do
        Services.enable_group(except: 'prometheus')
        expect(Gitlab['unicorn']['enable']).to be true
        expect(Gitlab['gitlab_monitor']['enable']).to be false
      end

      it 'disables all others' do
        Services.disable_group(except: 'prometheus')
        expect(Gitlab['postgres_exporter']['enable']).to be true
        expect(Gitlab['postgresql']['enable']).to be false
      end
    end

    context 'when passed multiple exceptions' do
      before do
        Services.add_services('gitlab', Services::BaseServices.list)
        stub_gitlab_rb(
          redis: { enable: true },
          redis_exporter: { enable: false },
          sidekiq: { enable: true },
          unicorn: { enable: false },
          prometheus: { enable: true },
          node_exporter: { enable: false }
        )
      end

      it 'enables all others' do
        Services.enable_group(except: %w(redis rails))
        expect(Gitlab['unicorn']['enable']).to be false
        expect(Gitlab['node_exporter']['enable']).to be true
        expect(Gitlab['redis_exporter']['enable']).to be false
      end

      it 'disables all others' do
        Services.disable_group(except: %w(redis rails))
        expect(Gitlab['prometheus']['enable']).to be false
        expect(Gitlab['redis']['enable']).to be true
        expect(Gitlab['sidekiq']['enable']).to be true
      end
    end
  end
end
