require 'chef_helper'

RSpec.describe SettingsDSL::Utils do
  subject { described_class }

  describe '.hyphenated_form' do
    it 'returns original string if no underscore exists' do
      expect(subject.hyphenated_form('foo-bar')).to eq('foo-bar')
    end

    it 'returns string with underscores replaced by hyphens' do
      expect(subject.hyphenated_form('foo_bar')).to eq('foo-bar')
    end
  end

  describe '.underscored_form' do
    it 'returns original string if no hyphen exists' do
      expect(subject.underscored_form('foo_bar')).to eq('foo_bar')
    end

    it 'returns string with hyphens replaced by underscores' do
      expect(subject.underscored_form('foo-bar')).to eq('foo_bar')
    end
  end

  describe '.sanitized_key' do
    it 'returns underscored form for services specified to skip hyphenation' do
      [
        %w[gitlab-pages gitlab_pages],
        %w[gitlab-sshd gitlab_sshd],
        %w[node-exporter node_exporter],
        %w[redis-exporter redis_exporter],
        %w[postgres-exporter postgres_exporter],
        %w[pgbouncer-exporter pgbouncer_exporter],
        %w[gitlab-shell gitlab_shell],
        %w[suggested-reviewers suggested_reviewers],
        %w[gitlab-exporter gitlab_exporter],
        %w[remote-syslog remote_syslog],
        %w[gitlab-workhorse gitlab_workhorse],
        %w[gitlab-kas gitlab_kas],
        %w[geo-secondary geo_secondary],
        %w[geo-logcursor geo_logcursor],
        %w[geo-postgresql geo_postgresql],
        %w[gitlab-rails gitlab_rails],
        %w[external-url external_url],
        %w[gitlab-kas-external-url gitlab_kas_external_url],
        %w[mattermost-external-url mattermost_external_url],
        %w[pages-external-url pages_external_url],
        %w[registry-external-url registry_external_url],
        %w[gitlab-ci gitlab_ci],
        %w[high-availability high_availability],
        %w[manage-accounts manage_accounts],
        %w[manage-storage-directories manage_storage_directories],
        %w[omnibus-gitconfig omnibus_gitconfig],
        %w[prometheus-monitoring prometheus_monitoring],
        %w[runtime-dir runtime_dir],
        %w[storage-check storage_check],
        %w[web-server web_server],
      ].each do |input, output|
        expect(subject.sanitized_key(input)).to eq(output)
      end
    end

    it 'returns hyphenated form for services not specified to skip hyphenation' do
      [
        %w[foo-bar foo-bar],
        %w[foo_bar foo-bar],
      ].each do |input, output|
        expect(subject.sanitized_key(input)).to eq(output)
      end
    end
  end

  describe 'secrets generation' do
    let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }

    before do
      allow(Gitlab).to receive(:[]).and_call_original
    end

    describe 'default secrets' do
      context 'by default' do
        it 'generates default secrets' do
          expect(GitlabRails).to receive(:parse_secrets)

          chef_run
        end
      end

      context 'when explicitly disabled' do
        before do
          stub_gitlab_rb(
            package: {
              generate_default_secrets: false
            }
          )
        end

        it 'does not generate default secrets' do
          expect(GitlabRails).not_to receive(:parse_secrets)

          chef_run
        end
      end
    end

    describe 'gitlab-secrets.json file' do
      let(:file) { double(:file, puts: true, chmod: true) }

      before do
        allow(::File).to receive(:directory?).and_call_original
        allow(::File).to receive(:directory?).with('/etc/gitlab').and_return(true)
        allow(::File).to receive(:open).with('/etc/gitlab/gitlab-secrets.json', 'w', 0600).and_yield(file).once
      end

      context 'by default' do
        it 'generates gitlab-secrets.json file' do
          expect(::File).to receive(:open).with('/etc/gitlab/gitlab-secrets.json', 'w', 0600)

          chef_run
        end
      end

      context 'when explicitly disabled' do
        before do
          stub_gitlab_rb(
            package: {
              generate_secrets_json_file: false
            }
          )

          allow(LoggingHelper).to receive(:warning).and_call_original
        end

        it 'does not generate gitlab-secrets.json file' do
          expect(::File).not_to receive(:open).with('/etc/gitlab/gitlab-secrets.json', 'w', 0600)

          chef_run
        end

        it 'generates warning about secrets not persisting' do
          expect(LoggingHelper).to receive(:warning).with(/You've enabled generating default secrets but have disabled writing them to gitlab-secrets.json file/)

          chef_run
        end
      end
    end
  end
end
