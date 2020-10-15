require 'chef_helper'

RSpec.describe GitlabWorkhorseHelper do
  let(:node) { chef_run.node }
  subject { described_class.new(node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'workhorse is listening on a tcp socket' do
    cached(:chef_run) { converge_config }
    let(:tcp_address) { '10.0.1.42' }

    before do
      stub_gitlab_rb(
        gitlab_workhorse: {
          listen_network: 'http',
          listen_addr: tcp_address
        }
      )
    end

    describe '#unix_socket?' do
      it 'returns false' do
        expect(subject.unix_socket?).to be false
      end
    end
  end

  context 'workhorse is listening on a unix socket' do
    let(:new_directory) { '/var/opt/gitlab/gitlab-workhorse/sockets' }
    let(:deprecated_custom) { '/where/is/my/ten/mm/socket' }
    let(:new_custom_directory) { '/where/is/my/ten/mm/sockets' }

    context 'with default workhorse configuration' do
      cached(:chef_run) { converge_config }
      before do
        stub_gitlab_rb(
          gitlab_workhorse: {
            listen_network: 'unix'
          }
        )
      end

      describe '#sockets_directory' do
        it 'returns the default directory path' do
          expect(subject.sockets_directory).to eq(new_directory)
        end
      end

      describe '#unix_socket?' do
        it 'returns true' do
          expect(subject.unix_socket?).to be true
        end
      end
    end

    context 'with custom workhorse listen_addr' do
      context 'without sockets_directory configured' do
        cached(:chef_run) { converge_config }

        before do
          stub_gitlab_rb(
            gitlab_workhorse: {
              listen_network: 'unix',
              listen_addr: deprecated_custom
            }
          )
        end

        describe '#user_customized_socket?' do
          it 'should be true when listen_addr is set' do
            expect(subject.user_customized_socket?).to be true
          end
        end
      end

      context 'with sockets_directory configured' do
        cached(:chef_run) { converge_config }

        before do
          stub_gitlab_rb(
            gitlab_workhorse: {
              listen_network: 'unix',
              listen_addr: deprecated_custom,
              sockets_directory: new_custom_directory
            }
          )
        end

        describe '#sockets_directory' do
          it 'returns the user configured sockets directory path' do
            expect(subject.sockets_directory).to eq(new_custom_directory)
          end
        end
      end
    end
  end
end
