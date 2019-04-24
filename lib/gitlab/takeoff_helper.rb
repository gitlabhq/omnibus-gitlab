require "http"
require "json"
require_relative "util.rb"

class PipelineTriggerFailure < StandardError; end
class TakeoffHelper
  RETRY_INTERVAL = 5
  def initialize(trigger_token, deploy_env, trigger_ref)
    @deploy_env = deploy_env
    @trigger_token = trigger_token
    @trigger_ref = trigger_ref
    @endpoint = "https://#{trigger_host}/api/v4"
  end

  def trigger_deploy
    begin
      retries ||= 0
      resp = HTTP.post(pipeline_trigger_url, form: form_data_for_trigger)
      raise PipelineTriggerFailure unless resp.status == 201
    rescue PipelineTriggerFailure
      if (retries +=1) <3
        sleep RETRY_INTERVAL
        puts "Retrying pipeline trigger ##{retries} due to invalid status: #{resp.status}"
        retry
      else
        raise "Unable to trigger pipeline after #{retries} retries"
      end
    end
    web_url_from_trigger(resp)
  end

  def web_url_from_trigger(resp)
    begin
      JSON.parse(resp.body.to_s)['web_url']
    rescue JSON::ParserError
      raise "Unable to parse response from pipeline trigger, got #{resp.body.to_s}"
    end
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

  def form_data_for_trigger
    {
      'token' => @trigger_token,
      'ref' => @trigger_ref,
    }.merge(takeoff_env_vars.map { |k, v| ["variables[#{k}]", v] }.to_h)
  end

  def takeoff_env_vars
    {
      'DEPLOY_ENVIRONMENT' => @deploy_env,
      'DEPLOY_VERSION' => Gitlab::Util.get_env('TAKEOFF_VERSION') || release,
      'DEPLOY_REPO' => Gitlab::Util.get_env('TAKEOFF_DEPLOY_REPO') || 'gitlab/pre-release',
      'DEPLOY_USER' => Gitlab::Util.get_env('TAKEOFF_DEPLOY_USER') || 'takeoff'
    }
  end
end
