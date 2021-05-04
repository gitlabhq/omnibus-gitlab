require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'sidekiq settings' do
    describe 'log_format' do
      context 'with default values' do
        it 'renders gitlab.yml with sidekiq log format set to json' do
          expect(gitlab_yml[:production][:sidekiq][:log_format]).to eq('json')
        end
      end

      context 'with user specified value' do
        before do
          stub_gitlab_rb(
            sidekiq: {
              log_format: 'text'
            }
          )
        end

        it 'renders gitlab.yml with user specified value for sidekiq log format' do
          expect(gitlab_yml[:production][:sidekiq][:log_format]).to eq('text')
        end
      end
    end
  end
end
