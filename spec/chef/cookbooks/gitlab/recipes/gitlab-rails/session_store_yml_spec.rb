require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  describe 'Session store settings' do
    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: 'templatesymlink').converge('gitlab::default') }
    let(:session_store_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/session_store.yml') }
    let(:session_store_yml_file_content) { ChefSpec::Renderer.new(chef_run, session_store_yml_template).content }
    let(:session_store_yml) { YAML.safe_load(session_store_yml_file_content, aliases: true, symbolize_names: true) }

    before do
      allow(Gitlab).to receive(:[]).and_call_original
      allow(File).to receive(:symlink?).and_call_original
    end

    context 'with default settings' do
      it 'it renders the default settings' do
        expect(session_store_yml[:production]).to eq({ session_cookie_token_prefix: "" })
      end
    end

    context 'with custom session store configuration' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            session_store_session_cookie_token_prefix: 'custom_prefix_'
          }
        )
      end

      it 'renders session_store.yml using these settings' do
        expect(session_store_yml[:production]).to eq(
          {
            session_cookie_token_prefix: 'custom_prefix_'
          }
        )
      end
    end
  end
end
