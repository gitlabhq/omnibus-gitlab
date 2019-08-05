require "http"
require "json"
require_relative "util.rb"

PipelineTriggerFailure = Class.new(StandardError)
class DeployerHelper
  TRIGGER_RETRY_INTERVAL = 5
  TRIGGER_RETRIES = 3
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
      puts "Triggering pipeline #{pipeline_trigger_url} for ref #{@trigger_ref}, status code: #{resp.status}"
      raise PipelineTriggerFailure unless resp.status == 201
    rescue PipelineTriggerFailure
      if (retries += 1) < TRIGGER_RETRIES
        sleep TRIGGER_RETRY_INTERVAL
        puts "Retrying pipeline trigger ##{retries} due to invalid status: #{resp.status}"
        retry
      end
      raise "Unable to trigger pipeline after #{retries} retries"
    end
    web_url_from_trigger(resp)
  end

  def web_url_from_trigger(resp)
    JSON.parse(resp.body.to_s)['web_url']
  rescue JSON::ParserError
    raise "Unable to parse response from pipeline trigger, got #{resp.body}"
  end

  def pipeline_trigger_url
    "#{@endpoint}/projects/#{trigger_project}/trigger/pipeline"
  end

  def trigger_host
    @trigger_host ||= Gitlab::Util.get_env('DEPLOYER_TRIGGER_HOST') || 'ops.gitlab.net'
  end

  def trigger_project
    # Project ID 135 is the project ID of deployer on ops.gitlab.net
    @trigger_project ||= Gitlab::Util.get_env('DEPLOYER_TRIGGER_PROJECT') || '135'
  end

  def release
    @release ||= Build::Info.docker_tag
  end

  def form_data_for_trigger
    {
      'token' => @trigger_token,
      'ref' => @trigger_ref,
    }.merge(deployer_env_vars.map { |k, v| ["variables[#{k}]", v] }.to_h)
  end

  def deployer_env_vars
    {
      'DEPLOY_ENVIRONMENT' => @deploy_env,
      'DEPLOY_VERSION' => Gitlab::Util.get_env('DEPLOYER_VERSION') || release,
      'DEPLOY_USER' => Gitlab::Util.get_env('DEPLOYER_DEPLOY_USER') || 'deployer'
    }
  end
end
