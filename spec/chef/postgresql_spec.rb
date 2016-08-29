require 'chef_helper'

describe 'postgresql' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before { allow(Gitlab).to receive(:[]).and_call_original }

  context 'when shared_preload_libraries is nil' do
    before do
      stub_gitlab_rb(
        "postgresql" => { shared_preload_libraries: nil}
      )
    end

    it 'correctly sets the shared_preload_libraries setting' do
      expect(chef_run.node['gitlab']['postgresql']['shared_preload_libraries'])
        .to be_nil
    end

  end

  context 'when shared_preload_libraries is pg_stat_statements' do
    before do
      stub_gitlab_rb(
        "postgresql" => { shared_preload_libraries: 'pg_stat_statements'}
      )
    end

    it 'correctly sets the shared_preload_libraries setting' do
      expect(chef_run.node['gitlab']['postgresql']['shared_preload_libraries'])
        .to eql('pg_stat_statements')
    end

  end

end
