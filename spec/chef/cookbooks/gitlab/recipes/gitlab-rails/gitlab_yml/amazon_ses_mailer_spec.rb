require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'Amazon SES Mailer settings' do
    context 'with default configuration' do
      it 'renders gitlab.yml with Amazon SES Mailer disabled' do
        expect(gitlab_yml[:production][:amazon_ses_mailer]).to eq(
          enabled: false,
          region: nil,
          role_arn: nil,
          access_key_id: nil,
          secret_access_key: nil
        )
      end
    end

    context 'with user specified configuration' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            amazon_ses_mailer_enabled: true,
            amazon_ses_mailer_region: 'us-east-1',
            amazon_ses_mailer_role_arn: 'arn:aws:iam::123456789012:role/ses-mailer',
            amazon_ses_mailer_access_key_id: 'YOUR-AWS-ACCESS-KEY-ID',
            amazon_ses_mailer_secret_access_key: 'YOUR-AWS-SECRET-ACCESS-KEY'
          }
        )
      end

      it 'renders gitlab.yml with user specified values for Amazon SES Mailer' do
        expect(gitlab_yml[:production][:amazon_ses_mailer]).to eq(
          enabled: true,
          region: 'us-east-1',
          role_arn: 'arn:aws:iam::123456789012:role/ses-mailer',
          access_key_id: 'YOUR-AWS-ACCESS-KEY-ID',
          secret_access_key: 'YOUR-AWS-SECRET-ACCESS-KEY'
        )
      end
    end
  end
end
