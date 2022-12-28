require 'chef_helper'

RSpec.describe 'gitlab-ee::suggested_reviwers' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab-ee::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(File).to receive(:symlink?).and_call_original
    %w(
      alertmanager
      gitlab-exporter
      gitlab-pages
      gitlab-kas
      gitlab-workhorse
      logrotate
      nginx
      node-exporter
      postgres-exporter
      postgresql
      prometheus
      redis
      redis-exporter
      sidekiq
      puma
      gitaly
    ).map { |svc| stub_should_notify?(svc, true) }

    allow_any_instance_of(OmnibusHelper).to receive(:should_notify?).and_call_original
  end

  describe 'gitlab_suggested_reviewers_secret' do
    let(:templatesymlink) do
      chef_run.templatesymlink('Create a gitlab_suggested_reviewers_secret and create a symlink to Rails root')
    end

    shared_examples 'Create suggested reviewer secrets and notifies services' do
      it 'creates gitlab_suggested_reviewers_secret template' do
        expect(templatesymlink.action).to include(:create)
        expect(templatesymlink.variables[:secret_token]).to eq(api_secret_key)
      end

      it 'gitlab_suggested_reviewers_secret template triggers notifications' do
        expect(templatesymlink).to notify('runit_service[puma]').to(:restart).delayed
        expect(templatesymlink).to notify('sidekiq_service[sidekiq]').to(:restart).delayed
      end
    end

    context 'by default' do
      let(:api_secret_key) { Gitlab['suggested_reviewers']['api_secret_key'] }

      it_behaves_like 'Create suggested reviewer secrets and notifies services'
    end

    context 'with specific gitlab_suggested_reviewers_secret' do
      let(:api_secret_key) { SecureRandom.base64(32) }

      before do
        stub_gitlab_rb(
          suggested_reviewers: {
            api_secret_key: api_secret_key
          }
        )
      end

      it_behaves_like 'Create suggested reviewer secrets and notifies services'
    end
  end
end
