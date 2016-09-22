require 'chef_helper'

describe 'Redis' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:node) { chef_run.node }
  subject { ::Redis }
  before { allow(Gitlab).to receive(:[]).and_call_original }

  context '.parse_variables' do
    it 'delegates to parse_redis_settings' do
      expect(subject).to receive(:parse_redis_settings)

      subject.parse_variables
    end
  end

  context '.parse_redis_settings' do
    context 'when no customization is made' do
      before { Gitlab[:node] = node }

      it 'keeps unixsocket' do
        expect(Gitlab['gitlab_rails']['unixsocket']).not_to eq false

        subject.parse_redis_settings
      end
    end

    context 'within redis host and port synchronization with gitlab_rails' do
      let(:redis_host) { '1.2.3.4' }
      let(:redis_port) { 6370 }

      context 'when not using sentinels' do
        before do
          stub_gitlab_rb(
            redis: {
              bind: redis_host,
              port: redis_port
            }
          )
          Gitlab[:node] = node
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

      context 'when using sentinels' do
        let(:master_name) { 'gitlabredis' }
        let(:master_pass) { 'hugepasswordhere' }
        before do
          stub_gitlab_rb(
            redis: {
              bind: redis_host,
              port: redis_port,
              master_name: master_name,
              master_password: master_pass
            },
            gitlab_rails: {
              redis_sentinels: [
                { host: '1.2.3.4', port: '26379' }
              ]
            }
          )
          Gitlab[:node] = node
        end

        it 'disables unix socket when sentinel params are defined' do
          expect(Gitlab['redis']['unixsocket']).to eq false

          subject.parse_redis_settings
        end

        it 'expects redis_host to match bind value from redis' do
          expect(Gitlab['gitlab_rails']['redis_host']).to eq master_name

          subject.parse_redis_settings
        end

        it 'expects redis_port to match default port value from redis' do
          expect(Gitlab['gitlab_rails']['redis_port']).to eq 6379

          subject.parse_redis_settings
        end

        it 'expects redis_password to match master_password value from redis' do
          expect(Gitlab['gitlab_rails']['redis_password']).to eq master_pass
        end
      end
    end

    context 'within gitlab-rails redis values' do
      let(:redis_host) { '1.2.3.4' }

      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: redis_host
          }
        )
        Gitlab[:node] = node
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
