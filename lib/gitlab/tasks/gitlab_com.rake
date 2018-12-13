require 'gitlab'
require_relative '../takeoff_helper.rb'

namespace :gitlab_com do
  desc 'Tasks related to gitlab.com.'
  task :takeoff do
    %w[TAKEOFF_TRIGGER_TOKEN TAKEOFF_ENVIRONMENT].each do |env_var|
      abort "This task requires #{env_var} to be set" unless ENV[env_var]
    end

    latest_tag = Build::Info.latest_tag
    unless Build::Check.match_tag?(latest_tag)
      puts "#{latest_tag} is not the latest tag, not doing anything."
      exit
    end

    unless Build::Info.package == "gitlab-ee"
      puts "#{Build::Info.package} is not an ee package, not doing anything."
      exit
    end

    trigger_token = ENV['TAKEOFF_TRIGGER_TOKEN']
    deploy_env = ENV['TAKEOFF_ENVIRONMENT']

    # there is only support for staging deployments
    # from ci at this time, error here for safety.
    raise NotImplementedError, "Environment #{deploy_env} not supported" unless deploy_env == "gstg"

    takeoff_helper = TakeoffHelper.new(trigger_token, deploy_env)
    url = takeoff_helper.trigger_deploy
    puts "Takeoff build triggered at #{url}"
  end
end
