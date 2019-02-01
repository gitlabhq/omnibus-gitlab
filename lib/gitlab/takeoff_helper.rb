require 'gitlab'
require_relative "util.rb"

class TakeoffHelper
  def initialize(trigger_token, deploy_env)
    @deploy_env = deploy_env
    @trigger_token = trigger_token
    Gitlab.endpoint = "https://#{trigger_host}/api/v4"
  end

  def client
    @client ||= Gitlab::Client.new(token: nil, host: trigger_host)
  end

  def trigger_deploy
    # For triggers we don't need an API token, so we explicitly set it to nil
    response = client.run_trigger(
      trigger_project,
      @trigger_token,
      :master,
      takeoff_env_vars
    )
    response.web_url
  end

  def trigger_host
    Gitlab::Util.get_env('TAKEOFF_TRIGGER_HOST') || 'ops.gitlab.net'
  end

  def trigger_project
    # Project ID 135 is the project ID of takeoff on ops.gitlab.net
    Gitlab::Util.get_env('TAKEOFF_TRIGGER_PROJECT') || '135'
  end

  def release
    @release ||= Build::Info.docker_tag
  end

  def takeoff_env_vars
    {
      'DEPLOY_ENVIRONMENT': @deploy_env,
      'DEPLOY_VERSION': Gitlab::Util.get_env('TAKEOFF_VERSION') || release,
      'DEPLOY_REPO': Gitlab::Util.get_env('TAKEOFF_DEPLOY_REPO') || 'gitlab/pre-release',
      'DEPLOY_USER': Gitlab::Util.get_env('TAKEOFF_DEPLOY_USER') || 'takeoff'
    }
  end
end
