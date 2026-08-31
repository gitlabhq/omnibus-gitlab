require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'Mobile push settings' do
    context 'with default configuration' do
      it 'renders gitlab.yml with mobile push unconfigured' do
        expect(gitlab_yml[:production][:mobile_push]).to eq(
          apns: {
            auth_key_path: nil,
            key_id: nil,
            team_id: nil,
            topic: nil
          }
        )
      end
    end

    context 'with user specified configuration' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            mobile_push_apns_auth_key_path: '/etc/gitlab/mobile_push_apns_auth_key.p8',
            mobile_push_apns_key_id: 'ABC123DEFG',
            mobile_push_apns_team_id: 'DEF456GHIJ',
            mobile_push_apns_topic: 'com.example.app'
          }
        )
      end

      it 'renders gitlab.yml with user specified values for mobile push' do
        expect(gitlab_yml[:production][:mobile_push]).to eq(
          apns: {
            auth_key_path: '/etc/gitlab/mobile_push_apns_auth_key.p8',
            key_id: 'ABC123DEFG',
            team_id: 'DEF456GHIJ',
            topic: 'com.example.app'
          }
        )
      end
    end

    context 'with an incomplete APNs configuration' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            mobile_push_apns_auth_key_path: '/etc/gitlab/mobile_push_apns_auth_key.p8'
          }
        )
      end

      it 'raises an error naming the missing settings' do
        expect { chef_run }.to raise_error(
          RuntimeError,
          /Missing: gitlab_rails\['mobile_push_apns_key_id'\], gitlab_rails\['mobile_push_apns_team_id'\]/
        )
      end
    end

    context 'with only the APNs topic set' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            mobile_push_apns_topic: 'com.example.app'
          }
        )
      end

      it 'raises an error requiring the auth key path, key id and team id' do
        expect { chef_run }.to raise_error(
          RuntimeError,
          /Missing: gitlab_rails\['mobile_push_apns_auth_key_path'\], gitlab_rails\['mobile_push_apns_key_id'\], gitlab_rails\['mobile_push_apns_team_id'\]/
        )
      end
    end

    context 'with a single required setting set to an empty string' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            mobile_push_apns_auth_key_path: '/etc/gitlab/mobile_push_apns_auth_key.p8',
            mobile_push_apns_key_id: '',
            mobile_push_apns_team_id: 'DEF456GHIJ'
          }
        )
      end

      it 'raises an error naming only that setting' do
        expect { chef_run }.to raise_error(
          RuntimeError,
          /Missing: gitlab_rails\['mobile_push_apns_key_id'\]\.$/
        )
      end
    end

    context 'with a whitespace-only required setting' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            mobile_push_apns_auth_key_path: '/etc/gitlab/mobile_push_apns_auth_key.p8',
            mobile_push_apns_key_id: '   ',
            mobile_push_apns_team_id: 'DEF456GHIJ'
          }
        )
      end

      it 'raises an error naming only that setting' do
        expect { chef_run }.to raise_error(
          RuntimeError,
          /Missing: gitlab_rails\['mobile_push_apns_key_id'\]\.$/
        )
      end
    end

    context 'with non-String values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            mobile_push_apns_auth_key_path: false,
            mobile_push_apns_key_id: 12345,
            mobile_push_apns_team_id: 'DEF456GHIJ'
          }
        )
      end

      it 'raises an error naming each non-String setting and its class' do
        expect { chef_run }.to raise_error(
          RuntimeError,
          /must be strings\. Not a string: gitlab_rails\['mobile_push_apns_auth_key_path'\] \(FalseClass\), gitlab_rails\['mobile_push_apns_key_id'\] \(Integer\)\.$/
        )
      end
    end

    context 'with a blank topic and padded values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            mobile_push_apns_auth_key_path: '/etc/gitlab/mobile_push_apns_auth_key.p8',
            mobile_push_apns_key_id: '  ABC123DEFG  ',
            mobile_push_apns_team_id: 'DEF456GHIJ',
            mobile_push_apns_topic: ''
          }
        )
      end

      it 'renders gitlab.yml with stripped values and a nil topic so the application default applies' do
        expect(gitlab_yml[:production][:mobile_push]).to eq(
          apns: {
            auth_key_path: '/etc/gitlab/mobile_push_apns_auth_key.p8',
            key_id: 'ABC123DEFG',
            team_id: 'DEF456GHIJ',
            topic: nil
          }
        )
      end
    end

    context 'with a complete APNs configuration' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            mobile_push_apns_auth_key_path: '/etc/gitlab/mobile_push_apns_auth_key.p8',
            mobile_push_apns_key_id: 'ABC123DEFG',
            mobile_push_apns_team_id: 'DEF456GHIJ'
          }
        )

        allow(LoggingHelper).to receive(:warning).and_call_original
        allow(File).to receive(:file?).and_call_original
      end

      it 'renders gitlab.yml with a nil topic so the application default applies' do
        expect(gitlab_yml[:production][:mobile_push]).to eq(
          apns: {
            auth_key_path: '/etc/gitlab/mobile_push_apns_auth_key.p8',
            key_id: 'ABC123DEFG',
            team_id: 'DEF456GHIJ',
            topic: nil
          }
        )
      end

      context 'when the auth key file does not exist' do
        before do
          allow(File).to receive(:file?).with('/etc/gitlab/mobile_push_apns_auth_key.p8').and_return(false)
        end

        it 'warns but does not fail' do
          expect(LoggingHelper).to receive(:warning).with(/no file exists at that path/)

          chef_run
        end
      end

      context 'when the auth key file exists' do
        before do
          allow(File).to receive(:file?).with('/etc/gitlab/mobile_push_apns_auth_key.p8').and_return(true)
        end

        it 'does not warn' do
          expect(LoggingHelper).not_to receive(:warning).with(/mobile_push_apns_auth_key_path/)

          chef_run
        end
      end

      context 'when the auth key path is a directory' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              mobile_push_apns_auth_key_path: '/tmp',
              mobile_push_apns_key_id: 'ABC123DEFG',
              mobile_push_apns_team_id: 'DEF456GHIJ'
            }
          )
        end

        it 'warns that no file exists at that path' do
          expect(LoggingHelper).to receive(:warning).with(/no file exists at that path/)

          chef_run
        end
      end
    end
  end
end
