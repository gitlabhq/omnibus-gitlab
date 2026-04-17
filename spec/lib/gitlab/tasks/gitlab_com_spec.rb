require 'spec_helper'

RSpec.describe 'gitlab_com', type: :rake do
  before(:all) do
    Rake.application.rake_require 'gitlab/tasks/gitlab_com'
  end

  describe 'gitlab_com:deployer' do
    before do
      Rake::Task['gitlab_com:deployer'].reenable

      allow(ENV).to receive(:[]).and_call_original
      stub_env_var('PATCH_DEPLOY_ENVIRONMENT', 'patch-environment')
      allow(DeployerHelper).to receive(:new).and_return(double(trigger_deploy: 'dummy-url'))
    end

    context 'when DEPLOYER_TRIGGER_TOKEN is not set' do
      before do
        stub_env_var('DEPLOYER_TRIGGER_TOKEN', nil)
      end

      it 'prints warning' do
        expect { Rake::Task['gitlab_com:deployer'].invoke }.to raise_error(SystemExit, "This task requires DEPLOYER_TRIGGER_TOKEN to be set")
      end
    end

    context 'when DEPLOYER_TRIGGER_TOKEN is set' do
      before do
        stub_env_var('DEPLOYER_TRIGGER_TOKEN', 'dummy-token')
      end

      context 'when building Community Edition (CE)' do
        before do
          stub_is_ee(false)
        end

        it 'prints warning' do
          expect { Rake::Task['gitlab_com:deployer'].invoke }.to output(/gitlab-ce is not an ee package, not doing anything./).to_stdout
        end
      end

      context 'when building Enterprise Edition (EE)' do
        before do
          stub_is_ee(true)
        end

        context 'with the auto-deploy tag' do
          before do
            allow(Build::Check).to receive(:is_auto_deploy?).and_return(true)
          end

          it 'shows a warning' do
            expect { Rake::Task['gitlab_com:deployer'].invoke }.to output(/Auto-deploys are handled in release-tools, exiting.../).to_stdout
          end
        end

        context 'with a release candidate (RC) tag' do
          before do
            allow(Build::Check).to receive(:is_rc_tag?).and_return(true)
          end

          it 'triggers deployment to the patch environment' do
            expect(DeployerHelper).to receive(:new).with('dummy-token', 'patch-environment', :master)

            Rake::Task['gitlab_com:deployer'].invoke
          end
        end
      end
    end
  end
end
