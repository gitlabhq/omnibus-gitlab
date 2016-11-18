require 'chef_helper'

describe 'gitlab::gitlab-rails' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when manage-storage-directories is disabled' do
    before do
      stub_gitlab_rb(gitlab_rails: { shared_path: '/tmp/shared' }, manage_storage_directories: { enable: false })
    end

    it 'does not create the shared directory' do
      expect(chef_run).to_not run_ruby_block('directory resource: /tmp/shared')
    end

    it 'does not create the artifacts directory' do
      expect(chef_run).to_not run_ruby_block('directory resource: /tmp/shared/artifacts')
    end

    it 'does not create the lfs storage directory' do
      expect(chef_run).to_not run_ruby_block('directory resource: /tmp/shared/lfs-objects')
    end

    it 'does not create the uploads storage directory' do
      stub_gitlab_rb(gitlab_rails: { uploads_directory: '/tmp/uploads' })
      expect(chef_run).to_not run_ruby_block('directory resource: /tmp/uploads')
    end

    it 'does not create the ci builds directory' do
      stub_gitlab_rb(gitlab_ci: { builds_directory: '/tmp/builds' })
      expect(chef_run).to_not run_ruby_block('directory resource: /tmp/builds')
    end

    it 'does not create the GitLab pages directory' do
      expect(chef_run).to_not run_ruby_block('directory resource: /tmp/shared/pages')
    end
  end

  context 'when manage-storage-directories is enabled' do
    before do
      stub_gitlab_rb(gitlab_rails: { shared_path: '/tmp/shared' } )
    end

    it 'creates the shared directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/shared')
    end

    it 'creates the artifacts directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/shared/artifacts')
    end

    it 'creates the lfs storage directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/shared/lfs-objects')
    end

    it 'creates the uploads directory' do
      stub_gitlab_rb(gitlab_rails: { uploads_directory: '/tmp/uploads' })
      expect(chef_run).to run_ruby_block('directory resource: /tmp/uploads')
    end

    it 'creates the ci builds directory' do
      stub_gitlab_rb(gitlab_ci: { builds_directory: '/tmp/builds' })
      expect(chef_run).to run_ruby_block('directory resource: /tmp/builds')
    end

    it 'creates the GitLab pages directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/shared/pages')
    end
  end

  context 'with redis settings' do
    let(:config_file) { '/var/opt/gitlab/gitlab-rails/etc/resque.yml' }

    context 'and default configuration' do
      it 'creates the config file with the required redis settings' do
        expect(chef_run).to render_file(config_file)
                              .with_content(%r{url: unix:/var/opt/gitlab/redis/redis.socket})
      end
    end

    context 'and custom configuration' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: 'redis.example.com',
            redis_port: 8888,
            redis_database: 2,
            redis_password: 'mypass'
          }
        )
      end

      it 'creates the config file with custom host, port, password and database' do
        expect(chef_run).to render_file(config_file)
                              .with_content(%r{url: redis://:mypass@redis.example.com:8888/2})
      end
    end
  end

  context 'with environment variables' do
    context 'by default' do
      it_behaves_like "enabled gitlab-rails env", "HOME", '\/var\/opt\/gitlab'
      it_behaves_like "enabled gitlab-rails env", "RAILS_ENV", 'production'
      it_behaves_like "enabled gitlab-rails env", "SIDEKIQ_MEMORY_KILLER_MAX_RSS", '1000000'
      it_behaves_like "enabled gitlab-rails env", "BUNDLE_GEMFILE", '\/opt\/gitlab\/embedded\/service\/gitlab-rails\/Gemfile'
      it_behaves_like "enabled gitlab-rails env", "PATH", '\/opt\/gitlab\/bin:\/opt\/gitlab\/embedded\/bin:\/bin:\/usr\/bin'
      it_behaves_like "enabled gitlab-rails env", "ICU_DATA", '\/opt\/gitlab\/embedded\/share\/icu\/current'
      it_behaves_like "enabled gitlab-rails env", "PYTHONPATH", '\/opt\/gitlab\/embedded\/lib\/python3.4\/site-packages'

      it_behaves_like "enabled gitlab-rails env", "LD_PRELOAD", '\/opt\/gitlab\/embedded\/lib\/libjemalloc.so'

      context 'when a custom env variable is specified' do
        before do
          stub_gitlab_rb(gitlab_rails: { env: { 'IAM' => 'CUSTOMVAR'}})
        end

        it_behaves_like "enabled gitlab-rails env", "IAM", 'CUSTOMVAR'
        it_behaves_like "enabled gitlab-rails env", "ICU_DATA", '\/opt\/gitlab\/embedded\/share\/icu\/current'

        it_behaves_like "enabled gitlab-rails env", "LD_PRELOAD", '\/opt\/gitlab\/embedded\/lib\/libjemalloc.so'
      end
    end

    context 'when jemalloc is disabled' do
      before do
        stub_gitlab_rb(gitlab_rails: { enable_jemalloc: false })
      end

      it_behaves_like "disabled gitlab-rails env", "LD_PRELOAD", '\/opt\/gitlab\/embedded\/lib\/libjemalloc.so'
    end
  end

  describe "with symlinked templates" do
    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default') }

    before do
      %w(unicorn sidekiq gitlab-workhorse postgresql redis nginx logrotate).map { |svc| stub_should_notify?(svc, true)}
    end

    describe 'database.yml' do
      let(:templatesymlink_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/database.yml') }
      let(:templatesymlink_link) { chef_run.link("Link /opt/gitlab/embedded/service/gitlab-rails/config/database.yml to /var/opt/gitlab/gitlab-rails/etc/database.yml") }

      context 'by default' do
        it 'creates the template' do
          expect(chef_run).to create_template('/var/opt/gitlab/gitlab-rails/etc/database.yml')
            .with(
              owner: 'root',
              group: 'root',
              mode: '0644',
            )
          expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/host: \'\/var\/opt\/gitlab\/postgresql\'/)
          expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/database: gitlabhq_production/)
        end

        it 'template triggers notifications' do
          expect(templatesymlink_template).to notify('service[unicorn]').to(:restart).delayed
          expect(templatesymlink_template).to notify('service[sidekiq]').to(:restart).delayed
          expect(templatesymlink_template).to_not notify('service[gitlab-workhorse]').to(:restart).delayed
          expect(templatesymlink_template).to_not notify('service[nginx]').to(:restart).delayed
        end

        it 'creates the symlink' do
          expect(chef_run).to create_link("Link /opt/gitlab/embedded/service/gitlab-rails/config/database.yml to /var/opt/gitlab/gitlab-rails/etc/database.yml")
        end

        it 'linking triggers notifications' do
          expect(templatesymlink_link).to notify('service[unicorn]').to(:restart).delayed
          expect(templatesymlink_link).to notify('service[sidekiq]').to(:restart).delayed
          expect(templatesymlink_link).to_not notify('service[gitlab-workhorse]').to(:restart).delayed
          expect(templatesymlink_link).to_not notify('service[nginx]').to(:restart).delayed
        end
      end

      context 'with specific database settings' do
        context 'when multiple postgresql listen_address is used' do
          before do
            stub_gitlab_rb(postgresql: { listen_address: "127.0.0.1,1.1.1.1" })
          end

          it 'creates the postgres configuration file with multi listen_address and database.yml file with one host' do
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/host: '127.0.0.1'/)
            expect(chef_run).to render_file('/var/opt/gitlab/postgresql/data/postgresql.conf').with_content(/listen_addresses = '127.0.0.1,1.1.1.1'/)
          end
        end

        context 'when no postgresql listen_address is used' do
          it 'creates the postgres configuration file with empty listen_address and database.yml file with default one' do
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/host: '\/var\/opt\/gitlab\/postgresql'/)
            expect(chef_run).to render_file('/var/opt/gitlab/postgresql/data/postgresql.conf').with_content(/listen_addresses = ''/)
          end
        end

        context 'when one postgresql listen_address is used' do
          before do
            stub_gitlab_rb(postgresql: { listen_address: "127.0.0.1" })
          end

          it 'creates the postgres configuration file with one listen_address and database.yml file with one host' do
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/host: '127.0.0.1'/)
            expect(chef_run).to render_file('/var/opt/gitlab/postgresql/data/postgresql.conf').with_content(/listen_addresses = '127.0.0.1'/)
          end

          it 'template triggers notifications' do
            expect(templatesymlink_template).to notify('service[unicorn]').to(:restart).delayed
            expect(templatesymlink_template).to notify('service[sidekiq]').to(:restart).delayed
            expect(templatesymlink_template).to_not notify('service[gitlab-workhorse]').to(:restart).delayed
            expect(templatesymlink_template).to_not notify('service[nginx]').to(:restart).delayed
          end

          it 'creates the symlink' do
            expect(chef_run).to create_link("Link /opt/gitlab/embedded/service/gitlab-rails/config/database.yml to /var/opt/gitlab/gitlab-rails/etc/database.yml")
          end

          it 'linking triggers notifications' do
            expect(templatesymlink_link).to notify('service[unicorn]').to(:restart).delayed
            expect(templatesymlink_link).to notify('service[sidekiq]').to(:restart).delayed
            expect(templatesymlink_link).to_not notify('service[gitlab-workhorse]').to(:restart).delayed
            expect(templatesymlink_link).to_not notify('service[nginx]').to(:restart).delayed
          end
        end
      end
    end


    describe 'gitlab_workhorse_secret' do
      let(:templatesymlink_template) { chef_run.template('/var/opt/gitlab/gitlab-rails/etc/gitlab_workhorse_secret') }
      let(:templatesymlink_link) { chef_run.link("Link /opt/gitlab/embedded/service/gitlab-rails/.gitlab_workhorse_secret to /var/opt/gitlab/gitlab-rails/etc/gitlab_workhorse_secret") }

      context 'by default' do
        it 'creates the template' do
          expect(chef_run).to create_template('/var/opt/gitlab/gitlab-rails/etc/gitlab_workhorse_secret')
            .with(
              owner: 'root',
              group: 'root',
              mode: '0644',
            )
        end

        it 'template triggers notifications' do
          expect(templatesymlink_template).to notify('service[gitlab-workhorse]').to(:restart).delayed
          expect(templatesymlink_template).to notify('service[unicorn]').to(:restart).delayed
          expect(templatesymlink_template).to notify('service[sidekiq]').to(:restart).delayed
        end

        it 'creates the symlink' do
          expect(chef_run).to create_link("Link /opt/gitlab/embedded/service/gitlab-rails/.gitlab_workhorse_secret to /var/opt/gitlab/gitlab-rails/etc/gitlab_workhorse_secret")
        end

        it 'linking triggers notifications' do
          expect(templatesymlink_link).to notify('service[gitlab-workhorse]').to(:restart).delayed
          expect(templatesymlink_link).to notify('service[unicorn]').to(:restart).delayed
          expect(templatesymlink_link).to notify('service[sidekiq]').to(:restart).delayed
        end
      end

      context 'with specific gitlab_workhorse_secret' do
        before do
          stub_gitlab_rb(gitlab_workhorse: { secret_token: 'abc123-gitlab-workhorse' })
        end

        it 'renders the correct node attribute' do
          expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/gitlab_workhorse_secret')
            .with_content('abc123-gitlab-workhorse')
        end

        it 'uses the correct owner and permissions' do
          expect(chef_run).to create_template('/var/opt/gitlab/gitlab-rails/etc/gitlab_workhorse_secret')
            .with(
              owner: 'root',
              group: 'root',
              mode: '0644',
            )
        end

        it 'template triggers notifications' do
          expect(templatesymlink_template).to notify('service[gitlab-workhorse]').to(:restart).delayed
          expect(templatesymlink_template).to notify('service[unicorn]').to(:restart).delayed
          expect(templatesymlink_template).to notify('service[sidekiq]').to(:restart).delayed
        end

        it 'creates the symlink' do
          expect(chef_run).to create_link("Link /opt/gitlab/embedded/service/gitlab-rails/.gitlab_workhorse_secret to /var/opt/gitlab/gitlab-rails/etc/gitlab_workhorse_secret")
        end

        it 'linking triggers notifications' do
          expect(templatesymlink_link).to notify('service[gitlab-workhorse]').to(:restart).delayed
          expect(templatesymlink_link).to notify('service[unicorn]').to(:restart).delayed
          expect(templatesymlink_link).to notify('service[sidekiq]').to(:restart).delayed
        end
      end
    end
  end
end
