require 'chef_helper'

RSpec.shared_context 'gitlab-rails' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: 'templatesymlink').converge('gitlab::default') }
  let(:gitlab_yml_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/gitlab.yml') }
  let(:gitlab_yml_file_content) { ChefSpec::Renderer.new(chef_run, gitlab_yml_template).content }
  let(:gitlab_yml) { YAML.safe_load(gitlab_yml_file_content, [], [], true, symbolize_names: true) }
  let(:config_dir) { '/var/opt/gitlab/gitlab-rails/etc/' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(File).to receive(:symlink?).and_call_original
  end
end
