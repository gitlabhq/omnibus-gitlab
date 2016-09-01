require 'chef_helper'

describe 'postgresql' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before { allow(Gitlab).to receive(:[]).and_call_original }

  context 'with default settings' do
    it 'correctly sets the shared_preload_libraries default setting' do
      expect(chef_run.node['gitlab']['postgresql']['shared_preload_libraries'])
        .to be_nil

      expect(chef_run).to render_file('/var/opt/gitlab/postgresql/data/postgresql.conf')
        .with_content(/shared_preload_libraries = ''/)
    end

    it 'correctly sets the log_line_prefix default setting' do
      expect(chef_run.node['gitlab']['postgresql']['log_line_prefix'])
        .to be_nil

      expect(chef_run).to render_file('/var/opt/gitlab/postgresql/data/postgresql.conf')
        .with_content(/log_line_prefix = ''/)
    end
  end

  context 'when user settings are set' do
    before do
      stub_gitlab_rb(postgresql: {
        shared_preload_libraries: 'pg_stat_statements',
        log_line_prefix: '%a'
        })
    end

    it 'correctly sets the shared_preload_libraries setting' do
      expect(chef_run.node['gitlab']['postgresql']['shared_preload_libraries'])
        .to eql('pg_stat_statements')

      expect(chef_run).to render_file('/var/opt/gitlab/postgresql/data/postgresql.conf')
        .with_content(/shared_preload_libraries = 'pg_stat_statements'/)
    end

    it 'correctly sets the log_line_prefix setting' do
      expect(chef_run.node['gitlab']['postgresql']['log_line_prefix'])
        .to eql('%a')

      expect(chef_run).to render_file('/var/opt/gitlab/postgresql/data/postgresql.conf')
        .with_content(/log_line_prefix = '%a'/)
    end
  end
end
