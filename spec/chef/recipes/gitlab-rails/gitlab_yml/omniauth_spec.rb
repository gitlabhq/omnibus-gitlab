require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax
  include_context 'gitlab-rails'

  describe 'omniauth settings' do
    context 'with default values' do
      it 'renders gitlab.yml with omniauth allow_single_sign_on set to saml' do
        expect(gitlab_yml[:production][:omniauth][:allow_single_sign_on]).to eq(['saml'])
      end

      it 'renders gitlab.yml with other omniauth settings set to nil' do
        expect(gitlab_yml[:production][:omniauth]).to eq(
          allow_bypass_two_factor: nil,
          auto_link_ldap_user: nil,
          auto_link_saml_user: nil,
          auto_link_user: nil,
          allow_single_sign_on: ['saml'],
          auto_sign_in_with_provider: nil,
          block_auto_created_users: nil,
          enabled: nil,
          external_providers: nil,
          providers: nil
        )
      end
    end

    context 'with user specified values' do
      describe 'saml_message_max_byte_size' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              omniauth_saml_message_max_byte_size: 100000
            }
          )
        end

        it 'renders gitlab.yml with custom value' do
          expect(gitlab_yml[:production][:omniauth][:saml_message_max_byte_size]).to eq(100000)
        end
      end

      describe 'settings that take in boolean values' do
        where(:gitlab_yml_setting, :gitlab_rb_setting) do
          'enabled'                  | 'omniauth_enabled'
          'block_auto_created_users' | 'omniauth_block_auto_created_users'
          'auto_link_ldap_user'      | 'omniauth_auto_link_ldap_user'
          'auto_link_saml_user'      | 'omniauth_auto_link_saml_user'
        end

        with_them do
          context "with #{params[:gitlab_rb_setting]} set to true" do
            before do
              stub_gitlab_rb(
                gitlab_rails: {
                  gitlab_rb_setting => true
                }.transform_keys(&:to_sym)
              )
            end

            it "renders gitlab.yml with #{params[:gitlab_yml_setting]} set to true" do
              expect(gitlab_yml[:production][:omniauth][gitlab_yml_setting.to_sym]).to be true
            end
          end
        end
      end

      describe 'settings that take in multiple types of values' do
        where(:gitlab_yml_setting, :gitlab_rb_setting) do
          'allow_single_sign_on'       | 'omniauth_allow_single_sign_on'
          'sync_email_from_provider'   | 'omniauth_sync_email_from_provider'
          'sync_profile_from_provider' | 'omniauth_sync_profile_from_provider'
          'allow_bypass_two_factor'    | 'omniauth_allow_bypass_two_factor'
          'sync_profile_attributes'    | 'omniauth_sync_profile_attributes'
          'auto_link_user'             | 'omniauth_auto_link_user'
        end

        with_them do
          # Testing scenarios where settings are set to boolean true, string,
          # and array of strings.
          [true, 'foo', ['bar', 'tar']].each do |value|
            context "with #{params[:gitlab_rb_setting]} set to #{value}" do
              before(:each) do
                stub_gitlab_rb(
                  gitlab_rails: {
                    gitlab_rb_setting => value
                  }.transform_keys(&:to_sym)
                )
              end

              it "renders gitlab.yml with #{params[:gitlab_yml_setting]} set to #{value}" do
                expect(gitlab_yml[:production][:omniauth][gitlab_yml_setting.to_sym]).to eq value
              end
            end
          end
        end
      end
    end
  end
end
