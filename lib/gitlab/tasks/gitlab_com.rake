require_relative '../deployer_helper.rb'
require_relative "../util.rb"

namespace :gitlab_com do
  desc 'Tasks related to gitlab.com.'
  task :deployer do
    %w[DEPLOYER_TRIGGER_TOKEN DEPLOYER_ENVIRONMENT].each do |env_var|
      abort "This task requires #{env_var} to be set" unless ENV[env_var]
    end

    unless Build::Info.package == "gitlab-ee"
      puts "#{Build::Info.package} is not an ee package, not doing anything."
      exit
    end

    if !Build::Check.is_auto_deploy? && !Build::Check.is_latest_tag?
      puts "Running on tag #{Build::Info.current_git_tag} which is not the latest tag: #{Build::Info.latest_tag}."
      exit
    end

    trigger_token = Gitlab::Util.get_env('DEPLOYER_TRIGGER_TOKEN')
    trigger_ref = Build::Check.is_auto_deploy? && Build::Check.ci_commit_tag? ? Gitlab::Util.get_env('CI_COMMIT_TAG') : :master
    deploy_env = Gitlab::Util.get_env('DEPLOYER_ENVIRONMENT')

    # We do not support auto-deployments or triggered deployments
    # directly to production from the omnibus pipeline, this check is here
    # for safety
    raise NotImplementedError, "Environment #{deploy_env} is not supported" if deploy_env == 'gprd'

    deployer_helper = DeployerHelper.new(trigger_token, deploy_env, trigger_ref)
    url = deployer_helper.trigger_deploy
    puts "Deployer build triggered at #{url} on #{trigger_ref} for the #{deploy_env} environment"
  end
end
