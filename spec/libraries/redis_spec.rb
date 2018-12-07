# This spec is to test the Redis helper and whether the values parsed
# are the ones we expect
require 'chef_helper'

describe 'Redis' do
  let(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  subject { ::Redis }
  before do
    allow(Gitlab).to receive(:[]).and_call_original
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
        expect(node['gitlab']['gitlab-rails']['unixsocket']).not_to eq false

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
        end

        it 'disables unix socket when redis tcp params are defined' do
          expect(node['redis']['unixsocket']).to eq false

          subject.parse_redis_settings
        end

        it 'expects redis_host to match bind value from redis' do
          expect(node['gitlab']['gitlab-rails']['redis_host']).to eq redis_host

          subject.parse_redis_settings
        end

        it 'expects redis_port to match port value from redis' do
          expect(node['gitlab']['gitlab-rails']['redis_port']).to eq redis_port

          subject.parse_redis_settings
        end
      end

      context 'when using sentinels' do
        let(:master_name) { 'gitlabredis' }
        let(:master_pass) { 'PASSWORD' }

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
        end

        it 'disables unix socket when sentinel params are defined' do
          expect(node['redis']['unixsocket']).to eq false

          subject.parse_redis_settings
        end
      end

      context 'when with redis_slave_role enabled' do
        before do
          stub_gitlab_rb(
            redis_slave_role: {
              enable: true
            },
            redis: {
              master_ip: '10.0.0.0',
              master_port: 6379,
              master_password: 'PASSWORD'
            }
          )
        end

        it 'defined redis master as false' do
          expect(node['redis']['master']).to eq false
        end
      end
    end

    context 'within redis password and master_password' do
      let(:redis_password) { 'PASSWORD' }

      context 'when master_role is enabled' do
        before do
          stub_gitlab_rb(
            redis_master_role: {
              enable: true
            },
            redis: {
              password: redis_password,
              master_ip: '10.0.0.0'
            }
          )
        end

        it 'master_password is autofilled based on redis current password' do
          expect(node['redis']['master_password']).to eq redis_password
        end
      end

      context 'when redis is a slave' do
        before do
          stub_gitlab_rb(
            redis: {
              master: false,
              password: redis_password,
              master_ip: '10.0.0.0'
            }
          )
        end

        it 'master_password is autofilled based on redis current password' do
          expect(node['redis']['master_password']).to eq redis_password
        end
      end

      context 'when sentinel is enabled' do
        before do
          stub_gitlab_rb(
            sentinel: {
              enable: true
            },
            redis: {
              password: redis_password,
              master_ip: '10.0.0.0'
            }
          )
        end

        it 'master_password is autofilled based on redis current password' do
          expect(node['redis']['master_password']).to eq redis_password
        end

        context 'announce_ip is defined' do
          let(:redis_port) { 6379 }
          let(:redis_announce_ip) { '10.10.10.10' }
          before do
            stub_gitlab_rb(
              redis_sentinel_role: {
                enable: true,
              },
              redis: {
                master_password: redis_password,
                master_ip: '10.0.0.0',
                port: redis_port,
                announce_ip: redis_announce_ip
              }
            )
          end

          it 'Redis announce_port is autofilled based on redis current port' do
            expect(node['redis']['announce_port']).to eq redis_port

            subject.parse_redis_settings
          end
        end
      end

      context 'when both password and master_password are present' do
        let(:master_password) { 'anotherPASSWORD' }
        before do
          stub_gitlab_rb(
            redis_slave_role: {
              enable: true
            },
            redis: {
              password: redis_password,
              master_ip: '10.0.0.0',
              master_password: master_password
            }
          )
        end

        it 'keeps user specified master_password' do
          expect(node['redis']['master_password']).to eq master_password
        end
      end
    end
  end
end
