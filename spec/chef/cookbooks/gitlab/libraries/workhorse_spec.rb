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
        expect(node['gitlab']['gitlab-workhorse']['listen_addr']).to eq(tcp_listen_address)
      end

      it 'keeps the sockets_directory as nil' do
        expect(node['gitlab']['gitlab-workhorse']['sockets_directory']).to eq(nil)
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
          expect(node['gitlab']['gitlab-workhorse']['sockets_directory']).to eq(default_sockets_directory)
        end

        it 'uses the default socket file path' do
          expect(node['gitlab']['gitlab-workhorse']['listen_addr']).to eq(default_socket)
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
          expect(node['gitlab']['gitlab-workhorse']['listen_addr']).to eq(user_socket)
        end

        it 'keeps the sockets_directory as nil' do
          expect(node['gitlab']['gitlab-workhorse']['sockets_directory']).to eq(nil)
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
          expect(node['gitlab']['gitlab-workhorse']['sockets_directory']).to eq(user_sockets_directory)
        end

        it 'creates a socket named socket in the user configured sockets directory' do
          expect(node['gitlab']['gitlab-workhorse']['listen_addr']).to eq("#{user_sockets_directory}/socket")
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
          expect(node['gitlab']['gitlab-workhorse']['sockets_directory']).to eq(user_sockets_directory)
        end

        it 'creates a socket matching the configured listen_addr' do
          expect(node['gitlab']['gitlab-workhorse']['listen_addr']).to eq(user_socket)
        end
      end
    end
  end
end
