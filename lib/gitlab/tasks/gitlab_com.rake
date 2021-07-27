require_relative '../deployer_helper.rb'
require_relative "../util.rb"

namespace :gitlab_com do
  desc 'Tasks related to gitlab.com.'
  task :deployer do
    abort "This task requires DEPLOYER_TRIGGER_TOKEN to be set" unless Gitlab::Util.get_env('DEPLOYER_TRIGGER_TOKEN')

    unless Build::Info.package == "gitlab-ee"
      puts "#{Build::Info.package} is not an ee package, not doing anything."
      exit
    end

    deploy_env = Build::Info.deploy_env
    operating_systems = Build::Info.package_list.map { |path| path.split("/")[1] }.uniq

    unless operating_systems.include?(Build::Info::DEPLOYER_OS_MAPPING[Build::Info.deploy_env_key])
      puts "Deployment to #{deploy_env} not to be triggered from this build (#{operating_systems.join(',')})."
      exit
    end

    if deploy_env.nil?
      puts 'Unable to determine which environment to deploy to, exiting...'
      exit
    end

    trigger_token = Gitlab::Util.get_env('DEPLOYER_TRIGGER_TOKEN')
    trigger_ref = Build::Check.is_auto_deploy? && Build::Check.ci_commit_tag? ? Gitlab::Util.get_env('CI_COMMIT_TAG') : :master

    if Gitlab::Util.get_env('AUTO_DEPLOY_OMNIBUS_TRIGGERS_DEPLOYER') == 'false' && Build::Check.is_auto_deploy?
      puts "AUTO_DEPLOY_OMNIBUS_TRIGGERS_DEPLOYER is disabled, exiting..."
      exit
    end

    # We do not support auto-deployments or triggered deployments
    # directly to production from the omnibus pipeline, this check is here
    # for safety
    raise NotImplementedError, "Environment #{deploy_env} is not supported" if deploy_env == 'gprd'

    deployer_helper = DeployerHelper.new(trigger_token, deploy_env, trigger_ref)
    url = deployer_helper.trigger_deploy
    puts "Deployer build triggered at #{url} on #{trigger_ref} for the #{deploy_env} environment"
  end
end
