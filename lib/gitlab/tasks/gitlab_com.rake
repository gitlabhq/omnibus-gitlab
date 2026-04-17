require_relative '../build/check'
require_relative '../build/info/deploy'
require_relative '../build/info/package'
require_relative '../deployer_helper'
require_relative '../util'

namespace :gitlab_com do
  desc 'Tasks related to gitlab.com.'
  task :deployer do
    abort "This task requires DEPLOYER_TRIGGER_TOKEN to be set" unless Gitlab::Util.get_env('DEPLOYER_TRIGGER_TOKEN')

    unless Build::Info::Package.name == "gitlab-ee"
      puts "#{Build::Info::Package.name} is not an ee package, not doing anything."
      next
    end

    if Build::Check.is_auto_deploy?
      puts 'Auto-deploys are handled in release-tools, exiting...'
      next
    end

    deploy_env = Build::Info::Deploy.environment

    if deploy_env.nil?
      puts 'Unable to determine which environment to deploy to, exiting...'
      next
    elsif deploy_env == 'gprd'
      # We do not support auto-deployments or triggered deployments
      # directly to production from the omnibus pipeline, this check is here
      # for safety
      raise NotImplementedError, "Environment #{deploy_env} is not supported"
    end

    trigger_token = Gitlab::Util.get_env('DEPLOYER_TRIGGER_TOKEN')
    # DEPLOYER_TRIGGER_REF to be set to trigger pipelines against a reference
    # other than `master` in the deployer project
    trigger_ref = Gitlab::Util.get_env('DEPLOYER_TRIGGER_REF') || :master

    deployer_helper = DeployerHelper.new(trigger_token, deploy_env, trigger_ref)
    url = deployer_helper.trigger_deploy
    puts "Deployer build triggered at #{url} on #{trigger_ref} for the #{deploy_env} environment"
  end
end
