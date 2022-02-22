require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'extra settings' do
    context 'with default values' do
      it 'renders gitlab.yml without extra settings' do
        expect(gitlab_yml[:production][:extra]).to be nil
      end
    end

    context 'with user specified values' do
      describe 'matomo settings' do
        context 'with just matomo_url specified' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                extra_matomo_url: 'http://foobar.com'
              }
            )
          end

          it 'renders gitlab.yml with default values for other matomo settings' do
            expect(gitlab_yml[:production][:extra][:matomo_url]).to eq('http://foobar.com')
            expect(gitlab_yml[:production][:extra][:matomo_site_id]).to be nil
            expect(gitlab_yml[:production][:extra][:matomo_disable_cookies]).to be nil
          end
        end

        context 'with all settings specified' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                extra_matomo_url: 'http://foobar.com',
                extra_matomo_site_id: 'foobar',
                extra_matomo_disable_cookies: true
              }
            )
          end

          it 'renders gitlab.yml with specified matomo settings' do
            expect(gitlab_yml[:production][:extra][:matomo_url]).to eq('http://foobar.com')
            expect(gitlab_yml[:production][:extra][:matomo_site_id]).to eq('foobar')
            expect(gitlab_yml[:production][:extra][:matomo_disable_cookies]).to be true
          end
        end
      end

      describe 'one_trust_id setting' do
        before do
          stub_gitlab_rb(gitlab_rails: { extra_one_trust_id: '0000-0000-test' })
        end

        it 'renders gitlab.yml with the provided value' do
          expect(gitlab_yml[:production][:extra][:one_trust_id]).to eq('0000-0000-test')
        end
      end

      describe 'google_tag_manager_nonce_id setting' do
        before do
          stub_gitlab_rb(gitlab_rails: { extra_google_tag_manager_nonce_id: '0000-0000' })
        end

        it 'renders gitlab.yml with the provided value' do
          expect(gitlab_yml[:production][:extra][:google_tag_manager_nonce_id]).to eq('0000-0000')
        end
      end

      context 'bizible' do
        context 'when true' do
          before do
            stub_gitlab_rb(
              gitlab_rails: { bizible: true }
            )
          end

          it 'should set bizible to true' do
            expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
              hash_including(
                'bizible' => true
              )
            )
          end
        end
      end
    end
  end
end
