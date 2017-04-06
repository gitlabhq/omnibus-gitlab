require 'chef_helper'

# NOTE: These specs do not verify whether the code actually ran
# Nor whether the resource inside of the recipe was notified correctly.
# At this moment they only verify whether the expected commands are passed
# to the bash block.
#

describe 'gitlab-ee::geo-database-migrations' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }
  let(:name) { 'migrate gitlab-geo tracking database' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when migration should run' do
    before do
      allow_any_instance_of(OmnibusHelper).to receive(:not_listening?).and_return(false)
      stub_gitlab_rb(geo_postgresql: { enable: true })
    end

    let(:bash_block) { chef_run.bash(name) }

    it 'runs the migrations' do
      expect(chef_run).to run_bash(name)
    end

    context 'places the log file' do
      it 'in a default location' do
        path = Regexp.escape('/var/log/gitlab/gitlab-rails/gitlab-geo-db-migrate-$(date +%Y-%m-%d-%H-%M-%S).log')
        expect(bash_block.code).to match(/#{path}/)
      end

      it 'in a custom location' do
        stub_gitlab_rb(gitlab_rails: { log_directory: '/tmp' })

        path = '/tmp/gitlab-geo-db-migrate-'
        expect(bash_block.code).to match(/#{path}/)
      end
    end

    context 'with auto_migrate off' do
      before do
        stub_gitlab_rb(geo_secondary: { auto_migrate: false })
      end

      it 'skips running the migrations' do
        expect(chef_run).not_to run_bash(name)
      end
    end
  end
end
