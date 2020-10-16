require 'chef_helper'

RSpec.describe GitlabWorkhorseHelper do
  let(:node) { chef_run.node }
  subject { described_class.new(node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'workhorse is listening on a tcp socket' do
    cached(:chef_run) { converge_config }
    let(:tcp_address) { '1.9.8.4' }

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
    cached(:chef_run) { converge_config }
    before do
      stub_gitlab_rb(
        gitlab_workhorse: {
          listen_network: 'unix'
        }
      )
    end

    describe '#unix_socket?' do
      it 'returns true' do
        expect(subject.unix_socket?).to be true
      end
    end
  end
end
