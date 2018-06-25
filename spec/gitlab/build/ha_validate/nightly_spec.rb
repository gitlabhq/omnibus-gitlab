require 'spec_helper'
require 'gitlab/build/ha_validate/nightly'

describe Build::HA::ValidateNightly do
  let(:expected_url) { 'https://omnibus-builds.s3.amazonaws.com/ubuntu-xenial/gitlab-ee_99.9.9%2Brfbranch-55_amd64.deb' }

  before do
    allow(Build::Info).to receive(:semver_version).and_return('99.9.9+rfbranch')
    allow_any_instance_of(Gitlab::BuildIteration).to receive(:build_iteration).and_return(55)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('HA_VALIDATE_TOKEN').and_return('faketoken')
  end

  it 'returns the correct package url' do
    expect(described_class.package_url).to eq(expected_url)
  end

  it 'generates the expected parameters' do
    results = {
      'ref' => 'master',
      'token' => 'faketoken',
      'variables[QA_IMAGE]' => 'gitlab/gitlab-ee-qa:nightly',
      'variables[PACKAGE_URL]' => expected_url
    }
    expect(described_class.get_params).to eq(results)
  end
end
