require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'shutdown settings' do
    context 'with default values' do
      it 'renders gitlab.yml with default value for blackout seconds' do
        expect(gitlab_yml[:production][:shutdown][:blackout_seconds]).to eq(10)
      end
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            shutdown_blackout_seconds: 30
          }
        )
      end

      it 'renders gitlab.yml with specified value for blackout seconds' do
        expect(gitlab_yml[:production][:shutdown][:blackout_seconds]).to eq(30)
      end
    end
  end
end
