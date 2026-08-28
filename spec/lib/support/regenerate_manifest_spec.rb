require 'spec_helper'

# The script lives in support/ and is meant to be run standalone, so we load it
# by path. Requiring it only defines constants and the ManifestRegen module; the
# orchestration is guarded by `$PROGRAM_NAME == __FILE__`, so nothing runs here.
require_relative '../../../support/regenerate-manifest'

RSpec.describe ManifestRegen do
  describe '.detect_edition' do
    it 'returns ee for an EE tag' do
      expect(described_class.detect_edition('19.0.5+ee.0')).to eq('ee')
    end

    it 'returns ce for a CE tag' do
      expect(described_class.detect_edition('19.0.5+ce.0')).to eq('ce')
    end

    it 'returns nil when the edition cannot be determined' do
      expect(described_class.detect_edition('19.0.5+rc42.ee.0')).to be_nil
      expect(described_class.detect_edition('garbage')).to be_nil
    end
  end

  describe '.manifest_version' do
    it 'strips the build metadata after the +' do
      expect(described_class.manifest_version('19.0.5+ee.0')).to eq('19.0.5')
    end
  end

  describe '.minor_version' do
    it 'keeps the major and minor components' do
      expect(described_class.minor_version('19.0.5')).to eq('19.0')
      expect(described_class.minor_version('18.11.2')).to eq('18.11')
    end
  end

  describe '.build_iteration' do
    it 'returns the part of the tag after + and before any -' do
      expect(described_class.build_iteration('19.0.5+ee.0')).to eq('ee.0')
      expect(described_class.build_iteration('19.0.5+ce.0')).to eq('ce.0')
    end
  end

  describe '.object_version' do
    it 'joins the version and build iteration like release_version' do
      expect(described_class.object_version('19.0.5+ee.0')).to eq('19.0.5-ee.0')
    end
  end

  describe '.object_key' do
    it 'matches the key the rake task uploads (includes the build iteration)' do
      expect(described_class.object_key(edition: 'ee', tag: '19.0.5+ee.0'))
        .to eq('gitlab-manifests/gitlab-ee/19.0/19.0.5-ee.0-ee.version-manifest.json')
      expect(described_class.object_key(edition: 'ce', tag: '19.0.5+ce.0'))
        .to eq('gitlab-manifests/gitlab-ce/19.0/19.0.5-ce.0-ce.version-manifest.json')
    end
  end

  describe '.ci_commit_tag_override' do
    it 'pins CI_COMMIT_TAG to the tag being regenerated' do
      expect(described_class.ci_commit_tag_override('19.0.5+ee.0'))
        .to eq('CI_COMMIT_TAG' => '19.0.5+ee.0')
    end
  end

  describe '.proactive_auth_supported?' do
    it 'is true for git 2.46 and newer' do
      expect(described_class.proactive_auth_supported?('git version 2.46.0')).to be(true)
      expect(described_class.proactive_auth_supported?('git version 2.51.1')).to be(true)
      expect(described_class.proactive_auth_supported?('git version 3.0.0')).to be(true)
    end

    it 'is false for older git' do
      expect(described_class.proactive_auth_supported?('git version 2.45.2')).to be(false)
      expect(described_class.proactive_auth_supported?('git version 2.34.1')).to be(false)
    end

    it 'is false when no version can be parsed' do
      expect(described_class.proactive_auth_supported?('not a version')).to be(false)
    end
  end

  describe '.gitlab_com_auth' do
    let(:repo_url) { 'https://gitlab.com/gitlab-org/omnibus-gitlab.git' }

    context 'when GITLAB_TOKEN is set' do
      it 'authenticates all of gitlab.com regardless of host' do
        env = { 'GITLAB_TOKEN' => 'glpat-x', 'CI_SERVER_HOST' => 'dev.gitlab.org' }

        auth = described_class.gitlab_com_auth(env, repo_url)

        expect(auth).to include(
          user: 'oauth2',
          secret_var: 'GITLAB_TOKEN',
          cred_scope: 'https://gitlab.com',
          http_scope: 'https://gitlab.com'
        )
      end

      it 'takes precedence over CI_JOB_TOKEN' do
        env = { 'GITLAB_TOKEN' => 'glpat-x', 'CI_JOB_TOKEN' => 'job', 'CI_SERVER_HOST' => 'gitlab.com' }

        expect(described_class.gitlab_com_auth(env, repo_url)[:secret_var]).to eq('GITLAB_TOKEN')
      end
    end

    context 'when only CI_JOB_TOKEN is set on gitlab.com' do
      it 'scopes the token to the omnibus-gitlab clone only' do
        env = { 'CI_JOB_TOKEN' => 'job', 'CI_SERVER_HOST' => 'gitlab.com' }

        auth = described_class.gitlab_com_auth(env, repo_url)

        expect(auth).to include(
          user: 'gitlab-ci-token',
          secret_var: 'CI_JOB_TOKEN',
          cred_scope: 'https://gitlab.com/gitlab-org/omnibus-gitlab',
          http_scope: 'https://gitlab.com/gitlab-org/omnibus-gitlab.git'
        )
      end
    end

    context 'when CI_JOB_TOKEN is set but not on gitlab.com' do
      it 'clones anonymously so a dev job token is never sent to gitlab.com' do
        env = { 'CI_JOB_TOKEN' => 'devjob', 'CI_SERVER_HOST' => 'dev.gitlab.org' }

        expect(described_class.gitlab_com_auth(env, repo_url)).to be_nil
      end
    end

    context 'when CI_JOB_TOKEN is set on gitlab.com but the repo is not on gitlab.com' do
      it 'clones anonymously' do
        env = { 'CI_JOB_TOKEN' => 'job', 'CI_SERVER_HOST' => 'gitlab.com' }

        auth = described_class.gitlab_com_auth(env, 'https://example.com/mirror/omnibus-gitlab.git')

        expect(auth).to be_nil
      end
    end

    context 'when no token is set' do
      it 'clones anonymously' do
        expect(described_class.gitlab_com_auth({}, repo_url)).to be_nil
      end
    end
  end
end
