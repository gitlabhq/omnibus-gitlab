require 'spec_helper'
require 'gitlab/build/facts'
require 'gitlab/build/gitlab_image'

RSpec.describe Build::Facts do
  before do
    allow(ENV).to receive(:[]).and_call_original
  end

  describe '.generate' do
    it 'calls necessary methods' do
      expect(described_class).to receive(:generate_tag_files)
      expect(described_class).to receive(:generate_env_file)

      described_class.generate
    end
  end

  describe '.generate_tag_files' do
    before do
      allow(Build::Info).to receive(:latest_stable_tag).and_return('14.6.2+ce.0')
      allow(Build::Info).to receive(:latest_tag).and_return('14.7.0+rc42.ce.0')
    end

    it 'writes tag details to file' do
      expect(File).to receive(:write).with('build_facts/latest_stable_tag', '14.6.2+ce.0')
      expect(File).to receive(:write).with('build_facts/latest_tag', '14.7.0+rc42.ce.0')

      described_class.generate_tag_files
    end
  end

  describe '.generate_env_file' do
    before do
      allow(described_class).to receive(:common_vars).and_return(%w[TOP_UPSTREAM_SOURCE_PROJECT=gitlab-org/gitlab])
      allow(described_class).to receive(:qa_trigger_vars).and_return(%w[QA_RELEASE=foobar])
      allow(described_class).to receive(:version_vars).and_return(%w[GITLAB_VERSION=randombranch])
    end

    it 'writes environment variables to file' do
      expect(File).to receive(:write).with('build_facts/env_vars', "TOP_UPSTREAM_SOURCE_PROJECT=gitlab-org/gitlab\nQA_RELEASE=foobar\nGITLAB_VERSION=randombranch")

      described_class.generate_env_file
    end
  end

  describe '.common_vars' do
    before do
      stub_env_var('TOP_UPSTREAM_SOURCE_PROJECT', 'gitlab-org/gitlab')
      stub_env_var('TOP_UPSTREAM_SOURCE_REF', 'master')
      stub_env_var('TOP_UPSTREAM_SOURCE_JOB', '123456')
      stub_env_var('TOP_UPSTREAM_SOURCE_SHA', 'aq2456fs')
      stub_env_var('TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID', '55555')
      stub_env_var('TOP_UPSTREAM_MERGE_REQUEST_IID', '7689')
    end

    it 'returns correct variables' do
      result = %w[
        TOP_UPSTREAM_SOURCE_PROJECT=gitlab-org/gitlab
        TOP_UPSTREAM_SOURCE_REF=master
        TOP_UPSTREAM_SOURCE_JOB=123456
        TOP_UPSTREAM_SOURCE_SHA=aq2456fs
        TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID=55555
        TOP_UPSTREAM_MERGE_REQUEST_IID=7689
        EDITION=ce
        ee=false
      ]

      expect(described_class.common_vars).to eq(result)
    end
  end

  describe '.qa_trigger_vars' do
    before do
      allow(described_class).to receive(:generate_knapsack_report?).and_return('true')
      allow(Build::GitlabImage).to receive(:gitlab_registry_image_address).and_return('registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/gitlab-ee:14.6.2-rfbranch.450066356.c97110ad-0')

      stub_env_var('QA_IMAGE', 'gitlab/gitlab-ee-qa:nightly')
      stub_env_var('QA_BRANCH', 'testapalooza')
      stub_env_var('QA_TESTS', '')
      stub_env_var('ALLURE_JOB_NAME', '')
      stub_env_var('GITLAB_QA_OPTIONS', '')
    end

    it 'returns correct variables' do
      result = %w[
        QA_BRANCH=testapalooza
        QA_RELEASE=registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/gitlab-ee:14.6.2-rfbranch.450066356.c97110ad-0
        QA_IMAGE=gitlab/gitlab-ee-qa:nightly
        QA_TESTS=
        ALLURE_JOB_NAME=
        GITLAB_QA_OPTIONS=
        KNAPSACK_GENERATE_REPORT=true
      ]

      expect(described_class.qa_trigger_vars).to eq(result)
    end
  end
end
