require 'chef_helper'

describe Services do
  before { allow(Gitlab).to receive(:[]).and_call_original }

  describe 'when using the gitlab cookbook' do
    cached(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
    it 'returns the gitlab service list' do
      chef_run
      expect(Services.service_list).to have_key('gitlab-rails')
      expect(Services.service_list).not_to have_key('sentinel')
    end
  end

  describe 'when using the gitlab-ee cookbook' do
    cached(:chef_run) { ChefSpec::SoloRunner.converge('gitlab-ee::default') }
    it 'returns the gitlab service list including gitlab-ee items' do
      chef_run
      expect(Services.service_list).to have_key('gitlab-rails')
      expect(Services.service_list).to have_key('sentinel')
    end
  end
end
