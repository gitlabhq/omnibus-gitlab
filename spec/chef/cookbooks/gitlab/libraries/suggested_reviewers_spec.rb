# This spec is to test the Redis helper and whether the values parsed
# are the ones we expect
require 'spec_helper'
require 'chef_helper'

RSpec.describe SuggestedReviewers do
  describe '.parse_secrets' do
    let(:some_hex) { '4ecd22c031fee5c7368a5a102f76dc41' }

    subject { described_class.parse_secrets }

    before do
      allow(Gitlab).to receive(:[]).and_return({ 'suggested_reviewers': [] })
      allow(SecretsHelper).to receive(:generate_hex).and_return(some_hex)
    end

    it 'raises no length error' do
      expect { subject }.not_to raise_error
    end

    context 'secret key length is wrong' do
      let(:some_hex) { '123456' }

      it 'raises no length error' do
        expect { subject }.to raise_error "suggested_reviewers['api_secret_key'] should be exactly 32 bytes"
      end
    end
  end
end
