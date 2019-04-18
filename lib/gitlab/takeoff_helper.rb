require "http"
require "json"
require_relative "util.rb"

class TakeoffHelper
  def initialize(trigger_token, deploy_env, trigger_ref)
    @deploy_env = deploy_env
    @trigger_token = trigger_token
    @trigger_ref = trigger_ref
    @endpoint = "https://#{trigger_host}/api/v4"
  end

  def trigger_deploy
    form_data = {
      "token" => @trigger_token,
      "ref" => @trigger_ref,
      "variables[DEPLOY_ENVIRONMENT]" => @deploy_env,
      "variables[DEPLOY_VERSION]" => 'some-version-that-does-not-exist'
    }
    resp = HTTP.post(pipeline_trigger_url, :form => form_data)
    raise "Unable to trigger #{pipeline_url}, status: #{resp.status}" unless resp.status == 201
    JSON.parse(resp.body.to_s)['web_url']
  end

  def pipeline_trigger_url
    "#{@endpoint}/projects/#{trigger_project}/trigger/pipeline"
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
      'DEPLOY_ENVIRONMENT': @deploy_env,
      'DEPLOY_VERSION': Gitlab::Util.get_env('TAKEOFF_VERSION') || release,
      'DEPLOY_REPO': Gitlab::Util.get_env('TAKEOFF_DEPLOY_REPO') || 'gitlab/pre-release',
      'DEPLOY_USER': Gitlab::Util.get_env('TAKEOFF_DEPLOY_USER') || 'takeoff',
      'CHECKMODE': '--check'
    }
  end
end
