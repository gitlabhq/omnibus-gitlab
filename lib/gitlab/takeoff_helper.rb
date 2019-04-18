require "faraday"
require_relative "util.rb"

class TakeoffHelper
  attr_reader :deploy_env, :trigger_ref, :trigger_token, :endpoint
  def initialize(trigger_token, deploy_env, trigger_ref)
    @deploy_env = deploy_env
    @trigger_token = trigger_token
    @trigger_ref = trigger_ref
    @endpoint = "https://#{trigger_host}/api/v4"
  end

  def client
    @client ||= Gitlab::Client.new(token: nil, host: trigger_host)
  end

  def trigger_deploy
    # For triggers we don't need an API token, so we explicitly set it to nil
    data = {
      "token": trigger_token,
      "ref": trigger_ref,
      "variables[DEPLOY_ENVIRONMENT]": 'gstg',
      "variables[DEPLOY_VERSION]": 'some-version-that-does-not-exist'
    }

    response = Faraday.post("#{endpoint}/projects/151/trigger/pipeline") do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(data)
    end


    response = client.run_trigger(
      trigger_project,
      trigger_token,
      trigger_ref,
      takeoff_env_vars
    )
    response.web_url
  end

  def trigger_host
    @trigger_host ||= Gitlab::Util.get_env('TAKEOFF_TRIGGER_HOST') || 'ops.gitlab.net'
  end

  def trigger_project
    # Project ID 135 is the project ID of takeoff on ops.gitlab.net
    @trigger_project ||= Gitlab::Util.get_env('TAKEOFF_TRIGGER_PROJECT') || '135'
  end

  def release
    @release ||= Build::Info.docker_tag
  end

  def takeoff_env_vars
    {
      'DEPLOY_ENVIRONMENT': deploy_env,
      'DEPLOY_VERSION': Gitlab::Util.get_env('TAKEOFF_VERSION') || release,
      'DEPLOY_REPO': Gitlab::Util.get_env('TAKEOFF_DEPLOY_REPO') || 'gitlab/pre-release',
      'DEPLOY_USER': Gitlab::Util.get_env('TAKEOFF_DEPLOY_USER') || 'takeoff',
      'CHECKMODE': '--check'
    }
  end
end
