# frozen_string_literal: true

require 'chef_helper'

RSpec.describe 'postgresql::bin' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }
  let(:gitlab_psql_rc) do
    <<-EOF
psql_user='gitlab-psql'
psql_group='gitlab-psql'
psql_host='/var/opt/gitlab/postgresql'
psql_port='5432'
    EOF
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when bundled postgresql is disabled' do
    before do
      stub_gitlab_rb(
        postgresql: {
          enable: false
        }
      )

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/var/opt/gitlab/postgresql/data/PG_VERSION').and_return(false)

      allow_any_instance_of(PgHelper).to receive(:database_version).and_return(nil)
      version = double("PgHelper", major: 10, minor: 9)
      allow_any_instance_of(PgHelper).to receive(:version).and_return(version)
    end

    it 'still includes the postgresql::bin recipe' do
      expect(chef_run).to include_recipe('postgresql::bin')
    end

    it 'includes postgresql::directory_locations' do
      expect(chef_run).to include_recipe('postgresql::directory_locations')
    end

    it 'creates gitlab-psql-rc' do
      expect(chef_run).to render_file('/opt/gitlab/etc/gitlab-psql-rc')
                            .with_content(gitlab_psql_rc)
    end

    # We do expect the ruby block to run, but nothing to be found
    it "doesn't link any files by default" do
      expect(FileUtils).to_not receive(:ln_sf)
    end

    context "with postgresql['version'] set" do
      before do
        stub_gitlab_rb(
          postgresql: {
            enable: false,
            version: '999'
          }
        )
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/999*").and_return(
          %w(
            /opt/gitlab/embedded/postgresql/999
          )
        )
        allow(Dir).to receive(:glob).with("/opt/gitlab/embedded/postgresql/999/bin/*").and_return(
          %w(
            /opt/gitlab/embedded/postgresql/999/bin/foo_one
            /opt/gitlab/embedded/postgresql/999/bin/foo_two
            /opt/gitlab/embedded/postgresql/999/bin/foo_three
          )
        )
      end

      it "doesn't print a warning with a valid postgresql version" do
        expect(chef_run).to_not run_ruby_block('check_postgresql_version')
      end

      it 'links the specified version' do
        allow(FileUtils).to receive(:ln_sf).and_return(true)
        %w(foo_one foo_two foo_three).each do |pg_bin|
          expect(FileUtils).to receive(:ln_sf).with(
            "/opt/gitlab/embedded/postgresql/999/bin/#{pg_bin}",
            "/opt/gitlab/embedded/bin/#{pg_bin}"
          )
        end
        chef_run.ruby_block('Link postgresql bin files to the correct version').block.call
      end
    end

    context "with an invalid version in postgresql['version']" do
      before do
        stub_gitlab_rb(
          postgresql: {
            enable: false,
            version: '888'
          }
        )
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with('/opt/gitlab/embedded/postgresql/888*').and_return([])
      end

      it 'should print a warning' do
        expect(chef_run).to run_ruby_block('check_postgresql_version')
      end
    end
  end
end
