require 'spec_helper'
require 'gitlab/build'
require 'gitlab/takeoff_helper'

describe TakeoffHelper  do
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
            "variables[DEPLOY_ENVIRONMENT]"=>"some-env",
            "variables[DEPLOY_VERSION]"=>"some-version",
            "variables[DEPLOY_REPO]"=>"gitlab/pre-release",
            "variables[DEPLOY_USER]"=>"takeoff"
          }
        ).and_return(response)
      expect(service.trigger_deploy).to eq('http://example.com')
    end
  end
end
