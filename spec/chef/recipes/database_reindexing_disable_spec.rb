require 'chef_helper'

RSpec.describe 'gitlab::database-reindexing' do
  let(:chef_run) { converge_config('gitlab::database_reindexing_disable') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'removes the database-reindexing cronjob' do
    expect(chef_run).to delete_crond_job('database-reindexing')
  end
end
