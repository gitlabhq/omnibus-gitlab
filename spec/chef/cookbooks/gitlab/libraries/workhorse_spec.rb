# This spec is to test the Workhorse library and whether the values parsed
# are the ones we expect
require 'chef_helper'

RSpec.describe 'GitlabWorkhorse' do
  let(:node) { chef_run.node }
  let(:user_socket) { '/where/is/my/ten/mm/socket_now' }
  let(:user_sockets_directory) { '/where/is/my/ten/mm/sockets' }
  let(:default_sockets_directory) { '/var/opt/gitlab/gitlab-workhorse/sockets' }
  let(:default_socket) { '/var/opt/gitlab/gitlab-workhorse/sockets/socket' }
  let(:tcp_listen_address) { '1.9.8.4' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context '.parse_variables' do
    context 'listening on a tcp socket' do
      let(:chef_run) { converge_config }

      before do
        stub_gitlab_rb(
          gitlab_workhorse: {
            listen_network: 'http',
            listen_addr: tcp_listen_address
          }
        )
      end

      it 'uses the user configured TCP listen address' do
        expect(node['gitlab']['gitlab_workhorse']['listen_addr']).to eq(tcp_listen_address)
      end

      it 'keeps the sockets_directory as nil' do
        expect(node['gitlab']['gitlab_workhorse']['sockets_directory']).to eq(nil)
      end
    end

    context 'listening on a unix socket' do
      context 'using default configuration' do
        let(:chef_run) { converge_config }

        before do
          stub_gitlab_rb(
            gitlab_workhorse: {
              listen_network: 'unix'
            }
          )
        end

        it 'uses the default sockets directory' do
          expect(node['gitlab']['gitlab_workhorse']['sockets_directory']).to eq(default_sockets_directory)
        end

        it 'uses the default socket file path' do
          expect(node['gitlab']['gitlab_workhorse']['listen_addr']).to eq(default_socket)
        end
      end

      context 'only listen_addr is set' do
        let(:chef_run) { converge_config }

        before do
          stub_gitlab_rb(
            gitlab_workhorse: {
              listen_network: 'unix',
              listen_addr: user_socket
            }
          )
        end

        it 'uses the user configured listen address' do
          expect(node['gitlab']['gitlab_workhorse']['listen_addr']).to eq(user_socket)
        end

        it 'keeps the sockets_directory as nil' do
          expect(node['gitlab']['gitlab_workhorse']['sockets_directory']).to eq(nil)
        end
      end

      context 'only sockets_directory is set' do
        let(:chef_run) { converge_config }

        before do
          stub_gitlab_rb(
            gitlab_workhorse: {
              listen_network: 'unix',
              sockets_directory: user_sockets_directory
            }
          )
        end

        it 'uses the user configured sockets directory' do
          expect(node['gitlab']['gitlab_workhorse']['sockets_directory']).to eq(user_sockets_directory)
        end

        it 'creates a socket named socket in the user configured sockets directory' do
          expect(node['gitlab']['gitlab_workhorse']['listen_addr']).to eq("#{user_sockets_directory}/socket")
        end
      end

      context 'listen_addr and sockets_directory are both set' do
        let(:chef_run) { converge_config }

        before do
          stub_gitlab_rb(
            gitlab_workhorse: {
              listen_network: 'unix',
              listen_addr: user_socket,
              sockets_directory: user_sockets_directory
            }
          )
        end

        it 'uses the user configured sockets directory' do
          expect(node['gitlab']['gitlab_workhorse']['sockets_directory']).to eq(user_sockets_directory)
        end

        it 'creates a socket matching the configured listen_addr' do
          expect(node['gitlab']['gitlab_workhorse']['listen_addr']).to eq(user_socket)
        end
      end
    end
  end

  context '.parse_redis_settings' do
    context 'when global redis_sentinels_ssl is set' do
      let(:chef_run) { converge_config }

      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_sentinels_ssl: true
          },
          gitlab_workhorse: {
            listen_network: 'unix'
          }
        )
      end

      it 'populates redis_workhorse_sentinels_ssl from global setting' do
        expect(node['gitlab']['gitlab_rails']['redis_workhorse_sentinels_ssl']).to eq(true)
      end
    end

    context 'when instance-specific redis_workhorse_sentinels_ssl is set' do
      let(:chef_run) { converge_config }

      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_sentinels_ssl: false,
            redis_workhorse_sentinels_ssl: true
          },
          gitlab_workhorse: {
            listen_network: 'unix'
          }
        )
      end

      it 'keeps the instance-specific setting' do
        expect(node['gitlab']['gitlab_rails']['redis_workhorse_sentinels_ssl']).to eq(true)
      end
    end

    shared_examples 'propagates sentinel TLS certificate from global setting' do |attr, path|
      let(:chef_run) { converge_config }

      before do
        stub_gitlab_rb(
          gitlab_rails: {
            attr => path
          },
          gitlab_workhorse: {
            listen_network: 'unix'
          }
        )
      end

      it "populates gitlab_workhorse #{attr} from global setting" do
        expect(node['gitlab']['gitlab_workhorse'][attr]).to eq(path)
      end
    end

    it_behaves_like 'propagates sentinel TLS certificate from global setting',
                    :redis_sentinels_tls_ca_cert_file, '/etc/gitlab/ssl/ca.crt'
    it_behaves_like 'propagates sentinel TLS certificate from global setting',
                    :redis_sentinels_tls_client_cert_file, '/etc/gitlab/ssl/client.crt'
    it_behaves_like 'propagates sentinel TLS certificate from global setting',
                    :redis_sentinels_tls_client_key_file, '/etc/gitlab/ssl/client.key'

    context 'when instance-specific redis_sentinel_tls_ca_cert_file is set' do
      let(:chef_run) { converge_config }

      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_sentinels_tls_ca_cert_file: '/etc/gitlab/ssl/ca.crt'
          },
          gitlab_workhorse: {
            listen_network: 'unix',
            redis_sentinels_tls_ca_cert_file: '/etc/gitlab/ssl/custom-ca.crt'
          }
        )
      end

      it 'keeps the instance-specific setting' do
        expect(node['gitlab']['gitlab_workhorse']['redis_sentinels_tls_ca_cert_file']).to eq('/etc/gitlab/ssl/custom-ca.crt')
      end
    end

    shared_examples 'sets redis TLS certificate on workhorse' do |attr, path|
      let(:chef_run) { converge_config }

      before do
        stub_gitlab_rb(
          gitlab_workhorse: {
            listen_network: 'unix',
            attr => path
          }
        )
      end

      it "sets #{attr}" do
        expect(node['gitlab']['gitlab_workhorse'][attr]).to eq(path)
      end
    end

    it_behaves_like 'sets redis TLS certificate on workhorse',
                    :redis_tls_ca_cert_file, '/etc/gitlab/ssl/redis-ca.crt'
    it_behaves_like 'sets redis TLS certificate on workhorse',
                    :redis_tls_client_cert_file, '/etc/gitlab/ssl/redis-client.crt'
    it_behaves_like 'sets redis TLS certificate on workhorse',
                    :redis_tls_client_key_file, '/etc/gitlab/ssl/redis-client.key'

    shared_examples 'propagates redis TLS certificate from global setting' do |attr, path|
      let(:chef_run) { converge_config }

      before do
        stub_gitlab_rb(
          gitlab_rails: {
            attr => path
          },
          gitlab_workhorse: {
            listen_network: 'unix'
          }
        )
      end

      it "populates gitlab_workhorse #{attr} from global setting" do
        expect(node['gitlab']['gitlab_workhorse'][attr]).to eq(path)
      end
    end

    it_behaves_like 'propagates redis TLS certificate from global setting',
                    :redis_tls_ca_cert_file, '/etc/gitlab/ssl/redis-bundle.crt'
    it_behaves_like 'propagates redis TLS certificate from global setting',
                    :redis_tls_client_cert_file, '/etc/gitlab/ssl/redis-client.crt'
    it_behaves_like 'propagates redis TLS certificate from global setting',
                    :redis_tls_client_key_file, '/etc/gitlab/ssl/redis-client.key'

    context 'when instance-specific redis_tls_ca_cert_file is set' do
      let(:chef_run) { converge_config }

      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_tls_ca_cert_file: '/etc/gitlab/ssl/redis-bundle.crt'
          },
          gitlab_workhorse: {
            listen_network: 'unix',
            redis_tls_ca_cert_file: '/etc/gitlab/ssl/custom-redis-ca.crt'
          }
        )
      end

      it 'keeps the instance-specific setting' do
        expect(node['gitlab']['gitlab_workhorse']['redis_tls_ca_cert_file']).to eq('/etc/gitlab/ssl/custom-redis-ca.crt')
      end
    end
  end
end
