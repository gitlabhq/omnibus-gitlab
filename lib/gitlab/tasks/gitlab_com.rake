require_relative '../takeoff_helper.rb'
require_relative "../util.rb"

namespace :gitlab_com do
  desc 'Tasks related to gitlab.com.'
  task :takeoff do
    %w[TAKEOFF_TRIGGER_TOKEN TAKEOFF_ENVIRONMENT].each do |env_var|
      abort "This task requires #{env_var} to be set" unless ENV[env_var]
    end

    unless Build::Info.package == "gitlab-ee"
      puts "#{Build::Info.package} is not an ee package, not doing anything."
      exit
    end

    unless Build::Check.is_auto_deploy?
      latest_tag = Build::Info.latest_tag
      unless Build::Check.match_tag?(latest_tag)
        puts "#{latest_tag} is not the latest tag, not doing anything."
        exit
      end
    end

    trigger_token = Gitlab::Util.get_env('TAKEOFF_TRIGGER_TOKEN')
    trigger_ref = Build::Check.is_auto_deploy? && Build::Check.ci_commit_tag? ? Gitlab::Util.get_env('CI_COMMIT_TAG') : :master
    deploy_env = Gitlab::Util.get_env('TAKEOFF_ENVIRONMENT')

    # We do not support auto-deployments or triggered deployments
    # to production from the omnibus pipeline, this check is here
    # for safety
    raise NotImplementedError, "Environment #{deploy_env} is not supported" if deploy_env.include?('gprd')
    takeoff_helper = TakeoffHelper.new(trigger_token, deploy_env, trigger_ref)
    url = takeoff_helper.trigger_deploy
    puts "Takeoff build triggered at #{url} on #{trigger_ref} for the #{deploy_env} environment"
  end
end
