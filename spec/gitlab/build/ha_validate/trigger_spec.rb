require 'spec_helper'
require 'gitlab/build/ha_validate/trigger'

describe Build::HA::ValidateTrigger do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('CI_COMMIT_SHA').and_return('11111111111111111')
    allow(ENV).to receive(:[]).with('HA_VALIDATE_TOKEN').and_return('faketoken')
    allow(Build::Info).to receive(:fetch_pipeline_jobs).and_return(
      [
        {
          'name' => 'imajob',
          'id' => 1
        },
        {
          'name' => 'badjob',
          'id' => 2
        },
        {
          'name' => 'Trigger:package',
          'id' => 3
        }
      ]
    )
  end

  it 'should return the correct job id' do
    expect(described_class.ee_package_job_id).to eq(3)
  end

  describe '#get_params' do
    it 'should return the correct default params' do
      expect(described_class.get_params).to eq(
        {
          'ref' => 'master',
          'token' => 'faketoken',
          'variables[QA_IMAGE]' => 'registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/gitlab-ee-qa:omnibus-11111111111111111',
          'variables[OMNIBUS_JOB_ID]' => 3
        }
      )
    end

    it 'should return the correct params with an image url' do
      expect(described_class.get_params(image: 'fake/image/url')).to eq(
        {
          'ref' => 'master',
          'token' => 'faketoken',
          'variables[QA_IMAGE]' => 'fake/image/url',
          'variables[OMNIBUS_JOB_ID]' => 3
        }
      )
    end
  end
end
