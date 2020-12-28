require 'chef_helper'

RSpec::Matchers.define :configure_gitlab_yml_using do |expected_variables|
  match do |chef_run|
    expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
      expected_variables
    )
  end
end

RSpec.describe 'gitlab::gitlab-rails' do
  using RSpec::Parameterized::TableSyntax

  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink runit_service)).converge('gitlab::default') }
  let(:redis_instances) { %w(cache queues shared_state) }
  let(:config_dir) { '/var/opt/gitlab/gitlab-rails/etc/' }
  let(:default_vars) do
    {
      'HOME' => '/var/opt/gitlab',
      'RAILS_ENV' => 'production',
      'SIDEKIQ_MEMORY_KILLER_MAX_RSS' => '2000000',
      'BUNDLE_GEMFILE' => '/opt/gitlab/embedded/service/gitlab-rails/Gemfile',
      'PATH' => '/opt/gitlab/bin:/opt/gitlab/embedded/bin:/bin:/usr/bin',
      'ICU_DATA' => '/opt/gitlab/embedded/share/icu/current',
      'PYTHONPATH' => '/opt/gitlab/embedded/lib/python3.7/site-packages',
      'EXECJS_RUNTIME' => 'Disabled',
      'TZ' => ':/etc/localtime',
      'LD_PRELOAD' => '/opt/gitlab/embedded/lib/libjemalloc.so',
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
            redis_sentinels: []
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
          expect(chef_run).to delete_file("/opt/gitlab/embedded/service/gitlab-rails/config/redis.#{instance}.yml")
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
    end

    context 'with multiple instances' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
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
            redis_sentinels: [{ "host" => instance, "port" => "1234" }, { "host" => instance, "port" => "3456" }]
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
            redis_sentinels: [{ 'host' => 'actioncable', 'port' => '1234' }, { 'host' => 'actioncable', 'port' => '3456' }]
          )
        )
      end
    end
  end

  context 'creating gitlab.yml' do
    gitlab_yml_path = '/var/opt/gitlab/gitlab-rails/etc/gitlab.yml'
    let(:gitlab_yml) { chef_run.template(gitlab_yml_path) }
    let(:gitlab_yml_content) { ChefSpec::Renderer.new(chef_run, gitlab_yml).content }
    let(:generated_yml_content) { YAML.safe_load(gitlab_yml_content, [], [], true) }
    let(:gitlab_yml_templatesymlink) { chef_run.templatesymlink('Create a gitlab.yml and create a symlink to Rails root') }

    let(:aws_connection_hash) do
      {
        'provider' => 'AWS',
        'region' => 'eu-west-1',
        'aws_access_key_id' => 'AKIAKIAKI',
        'aws_secret_access_key' => 'secret123'
      }
    end

    it_behaves_like 'renders a valid YAML file', gitlab_yml_path

    shared_examples 'sets the connection in YAML' do
      it do
        expect(chef_run).to render_file(gitlab_yml_path)
          .with_content(/connection:\s{"provider":"AWS"/)
        expect(chef_run).to render_file(gitlab_yml_path)
          .with_content(/"region":"eu-west-1"/)
        expect(chef_run).to render_file(gitlab_yml_path)
          .with_content(/"aws_access_key_id":"AKIAKIAKI"/)
        expect(chef_run).to render_file(gitlab_yml_path)
          .with_content(/"aws_secret_access_key":"secret123"/)
      end
    end

    # NOTE: Test if we pass proper notifications to other resources
    context 'rails cache management' do
      before do
        allow_any_instance_of(OmnibusHelper).to receive(:not_listening?)
          .and_return(false)
      end

      it 'should notify rails cache clear resource' do
        expect(gitlab_yml_templatesymlink).to notify('execute[clear the gitlab-rails cache]')
      end

      it 'should still notify rails cache clear resource if disabled' do
        stub_gitlab_rb(gitlab_rails: { rake_cache_clear: false })

        expect(gitlab_yml_templatesymlink).to notify(
          'execute[clear the gitlab-rails cache]')
        expect(chef_run).not_to run_execute(
          'clear the gitlab-rails cache')
      end
    end

    context 'matomo_disable_cookies' do
      context 'when true' do
        before do
          stub_gitlab_rb(
            gitlab_rails: { extra_matomo_disable_cookies: true }
          )
        end

        it 'should set matomo_disable_cookies to true' do
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'extra_matomo_disable_cookies' => true
            )
          )
        end
      end

      context 'when false' do
        before do
          stub_gitlab_rb(
            gitlab_rails: { extra_matomo_disable_cookies: false }
          )
        end

        it 'should set matomo_disable_cookies to false' do
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'extra_matomo_disable_cookies' => false
            )
          )
        end
      end

      context 'when absent' do
        it 'should set matomo_disable_cookies to nil' do
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'extra_matomo_disable_cookies' => nil
            )
          )
        end
      end
    end

    describe 'repositories storages' do
      it 'sets specified properties' do
        stub_gitlab_rb(
          git_data_dirs: {
            "second_storage" => {
              "path" => "/tmp/storage"
            }
          }
        )

        expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
          hash_including(
            'repositories_storages' => {
              'second_storage' => {
                'path' => '/tmp/storage/repositories',
                'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket'
              }
            }
          )
        )
      end

      it 'sets the defaults' do
        default_storages = {
          'default' => {
            'path' => '/var/opt/gitlab/git-data/repositories',
            'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket'
          }
        }
        expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
          hash_including(
            'repositories_storages' => default_storages
          )
        )
      end

      it 'sets path if not provided' do
        stub_gitlab_rb(
          {
            git_data_dirs:
            {
              'default' => { 'gitaly_address' => 'tcp://gitaly.internal:8075' }
            }
          }
        )

        expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
          hash_including(
            'repositories_storages' => {
              'default' => {
                'path' => '/var/opt/gitlab/git-data/repositories',
                'gitaly_address' => 'tcp://gitaly.internal:8075'
              }
            }
          )
        )
      end
    end

    context 'Content Security Policy' do
      context 'with default settings' do
        it 'does not include CSP config' do
          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            expect(content).not_to match(%r(content_security_policy))
          }
        end
      end

      context 'with settings' do
        before do
          stub_gitlab_rb(csp_config)
        end

        shared_examples 'renders CSP settings' do
          it 'gitlab.yml renders CSP settings' do
            expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
              yaml_data = YAML.safe_load(content, [], [], true)
              expect(yaml_data['production']['gitlab']['content_security_policy'])
                .to eq(csp_config[:gitlab_rails][:content_security_policy])
            }
          end
        end

        context 'CSP is disabled' do
          let(:csp_config) do
            {
              gitlab_rails: {
                content_security_policy: {
                  'enabled' => true,
                  'report_only' => false,
                }
              }
            }
          end

          it_behaves_like 'renders CSP settings'
        end

        context 'CSP is enabled' do
          let(:csp_config) do
            {
              gitlab_rails: {
                content_security_policy: {
                  'enabled' => true,
                  'report_only' => false,
                  'directives' => {
                    'default_src' => "'self'",
                    'script_src' => "'self' http://recaptcha.net",
                    'worker_src' => "'self'"
                  }
                }
              }
            }
          end

          it_behaves_like 'renders CSP settings'
        end
      end
    end

    describe 'Allowed hosts' do
      include_context 'gitlab-rails'

      context 'with default values' do
        it 'do not render allowed_hosts in gitlab.yml' do
          expect(gitlab_yml[:production][:gitlab][:allowed_hosts]).to be nil
        end
      end

      context 'with user specified values' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              allowed_hosts: ['example.com', 'foobar.com']
            }
          )
        end

        it 'renders allowed_hosts in gitlab.yml' do
          expect(gitlab_yml[:production][:gitlab][:allowed_hosts]).to eq(['example.com', 'foobar.com'])
        end
      end

      context 'pages local store is not specified' do
        it 'sets pages_local_store_enabled to true and return default path' do
          stub_gitlab_rb(
            external_url: 'https://gitlab.example.com',
            pages_external_url: 'https://pages.example.com'
          )

          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'pages_path' => '/var/opt/gitlab/gitlab-rails/shared/pages',
              'pages_local_store_enabled' => true,
              'pages_local_store_path' => '/var/opt/gitlab/gitlab-rails/shared/pages'
            )
          )
        end
      end

      context 'when pages_path is specified but not local store path' do
        it 'returns pages_local_store path with the same value as pages_path' do
          stub_gitlab_rb(
            external_url: 'https://gitlab.example.com',
            pages_external_url: 'https://pages.example.com',
            gitlab_rails: {
              pages_path: '/tmp/test',
              pages_local_store_enabled: false
            }
          )

          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'pages_path' => '/tmp/test',
              'pages_local_store_enabled' => false,
              'pages_local_store_path' => '/tmp/test'
            )
          )
        end
      end

      context 'when pages local store path and enabled are custom' do
        it 'returns pages_local_store path and enabled with these custom values' do
          stub_gitlab_rb(
            external_url: 'https://gitlab.example.com',
            pages_external_url: 'https://pages.example.com',
            gitlab_rails: {
              pages_path: '/tmp/test',
              pages_local_store_enabled: false,
              pages_local_store_path: '/another/path'
            }
          )

          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'pages_path' => '/tmp/test',
              'pages_local_store_enabled' => false,
              'pages_local_store_path' => '/another/path'
            )
          )
        end
      end
    end

    context 'when seat link is enabled' do
      it 'sets seat link to true' do
        expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
          hash_including(
            'seat_link_enabled' => true
          )
        )
      end
    end

    context 'when seat link is disabled' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            seat_link_enabled: false,
          }
        )
      end

      it 'sets seat link to false' do
        expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
          hash_including(
            'seat_link_enabled' => false
          )
        )
      end
    end

    context 'omniauth settings' do
      context 'enabled setting' do
        it 'defaults to nil (enabled)' do
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_enabled' => nil
            )
          )
        end

        it 'can be explicitly enabled' do
          stub_gitlab_rb(gitlab_rails: { omniauth_enabled: true })

          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_enabled' => true
            )
          )
        end

        it 'can be disabled' do
          stub_gitlab_rb(gitlab_rails: { omniauth_enabled: false })

          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_enabled' => false
            )
          )
        end
      end

      context 'sync email from omniauth provider is configured' do
        it 'sets the omniauth provider' do
          stub_gitlab_rb(gitlab_rails: { omniauth_sync_email_from_provider: 'cas3' })

          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_sync_email_from_provider' => 'cas3'
            )
          )
        end
      end

      context 'sync email from omniauth provider is not configured' do
        it 'does not include the sync email from omniauth provider setting' do
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_sync_email_from_provider' => nil
            )
          )
        end
      end

      context 'sync profile from omniauth provider is not configured' do
        it 'sets the sync profile from provider to []' do
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_sync_profile_from_provider' => nil
            )
          )
        end
      end

      context 'sync profile from omniauth provider is configured to array' do
        it 'sets the sync profile from provider to [\'cas3\']' do
          stub_gitlab_rb(gitlab_rails: { omniauth_sync_profile_from_provider: ['cas3'] })

          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_sync_profile_from_provider' => ['cas3']
            )
          )
        end
      end

      context 'sync profile from omniauth provider is configured to true' do
        it 'sets the sync profile from provider to true' do
          stub_gitlab_rb(gitlab_rails: { omniauth_sync_profile_from_provider: true })

          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_sync_profile_from_provider' => true
            )
          )
        end
      end

      context 'sync profile attributes is configured to [\"email\", \"name\"]' do
        it 'sets the sync profile attributes to [\"email\", \"name\"]' do
          stub_gitlab_rb(gitlab_rails: { omniauth_sync_profile_attributes: %w(email name) })

          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_sync_profile_attributes' => %w[email name]
            )
          )
        end
      end

      context 'bypass two factor for providers is configured ' do
        it 'bypass_two_factor configured as true' do
          stub_gitlab_rb(gitlab_rails: { omniauth_bypass_two_factor: true })
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_bypass_two_factor' => true
            )
          )
        end

        it 'bypass_two_factor configured as false' do
          stub_gitlab_rb(gitlab_rails: { omniauth_bypass_two_factor: false })
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_bypass_two_factor' => false
            )
          )
        end

        it 'bypass_two_factor configured as [\'foo\']' do
          stub_gitlab_rb(gitlab_rails: { omniauth_bypass_two_factor: ['foo'] })
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_bypass_two_factor' => ['foo']
            )
          )
        end
      end

      context 'sync profile attributes is configured to true' do
        it 'sets the sync profile attributes to true' do
          stub_gitlab_rb(gitlab_rails: { omniauth_sync_profile_attributes: true })

          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_sync_profile_attributes' => true
            )
          )
        end
      end

      context 'auto link user for providers is configured ' do
        it 'auto_link_user configured as true' do
          stub_gitlab_rb(gitlab_rails: { omniauth_auto_link_user: true })
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_auto_link_user' => true
            )
          )
        end

        it 'auto_link_user configured as false' do
          stub_gitlab_rb(gitlab_rails: { omniauth_auto_link_user: false })
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_auto_link_user' => false
            )
          )
        end

        it 'auto_link_user configured as [\'foo\']' do
          stub_gitlab_rb(gitlab_rails: { omniauth_auto_link_user: ['foo'] })
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_auto_link_user' => ['foo']
            )
          )
        end
      end

      context 'auto link user for providers is not configured' do
        it 'sets auto_link_user to []' do
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'omniauth_auto_link_user' => nil
            )
          )
        end
      end
    end

    context 'Application settings cache expiry' do
      context 'when a value is set' do
        it 'exposes the set value' do
          stub_gitlab_rb(
            gitlab_rails: {
              application_settings_cache_seconds: 30
            }
          )

          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'application_settings_cache_seconds' => 30
            )
          )
        end
      end
      context 'when a value is not set' do
        it 'exposes the default (nil) value' do
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'application_settings_cache_seconds' => nil
            )
          )
        end
      end
    end

    context 'sidekiq-cluster' do
      let(:chef_run) do
        ChefSpec::SoloRunner.new.converge('gitlab-ee::default')
      end

      before do
        stub_gitlab_rb(sidekiq_cluster: { enable: true, queue_groups: 'gitlab_shell' })
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).and_return(false)
        allow_any_instance_of(OmnibusHelper).to receive(:service_up?).with('sidekiq-cluster').and_return(true)
        stub_should_notify?('sidekiq-cluster', true)
      end

      describe 'gitlab.yml' do
        let(:templatesymlink) { chef_run.templatesymlink('Create a gitlab.yml and create a symlink to Rails root') }

        it 'template triggers notifications' do
          expect(templatesymlink).not_to notify('sidekiq_service[sidekiq]').to(:restart).delayed
          expect(templatesymlink).to notify('sidekiq_service[sidekiq-cluster]').to(:restart).delayed
        end
      end
    end

    context 'Sidekiq exporter settings' do
      it 'exporter enabled but log disabled by default' do
        expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
          yaml_data = YAML.safe_load(content, [], [], true)
          expect(yaml_data['production']['monitoring']['sidekiq_exporter']).to include('enabled' => true, 'log_enabled' => false)
        }
      end

      context 'when exporter log enabled' do
        before do
          stub_gitlab_rb(
            sidekiq: { exporter_log_enabled: true }
          )
        end

        it 'enables the log' do
          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            yaml_data = YAML.safe_load(content, [], [], true)
            expect(yaml_data['production']['monitoring']['sidekiq_exporter']).to include('enabled' => true, 'log_enabled' => true)
          }
        end
      end
    end

    context 'Shutdown settings' do
      context 'Blackout setting' do
        it 'default setting' do
          stub_gitlab_rb({})

          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            yaml_data = YAML.safe_load(content, [], [], true)
            expect(yaml_data['production']['shutdown']).to include('blackout_seconds' => 10)
          }
        end

        it 'custom setting' do
          stub_gitlab_rb(
            gitlab_rails: { shutdown_blackout_seconds: 20 }
          )

          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            yaml_data = YAML.safe_load(content, [], [], true)
            expect(yaml_data['production']['shutdown']).to include('blackout_seconds' => 20)
          }
        end
      end
    end

    describe 'maximum request duration' do
      where(:web_worker, :configured_timeout, :expected_duration) do
        :unicorn | nil  | 57
        :unicorn | 30   | 29
        :unicorn | "30" | 29
        :puma    | nil  | 57
        :puma    | 120  | 114
      end

      with_them do
        before do
          stub_gitlab_rb(
            unicorn: { enable: web_worker == :unicorn, worker_timeout: configured_timeout },
            puma: { enable: web_worker == :puma, worker_timeout: configured_timeout }
          )
        end

        it 'includes the expected max duration' do
          expected_hash = { 'max_request_duration_seconds' => expected_duration }

          configure_gitlab_yml_using(hash_including(expected_hash))
          expect(generated_yml_content['production']['gitlab']).to include(expected_hash)
        end
      end

      it 'includes the configured value when one is set' do
        expected_hash = { 'max_request_duration_seconds' => 12 }
        stub_gitlab_rb(gitlab_rails: { max_request_duration_seconds: 12 })

        configure_gitlab_yml_using(hash_including(expected_hash))
        expect(generated_yml_content['production']['gitlab']).to include(expected_hash)
      end

      it 'raises an error when trying to configure a duration bigger than the worker timeout' do
        stub_gitlab_rb(gitlab_rails: { max_request_duration_seconds: 9000 })

        expect { chef_run }.to raise_error(/maximum request duration needs to be smaller than the worker timeout/)
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

    context 'when jemalloc is disabled' do
      before do
        stub_gitlab_rb(gitlab_rails: { enable_jemalloc: false })
      end

      it 'creates necessary env variable files' do
        vars = default_vars.dup
        vars.delete("LD_PRELOAD")
        expect(chef_run).to create_env_dir('/opt/gitlab/etc/gitlab-rails/env').with_variables(vars)
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
          expect(generated_yml_content.dig('production', 'adapter')).to eq('postgresql')
          expect(generated_yml_content.dig('production', 'host')).to eq('/var/opt/gitlab/postgresql')
          expect(generated_yml_content.dig('production', 'port')).to eq(5432)
          expect(generated_yml_content.dig('production', 'application_name')).to eq(nil)
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

              expect(generated_yml_content.dig('production').keys).to include(*%w(adapter host port application_name))
              expect(generated_yml_content.dig('production', 'application_name')).to eq(expected)
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

      context 'with KAS disabled' do
        cached(:chef_run) do
          RSpec::Mocks.with_temporary_scope do
            stub_gitlab_rb(
              gitlab_kas: { enable: false }
            )
          end

          ChefSpec::SoloRunner.new.converge('gitlab::default')
        end

        it 'creates the template' do
          expect(chef_run).to create_templatesymlink('Create a gitlab_kas_secret and create a symlink to Rails root').with(
            owner: 'root',
            group: 'root',
            mode: '0644'
          )
        end
      end

      context 'with KAS enabled' do
        cached(:chef_run) do
          RSpec::Mocks.with_temporary_scope do
            stub_gitlab_rb(
              gitlab_kas: { enable: true }
            )
          end

          ChefSpec::SoloRunner.new.converge('gitlab::default')
        end

        it 'creates the template' do
          expect(chef_run).to create_templatesymlink('Create a gitlab_kas_secret and create a symlink to Rails root').with(
            owner: 'root',
            group: 'root',
            mode: '0644'
          )
        end

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
              gitlab_kas: { api_secret_key: api_secret_key, enable: true }
            )
          end

          ChefSpec::SoloRunner.new.converge('gitlab::default')
        end

        it 'renders the correct node attribute' do
          expect(chef_run).to create_templatesymlink('Create a gitlab_kas_secret and create a symlink to Rails root').with_variables(
            secret_token: api_secret_key
          )
        end

        it 'uses the correct owner and permissions' do
          expect(chef_run).to create_templatesymlink('Create a gitlab_kas_secret and create a symlink to Rails root').with(
            owner: 'root',
            group: 'root',
            mode: '0644'
          )
        end

        it 'template triggers notifications' do
          expect(templatesymlink).to notify('runit_service[gitlab-kas]').to(:restart).delayed
          expect(templatesymlink).to notify('runit_service[puma]').to(:restart).delayed
          expect(templatesymlink).to notify('sidekiq_service[sidekiq]').to(:restart).delayed
        end
      end
    end
  end

  context 'gitlab registry' do
    describe 'registry is disabled' do
      it 'does not generate gitlab-registry.key file' do
        expect(chef_run).not_to render_file("/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key")
      end
    end

    describe 'registry is enabled' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            registry_enabled: true
          }
        )
      end

      it 'generates gitlab-registry.key file' do
        expect(chef_run).to render_file("/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key").with_content(/\A-----BEGIN RSA PRIVATE KEY-----\n.+\n-----END RSA PRIVATE KEY-----\n\Z/m)
      end

      context 'with non-default values' do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              registry_key_path: '/fake/path'
            }
          )
        end

        it 'renders gitlab.yml correctly' do
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'registry_key_path' => '/fake/path'
            )
          )
        end
      end
    end
  end

  context 'SMIME email settings' do
    context 'SMIME is enabled' do
      it 'exposes the default SMIME email file path settings' do
        stub_gitlab_rb(
          gitlab_rails: {
            gitlab_email_smime_enabled: true
          }
        )

        expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
          hash_including(
            'gitlab_email_smime_enabled' => true,
            'gitlab_email_smime_key_file' => '/etc/gitlab/ssl/gitlab_smime.key',
            'gitlab_email_smime_cert_file' => '/etc/gitlab/ssl/gitlab_smime.crt',
            'gitlab_email_smime_ca_certs_file' => nil
          )
        )
      end

      it 'exposes the customized SMIME email settings' do
        stub_gitlab_rb(
          gitlab_rails: {
            gitlab_email_smime_enabled: true,
            gitlab_email_smime_key_file: '/etc/gitlab/ssl/custom_gitlab_smime.key',
            gitlab_email_smime_cert_file: '/etc/gitlab/ssl/custom_gitlab_smime.crt',
            gitlab_email_smime_ca_certs_file: '/etc/gitlab/ssl/custom_gitlab_smime_cas.crt'
          }
        )

        expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
          hash_including(
            'gitlab_email_smime_enabled' => true,
            'gitlab_email_smime_key_file' => '/etc/gitlab/ssl/custom_gitlab_smime.key',
            'gitlab_email_smime_cert_file' => '/etc/gitlab/ssl/custom_gitlab_smime.crt',
            'gitlab_email_smime_ca_certs_file' => '/etc/gitlab/ssl/custom_gitlab_smime_cas.crt'
          )
        )
      end
    end

    context 'SMIME is disabled' do
      context 'SMIME email is not configured' do
        it 'does not enable SMIME signing' do
          expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(
            hash_including(
              'gitlab_email_smime_enabled' => false
            )
          )
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
