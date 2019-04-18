require 'spec_helper'
require 'gitlab/takeoff_helper'

describe TakeoffHelper  do
  subject(:service) { described_class.new('gstg', 'token', 'master') }
  describe '#trigger_deploy' do
    it 'triggers an auto deploy' do
      response = instance_double('response', body: JSON.dump(web_url: 'http://example.com'), status: 201)
      expect(HTTP)
        .to receive(:post)
        .with(
          "https://ops.gitlab.net/api/v4/projects/135/trigger/pipeline",
          form: {
            "token" => "gstg",
            "ref" => "master",
            "variables[DEPLOY_ENVIRONMENT]"=>"pre",
            "variables[DEPLOY_VERSION]"=>"some-version-that-does-not-exist",
            "variables[CHECKMODE]"=>"--check"
          }
        ).and_return(response)
      expect(service.trigger_deploy).to eq('http://example.com')
    end
  end
end
