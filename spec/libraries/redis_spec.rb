require 'chef_helper'

describe 'Redis' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:node) { chef_run.node }
  subject { ::Redis }
  before do
    allow(Gitlab).to receive(:[]).and_call_original
    mock_file_load(%r{gitlab/libraries/helper})
  end

  context '.parse_variables' do
    it 'delegates to parse_redis_settings' do
      expect(subject).to receive(:parse_redis_settings)

      subject.parse_variables
    end
  end

  context '.parse_redis_settings' do
    context 'when no customization is made' do
      it 'keeps unixsocket' do
        expect(Gitlab['gitlab_rails']['unixsocket']).not_to eq false

        subject.parse_redis_settings
      end
    end

    context 'within redis host and port synchronization with gitlab_rails' do
      let(:redis_host) { '0.0.0.0' }
      let(:redis_port) { 6379 }

      before do
        stub_gitlab_rb(
          redis: {
            bind: redis_host,
            port: redis_port
          }
        )
        node
      end

      it 'disables unix socket when redis tcp params are defined' do
        expect(Gitlab['redis']['unixsocket']).to eq false

        subject.parse_redis_settings
      end

      it 'expects redis_host to match bind value from redis' do
        expect(Gitlab['gitlab_rails']['redis_host']).to eq redis_host

        subject.parse_redis_settings
      end

      it 'expects redis_port to match port value from redis' do
        expect(Gitlab['gitlab_rails']['redis_port']).to eq redis_port

        subject.parse_redis_settings
      end
    end

    context 'within gitlab-rails redis values' do
      let(:redis_host) { '0.0.0.0' }

      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: redis_host
          }
        )
        node
      end

      it 'disables unix socket when gitlab-rails tcp params are defined' do
        expect(Gitlab['gitlab_rails']['redis_socket']).to eq false
      end

      it 'defaults port to 6379' do
        expect(Gitlab['gitlab_rails']['redis_port']).to eq 6379
      end
    end
  end
end
