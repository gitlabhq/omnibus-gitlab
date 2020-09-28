require 'spec_helper'
require 'gitlab/build'
require 'gitlab/deployer_helper'

RSpec.describe DeployerHelper do
  subject(:service) { described_class.new('some-token', 'some-env', 'some-branch') }
  describe '#trigger_deploy' do
    it 'triggers an auto deploy' do
      response = instance_double('response', body: JSON.dump(web_url: 'http://example.com'), status: 201)
      allow(Build::Info).to receive(:docker_tag).and_return('some-version')
      expect(HTTP)
        .to receive(:post)
        .with(
          "https://ops.gitlab.net/api/v4/projects/135/trigger/pipeline",
          form: {
            "token" => "some-token",
            "ref" => "some-branch",
            "variables[DEPLOY_ENVIRONMENT]" => "some-env",
            "variables[DEPLOY_VERSION]" => "some-version",
            "variables[DEPLOY_USER]" => "deployer"
          }
        ).and_return(response)
      expect(service.trigger_deploy).to eq('http://example.com')
    end

    it 'triggers an auto deploy with retries' do
      # Set this to zero so there we don't have delays during tests
      stub_const('DeployerHelper::TRIGGER_RETRY_INTERVAL', 0)
      response = instance_double('response', body: JSON.dump(web_url: 'http://example.com'), status: 401)
      allow(Build::Info).to receive(:docker_tag).and_return('some-version')
      expect(HTTP)
        .to receive(:post)
        .with(
          "https://ops.gitlab.net/api/v4/projects/135/trigger/pipeline",
          form: {
            "token" => "some-token",
            "ref" => "some-branch",
            "variables[DEPLOY_ENVIRONMENT]" => "some-env",
            "variables[DEPLOY_VERSION]" => "some-version",
            "variables[DEPLOY_USER]" => "deployer"
          }
        ).and_return(response).exactly(3).times
      expect { service.trigger_deploy }.to raise_error(RuntimeError, "Unable to trigger pipeline after 3 retries")
    end
  end
end
