require 'chef_helper'

# NOTE: These specs do not verify whether the code actually ran
# Nor whether the resource inside of the recipe was notified correctly.
# At this moment they only verify whether the expected commands are passed
# to the bash block.
#

describe 'gitlab::database-migrations' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when migration should run' do
    let(:bash_block) { chef_run.bash('migrate gitlab-rails database') }

    context 'places the log file' do
      # Testing only path as escaping the file name "$(date +%s)-$$.log"
      # is causing issues with chefspec.

      it 'in a default location' do
        path = %Q(/var/log/gitlab/gitlab-rails/gitlab-rails-db-migrate-)
        expect(bash_block.code).to match(/#{path}/)
      end

      it 'in a custom location' do
        stub_gitlab_rb(gitlab_rails: { log_directory: "/tmp"})
        path = %Q(/tmp/gitlab-rails-db-migrate-)
        expect(bash_block.code).to match(/#{path}/)
      end
    end

    it 'triggers the gitlab:db:configure task' do
      migrate = %Q(/opt/gitlab/bin/gitlab-rake gitlab:db:configure 2>& 1 | tee ${log_file})
      expect(bash_block.code).to match(/#{migrate}/)
    end
  end
end
