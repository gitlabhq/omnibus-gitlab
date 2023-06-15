require 'chef_helper'

RSpec.describe SuggestedReviewers do
  describe '.parse_secrets' do
    let(:chef_run) { converge_config(is_ee: true) }

    before do
      allow(SecretsHelper).to receive(:generate_hex).and_return('4ecd22c031fee5c7368a5a102f76dc41')
      allow(Gitlab).to receive(:[]).and_call_original
    end

    context 'by default' do
      it 'generates a secret' do
        node = chef_run.node

        expect(node['gitlab']['suggested_reviewers']['api_secret_key']).to eq('NGVjZDIyYzAzMWZlZTVjNzM2OGE1YTEwMmY3NmRjNDE=')
      end
    end

    context 'with user specified values' do
      context 'of sufficient length' do
        before do
          stub_gitlab_rb(
            suggested_reviewers: {
              api_secret_key: 'NTliMjc2ZDkxMTZhZGZiZGE4ZWEzODI3NTczODQ5ZjI='
            }
          )
        end

        it 'uses the specified value' do
          node = chef_run.node

          expect(node['gitlab']['suggested_reviewers']['api_secret_key']).to eq('NTliMjc2ZDkxMTZhZGZiZGE4ZWEzODI3NTczODQ5ZjI=')
        end
      end

      context 'of insufficient length' do
        before do
          stub_gitlab_rb(
            suggested_reviewers: {
              api_secret_key: 'MTIzNDU2'
            }
          )
        end

        it 'raises an error' do
          expect { chef_run }.to raise_error.with_message("suggested_reviewers['api_secret_key'] should be exactly 32 bytes")
        end
      end
    end
  end
end
