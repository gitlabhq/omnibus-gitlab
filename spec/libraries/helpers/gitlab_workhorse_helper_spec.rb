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

    describe '#listen_address' do
      it 'returns the tcp listen address' do
        expect(subject.listen_address).to eq(tcp_address)
      end
    end
  end

  context 'workhorse is listening on a unix socket' do
    let(:socket_file_name) { 'socket' }
    let(:deprecated_path) { '/var/opt/gitlab/gitlab-workhorse/socket' }
    let(:new_directory) { '/var/opt/gitlab/gitlab-workhorse/sockets' }
    let(:new_path) { '/var/opt/gitlab/gitlab-workhorse/sockets/socket' }
    let(:deprecated_custom) { '/where/is/my/ten/mm/socket' }
    let(:new_custom_directory) { '/where/is/my/ten/mm/sockets' }
    let(:new_custom_path) { '/where/is/my/ten/mm/sockets/socket' }

    context 'with default workhorse configuration' do
      cached(:chef_run) { converge_config }
      before do
        stub_gitlab_rb(
          gitlab_workhorse: {
            listen_network: 'unix'
          }
        )
      end

      describe "#socket_file_name" do
        it 'returns only the socket file base name' do
          expect(subject.socket_file_name).to eq(socket_file_name)
        end
      end

      describe '#sockets_directory' do
        it 'returns the expected directory path' do
          expect(subject.sockets_directory).to eq(new_directory)
        end
      end

      describe '#unix_socket?' do
        it 'returns true' do
          expect(subject.unix_socket?).to be true
        end
      end

      describe '#deprecated_socket' do
        it 'returns the workhorse socket path not in a directory' do
          expect(subject.deprecated_socket).to eq(deprecated_path)
        end
      end

      describe '#orphan_socket' do
        it 'returns the deprecated path when using default configuration' do
          expect(subject.orphan_socket).to eq(deprecated_path)
        end
      end

      describe '#orphan_socket?' do
        it 'true when the orphan socket exists on disk' do
          allow(File).to receive(:exist?).with(deprecated_path).and_return(true)
          expect(subject.orphan_socket?).to be true
        end

        it 'false when the orphan socket does not exist on disk' do
          allow(File).to receive(:exist?).with(deprecated_path).and_return(true)
          expect(subject.orphan_socket?).to be true
        end
      end

      describe '#listen_address' do
        it 'returns the adjusted listen address' do
          expect(subject.listen_address).to eq(new_path)
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

        describe '#user_customized_sockets_directory?' do
          it 'should be false when the directory is default' do
            expect(subject.user_customized_sockets_directory?).to be false
          end
        end

        describe '#orphan_socket' do
          it 'returns the configured custom path' do
            expect(subject.orphan_socket).to eq(deprecated_custom)
          end
        end

        describe '#orphan_socket?' do
          it 'is false when the listen address is customized' do
            allow(File).to receive(:exist?).with(deprecated_custom).and_return(true)
            expect(subject.orphan_socket?).to be false
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

        describe "#user_customized_sockets_directory?" do
          it 'should be true when the directory has been set' do
            expect(subject.user_customized_sockets_directory?).to be true
          end
        end

        describe '#orphan_socket' do
          it 'returns the configured custom path' do
            expect(subject.orphan_socket).to eq(deprecated_custom)
          end
        end

        describe '#orphan_socket?' do
          it 'is true when the listen address is customized' do
            allow(File).to receive(:exist?).with(deprecated_custom).and_return(true)
            expect(subject.orphan_socket?).to be true
          end
        end

        describe '#listen_address' do
          it 'returns the path the custom directory' do
            expect(subject.listen_address).to eq(new_custom_path)
          end
        end
      end
    end
  end
end
