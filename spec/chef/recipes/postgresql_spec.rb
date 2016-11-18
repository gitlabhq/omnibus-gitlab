require 'chef_helper'

describe 'postgresql 9.2' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(PgHelper).to receive(:version).and_return("9.2.18")
  end

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

  it 'sets unix_socket_directory' do
    expect(chef_run.node['gitlab']['postgresql']['unix_socket_directory'])
      .to eq('/var/opt/gitlab/postgresql')
    expect(chef_run.node['gitlab']['postgresql']['unix_socket_directories'])
      .to eq(nil)
    expect(chef_run).to render_file(
      '/var/opt/gitlab/postgresql/data/postgresql.conf'
    ).with_content { |content|
      expect(content).to match(
        /unix_socket_directory = '\/var\/opt\/gitlab\/postgresql'/
      )
      expect(content).not_to match(
        /unix_socket_directories = '\/var\/opt\/gitlab\/postgresql'/
      )
    }
  end

  it 'sets checkpoint_segments' do
    expect(chef_run.node['gitlab']['postgresql']['checkpoint_segments'])
      .to eq(10)
    expect(chef_run).to render_file(
      '/var/opt/gitlab/postgresql/data/postgresql.conf'
    ).with_content(/checkpoint_segments = 10/)
  end
end

describe 'postgresl 9.6' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'sets unix_socket_directories' do
    expect(chef_run.node['gitlab']['postgresql']['unix_socket_directory'])
      .to eq('/var/opt/gitlab/postgresql')
    expect(chef_run).to render_file(
      '/var/opt/gitlab/postgresql/data/postgresql.conf'
    ).with_content { |content|
      expect(content).to match(
        /unix_socket_directories = '\/var\/opt\/gitlab\/postgresql'/
      )
      expect(content).not_to match(
        /unix_socket_directory = '\/var\/opt\/gitlab\/postgresql'/
      )
    }
  end

  it 'does not set checkpoint_segments' do
    expect(chef_run).not_to render_file(
      '/var/opt/gitlab/postgresql/data/postgresql.conf'
    ).with_content(/checkpoint_segments = 10/)
  end
end
