require 'chef_helper'

RSpec.describe MailroomHelper do
  cached(:chef_run) { converge_config }
  let(:node) { chef_run.node }
  subject { described_class.new(node) }

  before do
    allow(Gitlab).to receive(:[]).and_call_original

    stub_gitlab_rb(
      external_url: 'http://localhost/gitlab/'
    )
  end

  describe '#internal_api_url' do
    context 'when the workhorse internal api url uses http' do
      before do
        allow(WebServerHelper).to receive(:internal_api_url).with(node).and_return(
          ['http://internal-api-url', nil]
        )
      end

      it 'returns result from workhorse helper' do
        expect(subject.internal_api_url).to eql('http://internal-api-url')
      end
    end

    context 'when the workhorse internal api url uses a unix socket' do
      before do
        allow(WebServerHelper).to receive(:internal_api_url).with(node).and_return(
          ['http+unix:///path/to/socket/something.sock', nil]
        )
      end

      it 'returns external gitlab url' do
        expect(subject.internal_api_url).to eql('http://localhost/gitlab')
      end
    end
  end
end
