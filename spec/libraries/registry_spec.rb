require 'chef_helper'
require_relative '../../files/gitlab-cookbooks/gitlab/libraries/registry'

RSpec.describe Registry do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'registry is disabled' do
    before do
      stub_gitlab_rb(
        registry: {
          enabled: false
        }
      )
    end

    it 'should return false' do
      expect(described_class.auto_enable).to be_falsey
    end
  end

  context 'registry_external_url is set' do
    before do
      stub_gitlab_rb(
        registry_external_url: 'https://registry.example.com'
      )
    end

    it 'should return false' do
      expect(described_class.auto_enable).to be_falsey
    end
  end

  context 'lets encrypt is not enabled' do
    before do
      stub_gitlab_rb(
        letsencrypt: {
          enable: false
        }
      )
    end

    it 'should return false' do
      expect(described_class.auto_enable).to be_falsey
    end
  end

  context 'external_url is a relative url' do
    before do
      stub_gitlab_rb(
        external_url: 'https://registry.example.com/path'
      )
    end

    it 'should return false' do
      expect(described_class.auto_enable).to be_falsey
    end
  end
end
