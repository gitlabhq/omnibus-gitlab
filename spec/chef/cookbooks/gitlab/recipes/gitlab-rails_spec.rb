require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax

  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink runit_service)).converge('gitlab::default') }
  let(:redis_instances) { %w(cache queues shared_state trace_chunks rate_limiting sessions) }
  let(:config_dir) { '/var/opt/gitlab/gitlab-rails/etc/' }
  let(:default_vars) do
    {
      'HOME' => '/var/opt/gitlab',
      'RAILS_ENV' => 'production',
      'SIDEKIQ_MEMORY_KILLER_MAX_RSS' => '2000000',
      'BUNDLE_GEMFILE' => '/opt/gitlab/embedded/service/gitlab-rails/Gemfile',
      'PATH' => '/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin',
      'ICU_DATA' => '/opt/gitlab/embedded/share/icu/current',
      'PYTHONPATH' => '/opt/gitlab/embedded/lib/python3.9/site-packages',
      'EXECJS_RUNTIME' => 'Disabled',
      'TZ' => ':/etc/localtime',
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
      'SSL_CERT_FILE' => '/opt/gitlab/embedded/ssl/cert.pem',
      'PUMA_WORKER_MAX_MEMORY' => nil
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(File).to receive(:symlink?).and_call_original
  end

  context 'with defaults' do
    it 'creates a default VERSION file and restarts services' do
      expect(chef_run).to create_version_file('Create version file for Rails').with(
        version_file_path: '/var/opt/gitlab/gitlab-rails/RUBY_VERSION',
        version_check_cmd: '/opt/gitlab/embedded/bin/ruby --version'
      )

      dependent_services = []
      dependent_services.each do |svc|
        expect(chef_run.version_file('Create version file for Rails')).to notify("runit_service[#{svc}]").to(:restart)
      end
    end
  end

  context 'when manage-storage-directories is disabled' do
    cached(:chef_run) do
      RSpec::Mocks.with_temporary_scope do
        stub_gitlab_rb(gitlab_rails: { shared_path: '/tmp/shared',
                                       uploads_directory: '/tmp/uploads',
                                       uploads_storage_path: '/tmp/uploads_storage' },
                       gitlab_ci: { builds_directory: '/tmp/builds' },
                       git_data_dirs: {
                         "some_storage" => {
                           "path" => "/tmp/git-data"
                         }
                       },
                       manage_storage_directories: { enable: false })
      end

      ChefSpec::SoloRunner.new.converge('gitlab::default')
    end

    it 'does not create the git-data directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/git-data')
    end

    it 'does not create the repositories directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/git-data/repositories')
    end

    it 'does not create the shared directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared')
    end

    it 'does not create the artifacts directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared/artifacts')
    end

    it 'does not create the external-diffs directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared/external-diffs')
    end

    it 'does not create the lfs storage directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared/lfs-objects')
    end

    it 'does not create the packages storage directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared/packages')
    end

    it 'does not create the dependency_proxy storage directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared/dependency_proxy')
    end

    it 'does not create the terraform_state storage directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared/terraform_state')
    end

    it 'does not create the ci_secure_files storage directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared/ci_secure_files')
    end

    it 'does not create the GitLab pages directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared/pages')
    end

    it 'does not create the uploads directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/uploads')
    end

    it 'does not create the ci builds directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/builds')
    end

    it 'does not create the uploads storage directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/uploads_storage')
    end
  end

  context 'when manage-storage-directories is enabled' do
    cached(:chef_run) do
      RSpec::Mocks.with_temporary_scope do
        stub_gitlab_rb(gitlab_rails: { shared_path: '/tmp/shared',
                                       uploads_directory: '/tmp/uploads',
                                       uploads_storage_path: '/tmp/uploads_storage' },
                       gitlab_ci: { builds_directory: '/tmp/builds' },
                       git_data_dirs: {
                         "some_storage" => {
                           "path" => "/tmp/git-data"
                         }
                       })
      end

      ChefSpec::SoloRunner.converge('gitlab::default')
    end

    it 'creates the git-data directory' do
      expect(chef_run).to create_storage_directory('/tmp/git-data').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the repositories directory' do
      expect(chef_run).to create_storage_directory('/tmp/git-data/repositories').with(owner: 'git', group: 'git', mode: '2770')
    end

    it 'creates the shared directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared').with(owner: 'git', group: 'gitlab-www', mode: '0751')
    end

    it 'creates the artifacts directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared/artifacts').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the external-diffs directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared/external-diffs').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the lfs storage directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared/lfs-objects').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the packages directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared/packages').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the dependency_proxy directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared/dependency_proxy').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the terraform_state directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared/terraform_state').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the ci_secure_files directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared/ci_secure_files').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the encrypted_settings directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared/encrypted_settings').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the GitLab pages directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared/pages').with(owner: 'git', group: 'gitlab-www', mode: '0750')
    end

    it 'creates the shared tmp directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared/tmp').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the shared cache directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared/cache').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the uploads directory' do
      expect(chef_run).to create_storage_directory('/tmp/uploads').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the ci builds directory' do
      expect(chef_run).to create_storage_directory('/tmp/builds').with(owner: 'git', group: 'git', mode: '0700')
    end

    it 'creates the uploads storage directory' do
      expect(chef_run).to create_storage_directory('/tmp/uploads_storage').with(owner: 'git', group: 'git', mode: '0700')
    end
  end

  context 'when uploads storage directory is not specified' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.converge('gitlab::default')
    end

    it 'does not create the uploads storage directory' do
      expect(chef_run).not_to create_storage_directory('/opt/gitlab/embedded/service/gitlab-rails/public')
    end
  end

  context 'with redis settings' do
    let(:config_file) { '/var/opt/gitlab/gitlab-rails/etc/resque.yml' }
    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default') }

    context 'and default configuration' do
      it 'creates the config file with the required redis settings' do
        expect(chef_run).to create_templatesymlink('Create a resque.yml and create a symlink to Rails root').with_variables(
          hash_including(
            redis_url: URI('unix:/var/opt/gitlab/redis/redis.socket'),
            redis_sentinels: [],
            redis_enable_client: true
          )
        )

        expect(chef_run).to render_file(config_file).with_content { |content|
          expect(content).to match(%r(url: unix:/var/opt/gitlab/redis/redis.socket$))
          expect(content).not_to match(/id:/)
        }
      end

      it 'creates cable.yml with the same settings' do
        expect(chef_run).to create_templatesymlink('Create a cable.yml and create a symlink to Rails root').with_variables(
          hash_including(
            redis_url: URI('unix:/var/opt/gitlab/redis/redis.socket'),
            redis_sentinels: [],
            redis_enable_client: true
          )
        )

        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/cable.yml').with_content { |content|
          expect(content).to match(%r(url: unix:/var/opt/gitlab/redis/redis.socket$))
        }
      end

      it 'does not render the separate instance configurations' do
        redis_instances.each do |instance|
          expect(chef_run).not_to render_file("#{config_dir}redis.#{instance}.yml")
        end
      end

      it 'deletes the separate instance config files' do
        redis_instances.each do |instance|
          expect(chef_run).to delete_link("/opt/gitlab/embedded/service/gitlab-rails/config/redis.#{instance}.yml")
          expect(chef_run).to delete_file("/var/opt/gitlab/gitlab-rails/etc/redis.#{instance}.yml")
        end
      end
    end

    context 'and custom configuration' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_host: 'redis.example.com',
            redis_port: 8888,
            redis_database: 2,
            redis_password: 'mypass',
            redis_enable_client: false
          }
        )
      end

      it 'creates the config file with custom host, port, password and database' do
        expect(chef_run).to create_templatesymlink('Create a resque.yml and create a symlink to Rails root').with_variables(
          hash_including(
            redis_url: URI('redis://:mypass@redis.example.com:8888/2'),
            redis_sentinels: [],
            redis_enable_client: false
          )
        )

        expect(chef_run).to render_file(config_file).with_content { |content|
          expect(content).to match(%r(url: redis://:mypass@redis.example.com:8888/2))
          expect(content).to match(/id:$/)
        }
      end

      it 'creates cable.yml with custom host, port, password and database' do
        expect(chef_run).to create_templatesymlink('Create a cable.yml and create a symlink to Rails root').with_variables(
          hash_including(
            redis_url: URI('redis://:mypass@redis.example.com:8888/2'),
            redis_sentinels: [],
            redis_enable_client: false
          )
        )

        expect(chef_run).to render_file(config_file).with_content { |content|
          expect(content).to match(%r(url: redis://:mypass@redis.example.com:8888/2))
          expect(content).to match(/id:$/)
        }
      end
    end

    context 'with multiple instances' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            redis_enable_client: false,
            redis_cache_instance: "redis://:fakepass@fake.redis.cache.com:8888/2",
            redis_cache_sentinels: [
              { host: 'cache', port: '1234' },
              { host: 'cache', port: '3456' }
            ],
            redis_queues_instance: "redis://:fakepass@fake.redis.queues.com:8888/2",
            redis_queues_sentinels: [
              { host: 'queues', port: '1234' },
              { host: 'queues', port: '3456' }
            ],
            redis_shared_state_instance: "redis://:fakepass@fake.redis.shared_state.com:8888/2",
            redis_shared_state_sentinels: [
              { host: 'shared_state', port: '1234' },
              { host: 'shared_state', port: '3456' }
            ],
            redis_trace_chunks_instance: "redis://:fakepass@fake.redis.trace_chunks.com:8888/2",
            redis_trace_chunks_sentinels: [
              { host: 'trace_chunks', port: '1234' },
              { host: 'trace_chunks', port: '3456' }
            ],
            redis_rate_limiting_instance: "redis://:fakepass@fake.redis.rate_limiting.com:8888/2",
            redis_rate_limiting_sentinels: [
              { host: 'rate_limiting', port: '1234' },
              { host: 'rate_limiting', port: '3456' }
            ],
            redis_sessions_instance: "redis://:fakepass@fake.redis.sessions.com:8888/2",
            redis_sessions_sentinels: [
              { host: 'sessions', port: '1234' },
              { host: 'sessions', port: '3456' }
            ],
            redis_actioncable_instance: "redis://:fakepass@fake.redis.actioncable.com:8888/2",
            redis_actioncable_sentinels: [
              { host: 'actioncable', port: '1234' },
              { host: 'actioncable', port: '3456' }
            ]
          }
        )
      end

      it 'render separate config files' do
        redis_instances.each do |instance|
          expect(chef_run).to create_templatesymlink("Create a redis.#{instance}.yml and create a symlink to Rails root").with_variables(
            redis_url: "redis://:fakepass@fake.redis.#{instance}.com:8888/2",
            redis_sentinels: [{ "host" => instance, "port" => "1234" }, { "host" => instance, "port" => "3456" }],
            redis_enable_client: false
          )
          expect(chef_run).not_to delete_file("/var/opt/gitlab/gitlab-rails/etc/redis.#{instance}.yml")
        end
      end

      it 'still renders the default configuration file' do
        expect(chef_run).to create_templatesymlink('Create a resque.yml and create a symlink to Rails root')
      end

      it 'creates cable.yml with custom settings' do
        expect(chef_run).to create_templatesymlink('Create a cable.yml and create a symlink to Rails root').with_variables(
          hash_including(
            redis_url: "redis://:fakepass@fake.redis.actioncable.com:8888/2",
            redis_sentinels: [{ 'host' => 'actioncable', 'port' => '1234' }, { 'host' => 'actioncable', 'port' => '3456' }],
            redis_enable_client: false
          )
        )
      end
    end
  end

  describe 'gitlab.yml' do
    gitlab_yml_path = '/var/opt/gitlab/gitlab-rails/etc/gitlab.yml'
    let(:gitlab_yml) { chef_run.template(gitlab_yml_path) }
    let(:gitlab_yml_templatesymlink) { chef_run.templatesymlink('Create a gitlab.yml and create a symlink to Rails root') }

    # NOTE: Test if we pass proper notifications to other resources
    describe 'rails cache management' do
      before do
        stub_default_not_listening?(false)
      end

      context 'with default values' do
        it 'should notify rails cache clear resource' do
          expect(gitlab_yml_templatesymlink).to notify('execute[clear the gitlab-rails cache]')
        end
      end

      context 'with rake_cache_clear set to false' do
        before do
          stub_gitlab_rb(gitlab_rails: { rake_cache_clear: false })
        end

        it 'should notify rails cache clear resource' do
          expect(gitlab_yml_templatesymlink).to notify(
            'execute[clear the gitlab-rails cache]')
        end

        it 'should not run cache clear' do
          expect(chef_run).not_to run_execute(
            'clear the gitlab-rails cache')
        end
      end
    end
  end

  context 'with environment variables' do
    context 'by default' do
      it 'creates necessary env variable files' do
        expect(chef_run).to create_env_dir('/opt/gitlab/etc/gitlab-rails/env').with_variables(default_vars)
      end

      context 'when a custom env variable is specified' do
        before do
          stub_gitlab_rb(gitlab_rails: { env: { 'IAM' => 'CUSTOMVAR' } })
        end

        it 'creates necessary env variable files' do
          expect(chef_run).to create_env_dir('/opt/gitlab/etc/gitlab-rails/env').with_variables(
            default_vars.merge(
              {
                'IAM' => 'CUSTOMVAR'
              }
            )
          )
        end
      end
    end

    context 'when puma per_worker_max_memory_mb is configured' do
      before do
        stub_gitlab_rb(puma: { per_worker_max_memory_mb: 1200 })
      end

      it 'creates necessary env variable files' do
        expect(chef_run).to create_env_dir('/opt/gitlab/etc/gitlab-rails/env').with_variables(
          default_vars.merge(
            {
              'PUMA_WORKER_MAX_MEMORY' => 1200
            }
          )
        )
      end
    end

    context 'when relative URL is enabled' do
      before do
        stub_gitlab_rb(gitlab_rails: { gitlab_relative_url: '/gitlab' })
      end

      it 'creates necessary env variable files' do
        expect(chef_run).to create_env_dir('/opt/gitlab/etc/gitlab-rails/env').with_variables(
          default_vars.merge(
            {
              'RAILS_RELATIVE_URL_ROOT' => '/gitlab'
            }
          )
        )
      end
    end

    context 'when relative URL is specified in external_url' do
      before do
        stub_gitlab_rb(external_url: 'http://localhost/gitlab')
      end

      it 'creates necessary env variable files' do
        expect(chef_run).to create_env_dir('/opt/gitlab/etc/gitlab-rails/env').with_variables(
          default_vars.merge(
            {
              'RAILS_RELATIVE_URL_ROOT' => '/gitlab'
            }
          )
        )
      end
    end
  end

  describe "with symlinked templates" do
    let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }

    before do
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
    end

    describe 'database.yml' do
      database_yml_path = '/var/opt/gitlab/gitlab-rails/etc/database.yml'
      let(:database_yml) { chef_run.template(database_yml_path) }
      let(:database_yml_content) { ChefSpec::Renderer.new(chef_run, database_yml).content }
      let(:generated_yml_content) { YAML.safe_load(database_yml_content) }

      let(:config_file) { database_yml_path }
      let(:templatesymlink) { chef_run.templatesymlink('Create a database.yml and create a symlink to Rails root') }

      context 'by default' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default')
        end

        it 'creates the template' do
          expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'db_host' => '/var/opt/gitlab/postgresql',
              'db_database' => 'gitlabhq_production',
              'db_load_balancing' => { 'hosts' => [] },
              'db_prepared_statements' => false,
              'db_sslcompression' => 0,
              'db_sslcert' => nil,
              'db_sslkey' => nil,
              'db_application_name' => nil
            )
          )
        end

        it 'template triggers notifications' do
          expect(templatesymlink).to notify('runit_service[puma]').to(:restart).delayed
          expect(templatesymlink).to notify('sidekiq_service[sidekiq]').to(:restart).delayed
          expect(templatesymlink).not_to notify('runit_service[gitlab-workhorse]').to(:restart).delayed
          expect(templatesymlink).not_to notify('runit_service[nginx]').to(:restart).delayed
        end

        it 'renders expected YAML' do
          expect(generated_yml_content.dig('production', 'main', 'adapter')).to eq('postgresql')
          expect(generated_yml_content.dig('production', 'main', 'host')).to eq('/var/opt/gitlab/postgresql')
          expect(generated_yml_content.dig('production', 'main', 'port')).to eq(5432)
          expect(generated_yml_content.dig('production', 'main', 'application_name')).to eq(nil)
        end
      end

      context 'with specific database settings' do
        context 'with an application name set' do
          where(:appname, :expected) do
            ''     | ''
            'test' | 'test'
          end

          with_them do
            cached(:chef_run) do
              ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default')
            end

            before do
              stub_gitlab_rb(
                'gitlab_rails' => { 'db_application_name' => appname }
              )
            end

            it 'renders expected YAML' do
              expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
                hash_including(
                  'db_application_name' => appname
                )
              )

              expect(generated_yml_content.dig('production', 'main').keys).to include(*%w(adapter host port application_name))
              expect(generated_yml_content.dig('production', 'main', 'application_name')).to eq(expected)
            end
          end
        end

        context 'when multiple postgresql listen_address is used' do
          before do
            stub_gitlab_rb(postgresql: { listen_address: "127.0.0.1,1.1.1.1" })
          end

          it 'creates the postgres configuration file with multi listen_address and database.yml file with one host' do
            expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
              hash_including(
                'db_host' => '127.0.0.1'
              )
            )
          end
        end

        context 'when no postgresql listen_address is used' do
          it 'creates the postgres configuration file with empty listen_address and database.yml file with default one' do
            expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
              hash_including(
                'db_host' => '/var/opt/gitlab/postgresql'
              )
            )
          end
        end

        context 'when one postgresql listen_address is used' do
          cached(:chef_run) do
            RSpec::Mocks.with_temporary_scope do
              stub_gitlab_rb(postgresql: { listen_address: "127.0.0.1" })
            end

            ChefSpec::SoloRunner.new.converge('gitlab::default')
          end

          it 'creates the postgres configuration file with one listen_address and database.yml file with one host' do
            expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
              hash_including(
                'db_host' => '127.0.0.1'
              )
            )
          end

          it 'template triggers notifications' do
            expect(templatesymlink).to notify('runit_service[puma]').to(:restart).delayed
            expect(templatesymlink).to notify('sidekiq_service[sidekiq]').to(:restart).delayed
            expect(templatesymlink).not_to notify('runit_service[gitlab-workhorse]').to(:restart).delayed
            expect(templatesymlink).not_to notify('runit_service[nginx]').to(:restart).delayed
          end
        end

        context 'when load balancers are specified' do
          before do
            stub_gitlab_rb(gitlab_rails: { db_load_balancing: { 'hosts' => ['primary.example.com', 'secondary.example.com'] } })
          end

          it 'uses provided value in database.yml' do
            expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
              hash_including(
                'db_load_balancing' => { 'hosts' => ['primary.example.com', 'secondary.example.com'] }
              )
            )
          end
        end

        context 'when prepared_statements are disabled' do
          before do
            stub_gitlab_rb(gitlab_rails: { db_prepared_statements: false })
          end

          it 'uses provided value in database.yml' do
            expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
              hash_including(
                'db_prepared_statements' => false,
                'db_statements_limit' => 1000
              )
            )
          end
        end

        context 'when limit for prepared_statements are specified' do
          before do
            stub_gitlab_rb(gitlab_rails: { db_statements_limit: 12345 })
          end

          it 'uses provided value in database.yml' do
            expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
              hash_including(
                'db_prepared_statements' => false,
                'db_statements_limit' => 12345
              )
            )
          end
        end

        context 'when SSL compression is enabled' do
          before do
            stub_gitlab_rb(gitlab_rails: { db_sslcompression: 1 })
          end

          it 'uses provided value in database.yml' do
            expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
              hash_including(
                'db_sslcompression' => 1
              )
            )
          end
        end

        context 'when SSL certificate and key for DB is specified' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                db_sslcert: '/etc/certs/db.cer',
                db_sslkey: '/etc/certs/db.key'
              }
            )
          end

          it 'uses specified value in database.yml' do
            expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
              hash_including(
                'db_sslcert' => '/etc/certs/db.cer',
                'db_sslkey' => '/etc/certs/db.key'
              )
            )
          end
        end
      end

      describe 'client side statement_timeout' do
        let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default') }

        context 'default values' do
          it 'does not set a default value' do
            expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
              hash_including(
                'db_statement_timeout' => nil
              )
            )

            expect(chef_run).to render_file(config_file).with_content { |content|
              expect(content).to match(%r(statement_timeout: $))
            }
          end
        end

        context 'custom value' do
          before do
            stub_gitlab_rb(
              'postgresql' => { 'statement_timeout' => '65000' },
              'gitlab_rails' => { 'db_statement_timeout' => '70000' }
            )
          end

          it 'uses specified client side statement_timeout value' do
            expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
              hash_including(
                'db_statement_timeout' => '70000'
              )
            )

            expect(chef_run).to render_file(config_file).with_content { |content|
              expect(content).to match(%r(statement_timeout: 70000$))
            }
          end
        end
      end

      context 'adjusting database adapter connection parameters' do
        let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default') }

        using RSpec::Parameterized::TableSyntax

        where(:rb_param, :yaml_param, :default_value, :custom_value) do
          'db_connect_timeout' | 'connect_timeout' | nil | 5
          'db_keepalives' | 'keepalives' | nil | 1
          'db_keepalives_idle' | 'keepalives_idle' | nil | 5
          'db_keepalives_interval' | 'keepalives_interval' | nil | 3
          'db_keepalives_count' | 'keepalives_count' | nil | 3
          'db_tcp_user_timeout' | 'tcp_user_timeout' | nil | 13000
        end

        with_them do
          context 'default values' do
            it 'does not set a default value' do
              expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
                hash_including(
                  rb_param => default_value
                )
              )

              expect(chef_run).to render_file(config_file).with_content { |content|
                expect(content).to match(%r(#{yaml_param}: $))
              }
            end
          end

          context 'custom connection parameter value' do
            before do
              stub_gitlab_rb(
                'gitlab_rails' => { rb_param => custom_value }
              )
            end

            it 'uses specified connection parameter value' do
              expect(chef_run).to create_templatesymlink('Create a database.yml and create a symlink to Rails root').with_variables(
                hash_including(
                  rb_param => custom_value
                )
              )

              expect(chef_run).to render_file(config_file).with_content { |content|
                expect(content).to match(%r(#{yaml_param}: #{custom_value}$))
              }
            end
          end
        end
      end
    end

    describe 'gitlab_workhorse_secret' do
      let(:templatesymlink) { chef_run.templatesymlink('Create a gitlab_workhorse_secret and create a symlink to Rails root') }

      context 'by default' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new.converge('gitlab::default')
        end

        it 'creates the template' do
          expect(chef_run).to create_templatesymlink("Create a gitlab_workhorse_secret and create a symlink to Rails root").with(
            owner: 'root',
            group: 'root',
            mode: '0644'
          )
        end

        it 'template triggers notifications' do
          expect(templatesymlink).to notify('runit_service[gitlab-workhorse]').to(:restart).delayed
          expect(templatesymlink).to notify('runit_service[puma]').to(:restart).delayed
          expect(templatesymlink).to notify('sidekiq_service[sidekiq]').to(:restart).delayed
        end
      end

      context 'with specific gitlab_workhorse_secret' do
        cached(:chef_run) do
          RSpec::Mocks.with_temporary_scope do
            stub_gitlab_rb(gitlab_workhorse: { secret_token: 'abc123-gitlab-workhorse' })
          end

          ChefSpec::SoloRunner.new.converge('gitlab::default')
        end

        it 'renders the correct node attribute' do
          expect(chef_run).to create_templatesymlink("Create a gitlab_workhorse_secret and create a symlink to Rails root").with_variables(
            secret_token: 'abc123-gitlab-workhorse'
          )
        end

        it 'uses the correct owner and permissions' do
          expect(chef_run).to create_templatesymlink('Create a gitlab_workhorse_secret and create a symlink to Rails root').with(
            owner: 'root',
            group: 'root',
            mode: '0644'
          )
        end

        it 'template triggers notifications' do
          expect(templatesymlink).to notify('runit_service[gitlab-workhorse]').to(:restart).delayed
          expect(templatesymlink).to notify('runit_service[puma]').to(:restart).delayed
          expect(templatesymlink).to notify('sidekiq_service[sidekiq]').to(:restart).delayed
        end
      end
    end

    describe 'gitlab_pages_secret' do
      let(:templatesymlink) { chef_run.templatesymlink('Create a gitlab_pages_secret and create a symlink to Rails root') }

      context 'with pages disabled' do
        let(:api_secret_key) { SecureRandom.base64(32) }

        cached(:chef_run) do
          RSpec::Mocks.with_temporary_scope do
            stub_gitlab_rb(
              pages_enabled: false,
              gitlab_pages: { api_secret_key: api_secret_key, enable: false },
              pages_external_url: 'http://pages.example.com'
            )
          end

          ChefSpec::SoloRunner.new.converge('gitlab::default')
        end

        it 'creates the template' do
          expect(chef_run).to create_templatesymlink("Create a gitlab_pages_secret and create a symlink to Rails root").with(
            owner: 'root',
            group: 'root',
            mode: '0644'
          )
        end
      end

      context 'by default' do
        cached(:chef_run) do
          RSpec::Mocks.with_temporary_scope do
            stub_gitlab_rb(
              external_url: 'http://gitlab.example.com',
              pages_external_url: 'http://pages.example.com'
            )
          end

          ChefSpec::SoloRunner.new.converge('gitlab::default')
        end

        it 'creates the template' do
          expect(chef_run).to create_templatesymlink("Create a gitlab_pages_secret and create a symlink to Rails root").with(
            owner: 'root',
            group: 'root',
            mode: '0644'
          )
        end

        it 'template triggers notifications' do
          expect(templatesymlink).to notify('runit_service[gitlab-pages]').to(:restart).delayed
          expect(templatesymlink).to notify('runit_service[puma]').to(:restart).delayed
          expect(templatesymlink).to notify('sidekiq_service[sidekiq]').to(:restart).delayed
        end
      end

      context 'with specific gitlab_pages_secret' do
        let(:api_secret_key) { SecureRandom.base64(32) }

        cached(:chef_run) do
          RSpec::Mocks.with_temporary_scope do
            stub_gitlab_rb(
              gitlab_pages: { api_secret_key: api_secret_key },
              external_url: 'http://gitlab.example.com',
              pages_external_url: 'http://pages.example.com'
            )
          end

          ChefSpec::SoloRunner.new.converge('gitlab::default')
        end

        it 'renders the correct node attribute' do
          expect(chef_run).to create_templatesymlink("Create a gitlab_pages_secret and create a symlink to Rails root").with_variables(
            secret_token: api_secret_key
          )
        end

        it 'uses the correct owner and permissions' do
          expect(chef_run).to create_templatesymlink('Create a gitlab_pages_secret and create a symlink to Rails root').with(
            owner: 'root',
            group: 'root',
            mode: '0644'
          )
        end

        it 'template triggers notifications' do
          expect(templatesymlink).to notify('runit_service[gitlab-pages]').to(:restart).delayed
          expect(templatesymlink).to notify('runit_service[puma]').to(:restart).delayed
          expect(templatesymlink).to notify('sidekiq_service[sidekiq]').to(:restart).delayed
        end
      end
    end

    describe 'gitlab_kas_secret' do
      let(:templatesymlink) { chef_run.templatesymlink('Create a gitlab_kas_secret and create a symlink to Rails root') }

      shared_examples 'creates the KAS template' do
        it 'creates the template' do
          expect(chef_run).to create_templatesymlink('Create a gitlab_kas_secret and create a symlink to Rails root').with(
            owner: 'root',
            group: 'root',
            mode: '0644'
          )
        end
      end

      context 'with KAS disabled' do
        cached(:chef_run) do
          RSpec::Mocks.with_temporary_scope do
            stub_gitlab_rb(
              gitlab_kas: { enable: false }
            )
          end

          ChefSpec::SoloRunner.new.converge('gitlab::default')
        end

        it_behaves_like 'creates the KAS template'
      end

      context 'with KAS enabled' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new.converge('gitlab::default')
        end

        it_behaves_like 'creates the KAS template'

        it 'template triggers notifications' do
          expect(templatesymlink).to notify('runit_service[gitlab-kas]').to(:restart).delayed
          expect(templatesymlink).to notify('runit_service[puma]').to(:restart).delayed
          expect(templatesymlink).to notify('sidekiq_service[sidekiq]').to(:restart).delayed
        end
      end

      context 'with specific gitlab_kas_secret' do
        let(:api_secret_key) { SecureRandom.base64(32) }

        cached(:chef_run) do
          RSpec::Mocks.with_temporary_scope do
            stub_gitlab_rb(
              gitlab_kas: { api_secret_key: api_secret_key }
            )
          end

          ChefSpec::SoloRunner.new.converge('gitlab::default')
        end

        it 'renders the correct node attribute' do
          expect(chef_run).to create_templatesymlink('Create a gitlab_kas_secret and create a symlink to Rails root').with_variables(
            secret_token: api_secret_key
          )
        end

        it_behaves_like 'creates the KAS template'

        it 'template triggers notifications' do
          expect(templatesymlink).to notify('runit_service[gitlab-kas]').to(:restart).delayed
          expect(templatesymlink).to notify('runit_service[puma]').to(:restart).delayed
          expect(templatesymlink).to notify('sidekiq_service[sidekiq]').to(:restart).delayed
        end
      end
    end
  end

  describe 'GitLab Registry files' do
    describe 'gitlab-registry.key file' do
      context 'Registry is disabled' do
        it 'does not generate gitlab-registry.key file' do
          expect(chef_run).not_to render_file("/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key")
        end
      end

      context 'Registry is enabled' do
        context 'with default configuration' do
          before do
            stub_gitlab_rb(
              gitlab_rails: {
                registry_enabled: true
              }
            )
          end

          it 'generates key file in the default location' do
            expect(chef_run).to render_file("/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key").with_content(/\A-----BEGIN RSA PRIVATE KEY-----\n.+\n-----END RSA PRIVATE KEY-----\n\Z/m)
          end
        end

        context 'with user specified configuration' do
          context 'when location of key file is specified' do
            before do
              stub_gitlab_rb(
                gitlab_rails: {
                  registry_enabled: true,
                  registry_key_path: '/fake/path'
                }
              )
            end

            it 'generates key file in the specified location' do
              expect(chef_run).to render_file("/fake/path").with_content(/\A-----BEGIN RSA PRIVATE KEY-----\n.+\n-----END RSA PRIVATE KEY-----\n\Z/m)
            end
          end

          context 'when key content is specified' do
            before do
              stub_gitlab_rb(
                gitlab_rails: {
                  registry_enabled: true
                },
                registry: {
                  internal_key: 'foobar'
                }
              )
            end

            it 'generates key file with specified content' do
              expect(chef_run).to render_file("/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key").with_content('foobar')
            end
          end
        end
      end
    end
  end

  context 'SMTP settings' do
    context 'when connection pooling is not configured' do
      it 'creates smtp_settings.rb with pooling disabled' do
        stub_gitlab_rb(
          gitlab_rails: {
            smtp_enable: true
          }
        )

        expect(chef_run).to create_templatesymlink('Create a smtp_settings.rb and create a symlink to Rails root').with_variables(
          hash_including(
            'smtp_pool' => false
          )
        )
      end
    end

    context 'when connection pooling is enabled' do
      it 'creates smtp_settings.rb with pooling enabled' do
        stub_gitlab_rb(
          gitlab_rails: {
            smtp_enable: true,
            smtp_pool: true
          }
        )

        expect(chef_run).to create_templatesymlink('Create a smtp_settings.rb and create a symlink to Rails root').with_variables(
          hash_including(
            'smtp_pool' => true
          )
        )

        expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/smtp_settings.rb').with_content { |content|
          expect(content).to include('ActionMailer::Base.delivery_method = :smtp_pool')
        }
      end
    end
  end

  describe 'logrotate settings' do
    context 'default values' do
      it_behaves_like 'configured logrotate service', 'gitlab-pages', 'git', 'git'
    end

    context 'specified username and group' do
      before do
        stub_gitlab_rb(
          user: {
            username: 'foo',
            group: 'bar'
          }
        )
      end

      it_behaves_like 'configured logrotate service', 'gitlab-pages', 'foo', 'bar'
    end
  end

  describe 'cleaning up the legacy sidekiq log symlink' do
    it 'removes the link if it existed' do
      allow(File).to receive(:symlink?).with('/var/log/gitlab/gitlab-rails/sidekiq.log') { true }

      expect(chef_run).to delete_link('/var/log/gitlab/gitlab-rails/sidekiq.log')
    end

    it 'does nothing if it did not exist' do
      allow(File).to receive(:symlink?).with('/var/log/gitlab/gitlab-rails/sidekiq.log') { false }

      expect(chef_run).not_to delete_link('/var/log/gitlab/gitlab-rails/sidekiq.log')
    end
  end
end
