require 'chef_helper'

describe 'postgresql 9.2' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(PgHelper).to receive(:version).and_return('9.2.18')
    allow_any_instance_of(PgHelper).to receive(:database_version).and_return('9.2')
  end

  it 'includes the postgresql-bin recipe' do
    expect(chef_run).to include_recipe('gitlab::postgresql-bin')
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

    it 'sets checkpoint_segments' do
      expect(chef_run.node['gitlab']['postgresql']['checkpoint_segments'])
        .to eq(10)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/postgresql/data/postgresql.conf'
      ).with_content(/checkpoint_segments = 10/)
    end

    it 'sets max_standby settings' do
      expect(chef_run).to render_file(
        '/var/opt/gitlab/postgresql/data/postgresql.conf'
      ).with_content(/max_standby_archive_delay = 30s/)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/postgresql/data/postgresql.conf'
      ).with_content(/max_standby_streaming_delay = 30s/)
    end

    it 'sets archive settings' do
      expect(chef_run).to render_file(
        '/var/opt/gitlab/postgresql/data/postgresql.conf'
      ).with_content(/archive_mode = off/)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/postgresql/data/postgresql.conf'
      ).with_content(/archive_command = ''/)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/postgresql/data/postgresql.conf'
      ).with_content(/archive_timeout = 60/)
    end

    it 'does not set the max_replication_slots setting' do
      expect(chef_run).to render_file(
        '/var/opt/gitlab/postgresql/data/postgresql.conf'
      ).with_content { |content|
        expect(content).to_not match(/max_replication_slots = /)
      }
    end
  end

  context 'when user settings are set' do
    before do
      stub_gitlab_rb(postgresql: {
        shared_preload_libraries: 'pg_stat_statements',
        log_line_prefix: '%a',
        max_standby_archive_delay: '60s',
        max_standby_streaming_delay: '120s',
        archive_mode: 'on',
        archive_command: 'command',
        archive_timeout: '120',
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

    it 'sets max_standby settings' do
      expect(chef_run).to render_file(
        '/var/opt/gitlab/postgresql/data/postgresql.conf'
      ).with_content(/max_standby_archive_delay = 60s/)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/postgresql/data/postgresql.conf'
      ).with_content(/max_standby_streaming_delay = 120s/)
    end

    it 'sets archive settings' do
      expect(chef_run).to render_file(
        '/var/opt/gitlab/postgresql/data/postgresql.conf'
      ).with_content(/archive_mode = on/)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/postgresql/data/postgresql.conf'
      ).with_content(/archive_command = 'command'/)
      expect(chef_run).to render_file(
        '/var/opt/gitlab/postgresql/data/postgresql.conf'
      ).with_content(/archive_timeout = 120/)
    end
  end

  context 'version specific settings' do
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

    context 'running version differs from data version' do
      before do
        allow_any_instance_of(PgHelper).to receive(:version).and_return('9.6.1')
        allow(File).to receive(:exists?).and_call_original
        allow(File).to receive(:exists?).with("/var/opt/gitlab/postgresql/data/PG_VERSION").and_return(true)
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/9.2*").and_return(
          ['/opt/gitlab/embedded/postgresql/9.2.18']
        )
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/9.2.18/bin/*").and_return(
          %w(
            /opt/gitlab/embedded/postgresql/9.2.18/bin/foo_one
            /opt/gitlab/embedded/postgresql/9.2.18/bin/foo_two
            /opt/gitlab/embedded/postgresql/9.2.18/bin/foo_three
          )
        )
      end

      it 'corrects symlinks to the correct location' do
        allow(FileUtils).to receive(:ln_sf).and_return(true)
        %w(foo_one foo_two foo_three).each do |pg_bin|
          expect(FileUtils).to receive(:ln_sf).with(
            "/opt/gitlab/embedded/postgresql/9.2.18/bin/#{pg_bin}",
            "/opt/gitlab/embedded/bin/#{pg_bin}"
          )
        end
        chef_run.ruby_block('Link postgresql bin files to the correct version').old_run_action(:run)
      end
    end
  end
end

describe 'postgresql 9.6' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow_any_instance_of(PgHelper).to receive(:version).and_return('9.6.1')
    allow_any_instance_of(PgHelper).to receive(:database_version).and_return('9.6')
  end

  context 'version specific settings' do
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

    it 'sets the max_replication_slots setting' do
      expect(chef_run.node['gitlab']['postgresql']['max_replication_slots'])
        .to eq(0)

      expect(chef_run).to render_file(
        '/var/opt/gitlab/postgresql/data/postgresql.conf'
      ).with_content(/max_replication_slots = 0/)
    end

    context 'running version differs from data version' do
      before do
        allow_any_instance_of(PgHelper).to receive(:version).and_return('9.2.18')
        allow(File).to receive(:exists?).and_call_original
        allow(File).to receive(:exists?).with("/var/opt/gitlab/postgresql/data/PG_VERSION").and_return(true)
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/9.6*").and_return(
          ['/opt/gitlab/embedded/postgresql/9.6.1']
        )
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/9.6.1/bin/*").and_return(
          %w(
            /opt/gitlab/embedded/postgresql/9.6.1/bin/foo_one
            /opt/gitlab/embedded/postgresql/9.6.1/bin/foo_two
            /opt/gitlab/embedded/postgresql/9.6.1/bin/foo_three
          )
        )
      end

      it 'corrects symlinks to the correct location' do
        allow(FileUtils).to receive(:ln_sf).and_return(true)
        %w(foo_one foo_two foo_three).each do |pg_bin|
          expect(FileUtils).to receive(:ln_sf).with(
            "/opt/gitlab/embedded/postgresql/9.6.1/bin/#{pg_bin}",
            "/opt/gitlab/embedded/bin/#{pg_bin}"
          )
        end
        chef_run.ruby_block('Link postgresql bin files to the correct version').old_run_action(:run)
      end
    end
  end
end
