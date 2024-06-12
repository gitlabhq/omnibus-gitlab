require 'spec_helper'
require 'gitlab/build/facts'

RSpec.describe Build::Facts do
  let(:version_manifest_contents) do
    <<-EOS
    {
      "manifest_format": 2,
      "software": {
        "gitlab-rails": {
          "locked_version": "6f286d7717f419489a08a9918621f438256e397b",
          "locked_source": {
            "git": "https://gitlab.com/gitlab-org/gitlab-foss.git"
          },
          "source_type": "git",
          "described_version": "master",
          "display_version": "master",
          "vendor": null,
          "license": "MIT"
        },
        "gitaly": {
          "locked_version": "b55578ec476e8bc8ecd9775ee7e9960b52e0f6e0",
          "locked_source": {
            "git": "https://gitlab.com/gitlab-org/gitaly"
          },
          "source_type": "git",
          "described_version": "master",
          "display_version": "master",
          "vendor": null,
          "license": "MIT"
        },
        "gitlab-shell": {
          "locked_version": "264d63e81cbf08e3ae75e84433b8d09af15f351f",
          "locked_source": {
            "git": "https://gitlab.com/gitlab-org/gitlab-shell.git"
          },
          "source_type": "git",
          "described_version": "main",
          "display_version": "main",
          "vendor": null,
          "license": "MIT"
        },
        "gitlab-pages": {
          "locked_version": "b0cb1f0c0783db2f5176301e6528fe41e1b42abf",
          "locked_source": {
            "git": "https://gitlab.com/gitlab-org/gitlab-pages.git"
          },
          "source_type": "git",
          "described_version": "master",
          "display_version": "master",
          "vendor": null,
          "license": "MIT"
        },
        "gitlab-kas": {
          "locked_version": "bab63c42d061bd8610fc681d7852df3c51eac515",
          "locked_source": {
            "git": "https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent.git"
          },
          "source_type": "git",
          "described_version": "master",
          "display_version": "master",
          "vendor": null,
          "license": "MIT"
        }
      }
    }
    EOS
  end
  let(:component_shas) do
    {
      'gitlab-rails' => '6f286d7717f419489a08a9918621f438256e397b',
      'gitlab-rails-ee' => '6f286d7717f419489a08a9918621f438256e397b',
      'gitaly' => 'b55578ec476e8bc8ecd9775ee7e9960b52e0f6e0',
      'gitlab-shell' => '264d63e81cbf08e3ae75e84433b8d09af15f351f',
      'gitlab-pages' => 'b0cb1f0c0783db2f5176301e6528fe41e1b42abf',
      'gitlab-kas' => 'bab63c42d061bd8610fc681d7852df3c51eac515'
    }
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
  end

  describe '.generate' do
    it 'calls necessary methods' do
      expect(described_class).to receive(:generate_tag_files)
      expect(described_class).to receive(:generate_version_files)
      expect(described_class).to receive(:generate_env_file)

      described_class.generate
    end
  end

  describe '.generate_tag_files' do
    before do
      allow(Build::Info::Git).to receive(:latest_stable_tag).and_return('14.6.2+ce.0')
      allow(Build::Info::Git).to receive(:latest_tag).and_return('14.7.0+rc42.ce.0')
    end

    it 'writes tag details to file' do
      expect(File).to receive(:write).with('build_facts/latest_stable_tag', '14.6.2+ce.0')
      expect(File).to receive(:write).with('build_facts/latest_tag', '14.7.0+rc42.ce.0')

      described_class.generate_tag_files
    end
  end

  describe '.get_component_shas' do
    context 'when version-manifest.json file does not exist' do
      before do
        allow(::File).to receive(:exist?).with('version-manifest.json').and_return(false)
      end

      it 'returns empty hash' do
        expect(described_class.get_component_shas).to eq({})
      end
    end

    context 'when version-manifest.json file exists' do
      before do
        allow(::File).to receive(:exist?).with('version-manifest.json').and_return(true)
        allow(::File).to receive(:read).with('version-manifest.json').and_return(version_manifest_contents)
      end

      it 'returns proper component shas hash' do
        expect(described_class.get_component_shas).to eq(component_shas)
      end
    end
  end

  describe '.generate_version_files' do
    context 'on tags' do
      before do
        allow(Build::Check).to receive(:on_tag?).and_return(true)
      end

      it 'does not generate version files as build facts' do
        expect(described_class).not_to receive(:get_component_shas)

        described_class.generate_version_files
      end
    end

    context 'on stable branches' do
      before do
        allow(Build::Check).to receive(:on_tag?).and_return(false)
        allow(Build::Check).to receive(:on_stable_branch?).and_return(true)
        allow(Build::Check).to receive(:mr_targetting_stable_branch?).and_return(false)
      end

      it 'does not generate version files as build facts' do
        expect(described_class).not_to receive(:get_component_shas)

        described_class.generate_version_files
      end
    end

    context 'on branches targetting a stable branch' do
      before do
        allow(Build::Check).to receive(:on_tag?).and_return(false)
        allow(Build::Check).to receive(:on_stable_branch?).and_return(false)
        allow(Build::Check).to receive(:mr_targetting_stable_branch?).and_return(true)
      end

      it 'does not generate version files as build facts' do
        expect(described_class).not_to receive(:get_component_shas)

        described_class.generate_version_files
      end
    end

    context 'on feature branches' do
      before do
        allow(Build::Check).to receive(:on_tag?).and_return(false)
        allow(Build::Check).to receive(:on_stable_branch?).and_return(false)
        allow(Build::Check).to receive(:mr_targetting_stable_branch?).and_return(false)
        allow(described_class).to receive(:get_component_shas).and_return(component_shas)
      end

      it 'writes version files as build facts' do
        component_shas.each do |component, version|
          expect(::File).to receive(:write).with("build_facts/#{component}_version", version)
        end

        described_class.generate_version_files
      end
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
      stub_is_ee(false)
      stub_env_var('TOP_UPSTREAM_SOURCE_PROJECT', 'gitlab-org/gitlab')
      stub_env_var('TOP_UPSTREAM_SOURCE_REF', 'master')
      stub_env_var('TOP_UPSTREAM_SOURCE_JOB', '123456')
      stub_env_var('TOP_UPSTREAM_SOURCE_SHA', 'aq2456fs')
      stub_env_var('TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID', '55555')
      stub_env_var('TOP_UPSTREAM_MERGE_REQUEST_IID', '7689')
      stub_env_var('BUILDER_IMAGE_REVISION', '1.2.3')
      stub_env_var('BUILDER_IMAGE_REGISTRY', 'registry.example.com')
      stub_env_var('PUBLIC_BUILDER_IMAGE_REGISTRY', 'registry.example.com')
      stub_env_var('DEV_BUILDER_IMAGE_REGISTRY', 'dev.gitlab.org:5005')
    end

    it 'returns correct variables' do
      result = %w[
        TOP_UPSTREAM_SOURCE_PROJECT=gitlab-org/gitlab
        TOP_UPSTREAM_SOURCE_REF=master
        TOP_UPSTREAM_SOURCE_JOB=123456
        TOP_UPSTREAM_SOURCE_SHA=aq2456fs
        TOP_UPSTREAM_MERGE_REQUEST_PROJECT_ID=55555
        TOP_UPSTREAM_MERGE_REQUEST_IID=7689
        BUILDER_IMAGE_REVISION=1.2.3
        BUILDER_IMAGE_REGISTRY=registry.example.com
        PUBLIC_BUILDER_IMAGE_REGISTRY=registry.example.com
        DEV_BUILDER_IMAGE_REGISTRY=dev.gitlab.org:5005
        COMPILE_ASSETS=false
        EDITION=CE
        ee=false
      ]

      expect(described_class.common_vars).to eq(result)
    end
  end

  describe '.qa_trigger_vars' do
    before do
      allow(described_class).to receive(:generate_knapsack_report?).and_return('true')
      allow(Build::GitlabImage).to receive(:gitlab_registry_image_address).and_return('registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/gitlab-ee:14.6.2-rfbranch.450066356.c97110ad-0')
      allow(Build::Info::Git).to receive(:latest_stable_tag).and_return("14.6.2+rfbranch.450066356")

      stub_env_var('QA_IMAGE', 'gitlab/gitlab-ee-qa:nightly')
      stub_env_var('QA_TESTS', '')
      stub_env_var('TOP_UPSTREAM_SOURCE_PROJECT', 'gitlab-org/gitaly')
      stub_env_var('PACKAGE_URL', 'https://example.com/gitlab.deb')
      stub_env_var('FIPS_PACKAGE_URL', 'https://example.com/gitlab-fips.deb')
      stub_env_var('ee', 'true')
    end

    it 'returns correct variables' do
      result = %w[
        QA_RELEASE=registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/gitlab-ee:14.6.2-rfbranch.450066356.c97110ad-0
        QA_IMAGE=gitlab/gitlab-ee-qa:nightly
        QA_TESTS=
        ALLURE_JOB_NAME=gitaly-ee
        GITLAB_SEMVER_VERSION=14.6.2-rfbranch.450066356
        RAT_REFERENCE_ARCHITECTURE=omnibus-gitlab-mrs
        RAT_FIPS_REFERENCE_ARCHITECTURE=omnibus-gitlab-mrs-fips-ubuntu
        RAT_PACKAGE_URL=https://example.com/gitlab.deb
        RAT_FIPS_PACKAGE_URL=https://example.com/gitlab-fips.deb
      ]

      expect(described_class.qa_trigger_vars).to eq(result)
    end
  end
end
