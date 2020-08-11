require 'chef_helper'

# NOTE: We do not try to verify if we pass proper notifications to
# execute['clear the gitlab-rails cache'] resource that's done in other specs
# We just test if we use proper command and that we can change default
# attribute value with gilab.rb setting.

RSpec.describe 'gitlab::rails-cache-clear' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'test clear cache execution' do
    let(:clear_cache_exec) { chef_run.execute('clear the gitlab-rails cache') }
    let(:gilab_yml_temp) do
      chef_run.find_resource(:templatesymlink,
                             'Create a gitlab.yml and create a symlink to Rails root')
    end

    it 'check rake_cache_clear default attribute value set to true' do
      expect(chef_run.node['gitlab']['gitlab-rails']['rake_cache_clear'])
        .to be(true)
    end

    it 'check rake_cache_clear attribute value set to true' do
      stub_gitlab_rb(gitlab_rails: { rake_cache_clear: true })
      expect(chef_run.node['gitlab']['gitlab-rails']['rake_cache_clear'])
        .to be(true)
    end

    it 'check rake_cache_clear attribute value set to false' do
      stub_gitlab_rb(gitlab_rails: { rake_cache_clear: false })
      expect(chef_run.node['gitlab']['gitlab-rails']['rake_cache_clear'])
        .to be(false)
    end

    it 'check command used to clear cache' do
      expect(clear_cache_exec.command).to match(
        '/opt/gitlab/bin/gitlab-rake cache:clear')
      expect(clear_cache_exec).to do_nothing
    end
  end
end
