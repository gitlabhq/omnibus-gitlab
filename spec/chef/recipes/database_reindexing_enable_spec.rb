require 'chef_helper'

RSpec.describe 'gitlab::database-reindexing' do
  let(:chef_run) { converge_config('gitlab::database_reindexing_enable') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'with defaults' do
    before do
      stub_gitlab_rb(gitlab_rails: { database_reindexing: { enable: true } })
    end

    it 'enables crond' do
      expect(chef_run).to include_recipe('crond::enable')
    end

    it 'adds a crond_job with default schedule' do
      expect(chef_run).to create_crond_job('database-reindexing').with(
        user: "root",
        hour: '*',
        minute: 0,
        month: '*',
        day_of_month: '*',
        day_of_week: '0,6',
        command: "/opt/gitlab/bin/gitlab-rake gitlab:db:reindex"
      )
    end
  end

  context 'with specific schedule' do
    let(:config) do
      {
        enable: true,
        hour: 10,
        minute: 5,
        month: 3,
        day_of_month: 2,
        day_of_week: 1
      }
    end

    it 'adds a crond_job with the configured schedule' do
      stub_gitlab_rb(gitlab_rails: { database_reindexing: config })

      expect(chef_run).to create_crond_job('database-reindexing').with(
        user: "root",
        hour: 10,
        minute: 5,
        month: 3,
        day_of_week: 1,
        command: "/opt/gitlab/bin/gitlab-rake gitlab:db:reindex"
      )
    end
  end
end
