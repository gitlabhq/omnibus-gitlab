require 'chef_helper'

describe 'gitlab::gitlab-rails' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink env_dir storage_directory)).converge('gitlab::default') }
  let(:redis_instances) { %w(cache queues shared_state) }
  let(:config_dir) { '/var/opt/gitlab/gitlab-rails/etc/' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(File).to receive(:symlink?).and_call_original
  end

  context 'when manage-storage-directories is disabled' do
    cached(:chef_run) do
      RSpec::Mocks.with_temporary_scope do
        stub_gitlab_rb(gitlab_rails: { shared_path: '/tmp/shared',
                                       uploads_directory: '/tmp/uploads',
                                       builds_directory: '/tmp/builds' },
                       manage_storage_directories: { enable: false })
      end

      ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default')
    end

    it 'does not create the shared directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared')
    end

    it 'does not create the artifacts directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared/artifacts')
    end

    it 'does not create the lfs storage directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared/lfs-objects')
    end

    it 'does not create the packages storage directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared/packages')
    end

    it 'does not create the uploads storage directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/uploads')
    end

    it 'does not create the ci builds directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/builds')
    end

    it 'does not create the GitLab pages directory' do
      expect(chef_run).not_to run_ruby_block('directory resource: /tmp/shared/pages')
    end
  end

  context 'when manage-storage-directories is enabled' do
    cached(:chef_run) do
      RSpec::Mocks.with_temporary_scope do
        stub_gitlab_rb(gitlab_rails: { shared_path: '/tmp/shared',
                                       uploads_directory: '/tmp/uploads' },
                       gitlab_ci: { builds_directory: '/tmp/builds' })
      end

      ChefSpec::SoloRunner.new(step_into: %w(templatesymlink storage_directory)).converge('gitlab::default')
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

    it 'creates the packages directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/shared/packages')
    end

    it 'creates the uploads directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/uploads')
    end

    it 'creates the ci builds directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/builds')
    end

    it 'creates the GitLab pages directory' do
      expect(chef_run).to run_ruby_block('directory resource: /tmp/shared/pages')
    end

    it 'creates the shared tmp directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared/tmp').with(owner: 'git', mode: '0700')
    end

    it 'creates the shared cache directory' do
      expect(chef_run).to create_storage_directory('/tmp/shared/cache').with(owner: 'git', mode: '0700')
    end
  end

  context 'with redis settings' do
    let(:config_file) { '/var/opt/gitlab/gitlab-rails/etc/resque.yml' }

    context 'and default configuration' do
      it 'creates the config file with the required redis settings' do
        expect(chef_run).to render_file(config_file)
                              .with_content(%r{url: unix:/var/opt/gitlab/redis/redis.socket})
      end

      it 'does not render the separate instance configurations' do
        redis_instances.each do |instance|
          expect(chef_run).not_to render_file("#{config_dir}redis.#{instance}.yml")
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
            redis_password: 'mypass'
          }
        )
      end

      it 'creates the config file with custom host, port, password and database' do
        expect(chef_run).to render_file(config_file)
                              .with_content(%r{url: redis://:mypass@redis.example.com:8888/2})
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
            ]
          }
        )
      end

      it 'render separate config files' do
        redis_instances.each do |instance|
          expect(chef_run).to render_file("#{config_dir}redis.#{instance}.yml")
            .with_content(%r{^\s*url: redis://:fakepass@fake.redis.#{instance}.com:8888/2})
        end
      end

      it 'renders Sentinel config in files' do
        redis_instances.each do |instance|
          expect(chef_run).to render_file("#{config_dir}redis.#{instance}.yml")
            .with_content(%r{^\s*sentinels:\n.*-.*\n.*host: #{instance}\n.*port: 1234\n.*\n.*host: #{instance}\n.*port: 3456})
        end
      end

      it 'still renders the default configuration file' do
        expect(chef_run).to render_file(config_file)
      end
    end
  end

  context 'creating gitlab.yml' do
    gitlab_yml_path = '/var/opt/gitlab/gitlab-rails/etc/gitlab.yml'
    let(:gitlab_yml) { chef_run.template(gitlab_yml_path) }
    let(:gitlab_yml_templatesymlink) { chef_run.templatesymlink('Create a gitlab.yml and create a symlink to Rails root') }

    let(:aws_connection_hash) do
      {
        'provider' => 'AWS',
        'region' => 'eu-west-1',
        'aws_access_key_id' => 'AKIAKIAKI',
        'aws_secret_access_key' => 'secret123'
      }
    end

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

    context 'for settings regarding object storage for artifacts' do
      it 'allows not setting any values' do
        expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/object_store:\s+enabled: false\s+direct_upload: false\s+background_upload: true\s+proxy_download: false\s+remote_directory: "artifacts"\s+connection:/)
      end

      context 'with values' do
        before do
          stub_gitlab_rb(gitlab_rails: {
                           artifacts_object_store_enabled: true,
                           artifacts_object_store_direct_upload: true,
                           artifacts_object_store_background_upload: false,
                           artifacts_object_store_proxy_download: true,
                           artifacts_object_store_remote_directory: 'mepmep',
                           artifacts_object_store_connection: aws_connection_hash
                         })
        end

        it "sets the object storage values" do
          expect(chef_run).to render_file(gitlab_yml_path)
          .with_content(/object_store:\s+enabled: true\s+direct_upload: true\s+background_upload: false\s+proxy_download: true\s+remote_directory:\s+"mepmep"/)
        end

        include_examples 'sets the connection in YAML'
      end
    end

    context 'for settings regarding object storage for lfs' do
      it 'allows not setting any values' do
        expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/storage_path:\s+[-\/\w]*shared\/lfs-objects\s+object_store:\s+enabled: false\s+direct_upload: false\s+background_upload: true\s+proxy_download: false\s+remote_directory: "lfs-objects"\s+connection:/)
      end

      context 'with values' do
        before do
          stub_gitlab_rb(gitlab_rails: {
                           lfs_object_store_enabled: true,
                           lfs_object_store_direct_upload: true,
                           lfs_object_store_background_upload: false,
                           lfs_object_store_proxy_download: true,
                           lfs_object_store_remote_directory: 'mepmep',
                           lfs_object_store_connection: aws_connection_hash
                         })
        end

        it "sets the object storage values" do
          expect(chef_run).to render_file(gitlab_yml_path)
          .with_content(/storage_path:\s+[-\/\w]*shared\/lfs-objects\s+object_store:\s+enabled: true\s+direct_upload: true\s+background_upload: false\s+proxy_download: true\s+remote_directory:\s+"mepmep"\s+connection:/)
        end

        include_examples 'sets the connection in YAML'
      end
    end

    context 'for settings regarding object storage for uploads' do
      it 'allows not setting any values' do
        expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(%r{storage_path: [-/\w]*public\s+object_store:\s+enabled: false\s+direct_upload: false\s+background_upload: true\s+proxy_download: false\s+remote_directory: "uploads"\s+connection:})
      end

      context 'with values' do
        before do
          stub_gitlab_rb(gitlab_rails: {
                           uploads_base_dir: 'mapmap',
                           uploads_object_store_enabled: true,
                           uploads_object_store_direct_upload: true,
                           uploads_object_store_background_upload: false,
                           uploads_object_store_proxy_download: true,
                           uploads_object_store_remote_directory: 'mepmep',
                           uploads_object_store_connection: aws_connection_hash
                         })
        end

        it "sets the object storage values" do
          expect(chef_run).to render_file(gitlab_yml_path)
          .with_content(/storage_path:\s+[-\/\w]*public\s+base_dir:\s+mapmap\s+object_store:\s+enabled: true\s+direct_upload: true\s+background_upload: false\s+proxy_download: true\s+remote_directory:\s+"mepmep"\s+connection:/)
        end

        include_examples 'sets the connection in YAML'
      end
    end

    context 'for settings regarding object storage for packages' do
      it 'allows not setting any values' do
        expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/storage_path:\s+[-\/\w]*shared\/packages\s+object_store:\s+enabled: false\s+direct_upload: false\s+background_upload: true\s+proxy_download: false\s+remote_directory: "packages"\s+connection:/)
      end

      context 'with values' do
        before do
          stub_gitlab_rb(gitlab_rails: {
                           packages_object_store_enabled: true,
                           packages_object_store_direct_upload: true,
                           packages_object_store_background_upload: false,
                           packages_object_store_proxy_download: true,
                           packages_object_store_remote_directory: 'mepmep',
                           packages_object_store_connection: aws_connection_hash
                         })
        end

        it "sets the object storage values" do
          expect(chef_run).to render_file(gitlab_yml_path)
          .with_content(/storage_path:\s+[-\/\w]*shared\/packages\s+object_store:\s+enabled: true\s+direct_upload: true\s+background_upload: false\s+proxy_download: true\s+remote_directory:\s+"mepmep"\s+connection:/)
        end

        include_examples 'sets the connection in YAML'
      end
    end

    describe 'pseudonymizer settings' do
      it 'allows not setting any values' do
        pseudonymizer_spec = Regexp.new([
          'pseudonymizer:',
          'manifest:',
          'upload:',
          'remote_directory:',
          'connection:\s+{}'
        ].join('\s+'))

        expect(chef_run).to render_file(gitlab_yml_path).with_content(pseudonymizer_spec)
      end

      context 'with values' do
        before do
          stub_gitlab_rb(gitlab_rails: {
                           pseudonymizer_manifest: 'another/path/manifest.yml',
                           pseudonymizer_upload_remote_directory: 'gitlab-pseudo',
                           pseudonymizer_upload_connection: aws_connection_hash,
                         })
        end

        it "sets the object storage values" do
          pseudonymizer_spec = Regexp.new([
            'pseudonymizer:',
            'manifest:\s+"another/path/manifest.yml"',
            'upload:',
            'remote_directory:\s+"gitlab-pseudo"',
          ].join('\s+'))

          expect(chef_run).to render_file(gitlab_yml_path).with_content(pseudonymizer_spec)
        end

        include_examples 'sets the connection in YAML'
      end
    end

    describe 'repositories storages' do
      it 'sets specified properties' do
        stub_gitlab_rb(
          git_data_dirs: {
            "second_storage" => {
              "path" => "tmp/storage"
            }
          }
        )

        expect(chef_run).to render_file(gitlab_yml_path).with_content('"path":"tmp/storage/repositories"')
      end

      it 'sets the defaults' do
        default_json = '{"default":{"path":"/var/opt/gitlab/git-data/repositories","gitaly_address":"unix:/var/opt/gitlab/gitaly/gitaly.socket"}}'
        expect(chef_run).to render_file(gitlab_yml_path).with_content(default_json)
      end
    end

    context 'pages settings' do
      context 'pages access control is enabled' do
        it 'sets the hint true' do
          stub_gitlab_rb(
            external_url: 'https://gitlab.example.com',
            pages_external_url: 'https://pages.example.com',
            gitlab_pages: {
              external_http: ['external_pages.example.com', 'localhost:9000'],
              external_https: ['external_pages.example.com', 'localhost:9001'],
              access_control: true
            }
          )

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/pages:\s+enabled: true\s+access_control: true/)
        end
      end

      context 'pages access control is disabled' do
        it 'sets the hint false' do
          stub_gitlab_rb(
            external_url: 'https://gitlab.example.com',
            pages_external_url: 'https://pages.example.com',
            gitlab_pages: {
              external_http: ['external_pages.example.com', 'localhost:9000'],
              external_https: ['external_pages.example.com', 'localhost:9001'],
              access_control: false
            }
          )
          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/pages:\s+enabled: true\s+access_control: false/)
        end
      end
    end

    context 'mattermost settings' do
      context 'mattermost is configured' do
        it 'exposes the mattermost host' do
          stub_gitlab_rb(mattermost: { enable: true },
                         mattermost_external_url: 'http://mattermost.domain.com')

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content("host: http://mattermost.domain.com")
        end
      end

      context 'mattermost is not configured' do
        it 'has empty values' do
          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/mattermost:\s+enabled: false\s+host:\s+/)
        end
      end

      context 'mattermost on another server' do
        it 'sets the mattermost host' do
          stub_gitlab_rb(gitlab_rails: { mattermost_host: 'http://my.host.com' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/mattermost:\s+enabled: true\s+host: http:\/\/my.host.com\s+/)
        end

        context 'values set twice' do
          it 'sets the mattermost external url' do
            stub_gitlab_rb(mattermost: { enable: true },
                           mattermost_external_url: 'http://my.url.com',
                           gitlab_rails: { mattermost_host: 'http://do.not/setme' })

            expect(chef_run).to render_file(gitlab_yml_path)
              .with_content(/mattermost:\s+enabled: true\s+host: http:\/\/my.url.com\s+/)
          end
        end
      end
    end

    context 'omniauth settings' do
      context 'enabled setting' do
        it 'defaults to nil (enabled)' do
          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/omniauth:\s+(#.*\n\s+)?enabled: \n/)
        end

        it 'can be explicitly enabled' do
          stub_gitlab_rb(gitlab_rails: { omniauth_enabled: true })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/omniauth:\s+(#.*\n\s+)?enabled: true\n/)
        end

        it 'can be disabled' do
          stub_gitlab_rb(gitlab_rails: { omniauth_enabled: false })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/omniauth:\s+(#.*\n\s+)?enabled: false\n/)
        end
      end

      context 'sync email from omniauth provider is configured' do
        it 'sets the omniauth provider' do
          stub_gitlab_rb(gitlab_rails: { omniauth_sync_email_from_provider: 'cas3' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content("sync_email_from_provider: \"cas3\"")
        end
      end

      context 'sync email from omniauth provider is not configured' do
        it 'does not include the sync email from omniauth provider setting' do
          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            expect(content).not_to include('sync_email_from_provider')
          }
        end
      end

      context 'sync profile from omniauth provider is not configured' do
        it 'sets the sync profile from provider to []' do
          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content("sync_profile_from_provider: []")
        end
      end

      context 'sync profile from omniauth provider is configured to array' do
        it 'sets the sync profile from provider to [\'cas3\']' do
          stub_gitlab_rb(gitlab_rails: { omniauth_sync_profile_from_provider: ['cas3'] })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content("sync_profile_from_provider: [\"cas3\"]")
        end
      end

      context 'sync profile from omniauth provider is configured to true' do
        it 'sets the sync profile from provider to true' do
          stub_gitlab_rb(gitlab_rails: { omniauth_sync_profile_from_provider: true })

          expect(chef_run).to render_file(gitlab_yml_path)
              .with_content("sync_profile_from_provider: true")
        end
      end

      context 'sync profile attributes is configured to [\"email\", \"name\"]' do
        it 'sets the sync profile attributes to [\"email\", \"name\"]' do
          stub_gitlab_rb(gitlab_rails: { omniauth_sync_profile_attributes: %w(email name) })

          expect(chef_run).to render_file(gitlab_yml_path)
                                  .with_content("sync_profile_attributes: [\"email\",\"name\"]")
        end
      end

      context 'sync profile attributes is configured to true' do
        it 'sets the sync profile attributes to true' do
          stub_gitlab_rb(gitlab_rails: { omniauth_sync_profile_attributes: true })

          expect(chef_run).to render_file(gitlab_yml_path)
                                  .with_content("sync_profile_attributes: true")
        end
      end

      context 'Sidekiq log_format' do
        it 'sets the Sidekiq log_format to default' do
          expect(chef_run).to render_file(gitlab_yml_path)
                                  .with_content("log_format: default")
          expect(chef_run).to render_file("/opt/gitlab/sv/sidekiq/log/run").with_content(/svlogd -tt/)
        end

        it 'sets the Sidekiq log_format to json' do
          stub_gitlab_rb(sidekiq: { log_format: 'json' })

          expect(chef_run).to render_file(gitlab_yml_path)
                                  .with_content("log_format: json")
          expect(chef_run).not_to render_file("/opt/gitlab/sv/sidekiq/log/run").with_content(/-tt/)
        end
      end
    end

    context 'GitLab Geo settings' do
      let(:chef_run) do
        ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab-ee::default')
      end

      context 'when repository sync worker is configured' do
        it 'sets the cron value' do
          stub_gitlab_rb(gitlab_rails: { geo_repository_sync_worker_cron: '1 2 3 4 5' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/geo_repository_sync_worker:\s+cron:\s+"1 2 3 4 5"/)
        end
      end

      context 'when repository sync worker is not configured' do
        it 'does not set the cron value' do
          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            expect(content).not_to include('geo_repository_sync_worker')
          }
        end
      end

      context 'when geo prune event log worker is configured' do
        it 'sets the cron value' do
          stub_gitlab_rb(gitlab_rails: { geo_prune_event_log_worker_cron: '5 4 3 2 1' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/geo_prune_event_log_worker:\s+cron:\s+"5 4 3 2 1"/)
        end
      end

      context 'when geo prune event log worker is not configured' do
        it 'does not set the cron value' do
          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            expect(content).not_to include('geo_prune_event_log_worker')
          }
        end
      end

      context 'when file download dispatch worker is configured' do
        it 'sets the cron value' do
          stub_gitlab_rb(gitlab_rails: { geo_file_download_dispatch_worker_cron: '1 2 3 4 5' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/geo_file_download_dispatch_worker:\s+cron:\s+"1 2 3 4 5"/)
        end
      end

      context 'when file download dispatch worker is not configured' do
        it 'does not set the cron value' do
          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            expect(content).not_to include('geo_file_download_dispatch_worker')
          }
        end
      end

      context 'when repository verification primary batch worker is configured' do
        it 'sets the cron value' do
          stub_gitlab_rb(gitlab_rails: { geo_repository_verification_primary_batch_worker_cron: '1 2 3 4 5' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/geo_repository_verification_primary_batch_worker:\s+cron:\s+"1 2 3 4 5"/)
        end
      end

      context 'when repository verification primary batch worker is not configured' do
        it 'does not set the cron value' do
          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            expect(content).not_to include('geo_repository_verification_primary_batch_worker')
          }
        end
      end

      context 'when repository verification secondary scheduler worker is configured' do
        it 'sets the cron value' do
          stub_gitlab_rb(gitlab_rails: { geo_repository_verification_secondary_scheduler_worker_cron: '1 2 3 4 5' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/geo_repository_verification_secondary_scheduler_worker:\s+cron:\s+"1 2 3 4 5"/)
        end
      end

      context 'when repository verification secondary scheduler worker is not configured' do
        it 'does not set the cron value' do
          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            expect(content).not_to include('geo_repository_verification_secondary_scheduler_worker')
          }
        end
      end

      context 'when migrated local files cleanup worker is configured' do
        it 'sets the cron value' do
          stub_gitlab_rb(gitlab_rails: { geo_migrated_local_files_clean_up_worker_cron: '1 2 3 4 5' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/geo_migrated_local_files_clean_up_worker:\s+cron:\s+"1 2 3 4 5"/)
        end
      end

      context 'when migrated local files cleanup worker is not configured' do
        it 'does not set the cron value' do
          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            expect(content).not_to include('geo_migrated_local_files_clean_up_worker')
          }
        end
      end

      context 'when pseudonymizer worker is configured' do
        it 'sets the cron value' do
          stub_gitlab_rb(gitlab_rails: { pseudonymizer_worker_cron: '1 2 3 4 5' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/pseudonymizer_worker:\s+cron:\s+"1 2 3 4 5"/)
        end
      end

      context 'when pseudonymizer worker is not configured' do
        it 'does not set the cron value' do
          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            expect(content).not_to include('pseudonymizer_worker')
          }
        end
      end
    end

    context 'Scheduled Pipeline settings' do
      context 'when the cron pattern is configured' do
        it 'sets the cron value' do
          stub_gitlab_rb(gitlab_rails: { pipeline_schedule_worker_cron: '41 * * * *' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/pipeline_schedule_worker:\s+cron:\s+"41/)
        end
      end

      context 'when the cron pattern is not configured' do
        it 'sets no value' do
          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/pipeline_schedule_worker:\s+cron:\s[^"]+/)
        end
      end
    end

    context 'Monitoring settings' do
      context 'by default' do
        it 'whitelists local subnet' do
          expect(chef_run).to render_file(gitlab_yml_path)
                                .with_content(%r{monitoring:\s+(.+\s+){3}ip_whitelist:\s+- "127.0.0.0/8"\s+- "::1/128"})
        end
        it 'sampler will sample every 10s' do
          expect(chef_run).to render_file(gitlab_yml_path)
                                .with_content(%r{monitoring:\s+(.+\s+)unicorn_sampler_interval: 10})
        end
      end

      context 'when ip whitelist is configured' do
        before do
          stub_gitlab_rb(gitlab_rails: { monitoring_whitelist: %w(1.0.0.0 2.0.0.0) })
        end
        it 'sets the whitelist' do
          expect(chef_run).to render_file(gitlab_yml_path)
                                .with_content(%r{monitoring:\s+(.+\s+){3}ip_whitelist:\s+- "1.0.0.0"\s+- "2.0.0.0"})
        end
      end

      context 'when unicorn sampler interval is configured' do
        before do
          stub_gitlab_rb(gitlab_rails: { monitoring_unicorn_sampler_interval: 123 })
        end

        it 'sets the interval value' do
          expect(chef_run).to render_file(gitlab_yml_path)
                                .with_content(%r{monitoring:\s+(.+\s+)unicorn_sampler_interval: 123})
        end
      end
    end

    context 'Gitaly settings' do
      it 'renders client_path' do
        expect(chef_run).to render_file(gitlab_yml_path)
          .with_content(%r{gitaly:\s+client_path: /opt/gitlab/embedded/bin\s})
      end

      context 'when a global token is set' do
        let(:token) { '123secret456gitaly' }

        it 'renders the token in the gitaly section' do
          stub_gitlab_rb(gitlab_rails: { gitaly_token: token })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(%r{gitaly:\s+client_path: /opt/gitlab/embedded/bin\s+token: "#{token}"})
        end
      end
    end

    context 'GitLab Shell settings' do
      context 'when git_timeout is configured' do
        it 'sets the git_timeout value' do
          stub_gitlab_rb(gitlab_rails: { gitlab_shell_git_timeout: '1000' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/git_timeout:\s+1000/)
        end
      end

      context 'when git_timeout is not configured' do
        it 'sets git_timeout value to default' do
          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/git_timeout:\s+10800/)
        end
      end
    end

    context 'GitLab LDAP cron_jobs settings' do
      context 'when ldap user sync worker is configured' do
        it 'sets the cron value' do
          stub_gitlab_rb(gitlab_rails: { ldap_sync_worker_cron: '40 2 * * *' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/ldap_sync_worker:\s+cron:\s+"40 2 \* \* \*"/)
        end
      end

      context 'when ldap user sync worker is not configured' do
        it 'does not set the cron value' do
          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            expect(content).not_to include('ldap_sync_worker')
          }
        end
      end

      context 'when ldap group sync worker is configured' do
        it 'sets the cron value' do
          stub_gitlab_rb(gitlab_rails: { ldap_group_sync_worker_cron: '1 0 * * *' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/ldap_group_sync_worker:\s+cron:\s+"1 0 \* \* \*"/)
        end
      end

      context 'when ldap group sync worker is not configured' do
        it 'does not set the cron value' do
          expect(chef_run).to render_file(gitlab_yml_path).with_content { |content|
            expect(content).not_to include('ldap_group_sync_worker')
          }
        end
      end
    end

    context 'GitLab LDAP settings' do
      context 'when ldap lowercase_usernames setting is' do
        it 'set, sets the setting value' do
          stub_gitlab_rb(gitlab_rails: { ldap_lowercase_usernames: true })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/lowercase_usernames: true/)
        end

        it 'not set, sets default value to blank' do
          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/lowercase_usernames:\s$/)
        end
      end
    end

    context 'Rescue stale live trace settings' do
      context 'when the cron pattern is configured' do
        it 'sets the cron value' do
          stub_gitlab_rb(gitlab_rails: { ci_archive_traces_cron_worker_cron: '17 * * * *' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/ci_archive_traces_cron_worker:\s+cron:\s+"17/)
        end
      end

      context 'when the cron pattern is not configured' do
        it 'sets no value' do
          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/ci_archive_traces_cron_worker:\s+cron:\s[^"]+/)
        end
      end
    end

    context 'GitLab Pages verification cron job settings' do
      context 'when the cron pattern is configured' do
        it 'sets the value' do
          stub_gitlab_rb(gitlab_rails: { pages_domain_verification_cron_worker: '1 0 * * *' })

          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/pages_domain_verification_cron_worker:\s+cron:\s+"1 0 \* \* \*"/)
        end
      end
      context 'when pages domain verification cron worker is not configured' do
        it ' sets no value' do
          expect(chef_run).to render_file(gitlab_yml_path)
            .with_content(/pages_domain_verification_cron_worker:\s+cron:\s[^"]+/)
        end
      end
    end
  end

  context 'with environment variables' do
    context 'by default' do
      it_behaves_like "enabled gitlab-rails env", "HOME", '\/var\/opt\/gitlab'
      it_behaves_like "enabled gitlab-rails env", "RAILS_ENV", 'production'
      it_behaves_like "enabled gitlab-rails env", "SIDEKIQ_MEMORY_KILLER_MAX_RSS", '2000000'
      it_behaves_like "enabled gitlab-rails env", "BUNDLE_GEMFILE", '\/opt\/gitlab\/embedded\/service\/gitlab-rails\/Gemfile'
      it_behaves_like "enabled gitlab-rails env", "PATH", '\/opt\/gitlab\/bin:\/opt\/gitlab\/embedded\/bin:\/bin:\/usr\/bin'
      it_behaves_like "enabled gitlab-rails env", "ICU_DATA", '\/opt\/gitlab\/embedded\/share\/icu\/current'
      it_behaves_like "enabled gitlab-rails env", "PYTHONPATH", '\/opt\/gitlab\/embedded\/lib\/python3.4\/site-packages'

      it_behaves_like "enabled gitlab-rails env", "LD_PRELOAD", '\/opt\/gitlab\/embedded\/lib\/libjemalloc.so'
      it_behaves_like "disabled gitlab-rails env", "RAILS_RELATIVE_URL_ROOT", ''

      context 'when a custom env variable is specified' do
        before do
          stub_gitlab_rb(gitlab_rails: { env: { 'IAM' => 'CUSTOMVAR' } })
        end

        it_behaves_like "enabled gitlab-rails env", "IAM", 'CUSTOMVAR'
        it_behaves_like "enabled gitlab-rails env", "ICU_DATA", '\/opt\/gitlab\/embedded\/share\/icu\/current'
        it_behaves_like "enabled gitlab-rails env", "LD_PRELOAD", '\/opt\/gitlab\/embedded\/lib\/libjemalloc.so'
      end
    end

    context 'when relative URL is enabled' do
      before do
        stub_gitlab_rb(gitlab_rails: { gitlab_relative_url: '/gitlab' })
      end

      it_behaves_like "enabled gitlab-rails env", "RAILS_RELATIVE_URL_ROOT", '/gitlab'
    end

    context 'when relative URL is specified in external_url' do
      before do
        stub_gitlab_rb(external_url: 'http://localhost/gitlab')
      end

      it_behaves_like "enabled gitlab-rails env", "RAILS_RELATIVE_URL_ROOT", '/gitlab'
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
      %w(
        alertmanager
        gitlab-monitor
        gitlab-pages
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
        unicorn
        gitaly
      ).map { |svc| stub_should_notify?(svc, true) }
    end

    describe 'database.yml' do
      let(:templatesymlink) { chef_run.templatesymlink('Create a database.yml and create a symlink to Rails root') }

      context 'by default' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default')
        end

        it 'creates the template' do
          expect(chef_run).to create_template('/var/opt/gitlab/gitlab-rails/etc/database.yml')
            .with(
              owner: 'root',
              group: 'git',
              mode: '0640'
            )
          expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content { |content|
            expect(content).to match(/host: \"\/var\/opt\/gitlab\/postgresql\"/)
            expect(content).to match(/database: gitlabhq_production/)
            expect(content).to match(/load_balancing: {"hosts":\[\]}/)
            expect(content).to match(/prepared_statements: false/)
            expect(content).to match(/statements_limit: 1000/)
            expect(content).to match(/sslcompression: 0/)
            expect(content).to match(/fdw:\s*$/)
          }
        end

        it 'template triggers notifications' do
          expect(templatesymlink).to notify('service[unicorn]').to(:restart).delayed
          expect(templatesymlink).to notify('service[sidekiq]').to(:restart).delayed
          expect(templatesymlink).not_to notify('service[gitlab-workhorse]').to(:restart).delayed
          expect(templatesymlink).not_to notify('service[nginx]').to(:restart).delayed
        end

        it 'creates the symlink' do
          expect(chef_run).to create_link("Link /opt/gitlab/embedded/service/gitlab-rails/config/database.yml to /var/opt/gitlab/gitlab-rails/etc/database.yml")
        end
      end

      context 'with specific database settings' do
        context 'when multiple postgresql listen_address is used' do
          before do
            stub_gitlab_rb(postgresql: { listen_address: "127.0.0.1,1.1.1.1" })
          end

          it 'creates the postgres configuration file with multi listen_address and database.yml file with one host' do
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/host: "127.0.0.1"/)
            expect(chef_run).to render_file('/var/opt/gitlab/postgresql/data/postgresql.conf').with_content(/listen_addresses = '127.0.0.1,1.1.1.1'/)
          end
        end

        context 'when no postgresql listen_address is used' do
          it 'creates the postgres configuration file with empty listen_address and database.yml file with default one' do
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/host: "\/var\/opt\/gitlab\/postgresql"/)
            expect(chef_run).to render_file('/var/opt/gitlab/postgresql/data/postgresql.conf').with_content(/listen_addresses = ''/)
          end
        end

        context 'when one postgresql listen_address is used' do
          cached(:chef_run) do
            RSpec::Mocks.with_temporary_scope do
              stub_gitlab_rb(postgresql: { listen_address: "127.0.0.1" })
            end

            ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default')
          end

          it 'creates the postgres configuration file with one listen_address and database.yml file with one host' do
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/host: "127.0.0.1"/)
            expect(chef_run).to render_file('/var/opt/gitlab/postgresql/data/postgresql.conf').with_content(/listen_addresses = '127.0.0.1'/)
          end

          it 'template triggers notifications' do
            expect(templatesymlink).to notify('service[unicorn]').to(:restart).delayed
            expect(templatesymlink).to notify('service[sidekiq]').to(:restart).delayed
            expect(templatesymlink).not_to notify('service[gitlab-workhorse]').to(:restart).delayed
            expect(templatesymlink).not_to notify('service[nginx]').to(:restart).delayed
          end

          it 'creates the symlink' do
            expect(chef_run).to create_link("Link /opt/gitlab/embedded/service/gitlab-rails/config/database.yml to /var/opt/gitlab/gitlab-rails/etc/database.yml")
          end
        end

        context 'when load balancers are specified' do
          before do
            stub_gitlab_rb(gitlab_rails: { db_load_balancing: { 'hosts' => ['primary.example.com', 'secondary.example.com'] } })
          end

          it 'uses provided value in database.yml' do
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/load_balancing: {"hosts":\["primary.example.com","secondary.example.com"\]}/)
          end
        end

        context 'when prepared_statements are disabled' do
          before do
            stub_gitlab_rb(gitlab_rails: { db_prepared_statements: false })
          end

          it 'uses provided value in database.yml' do
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/prepared_statements: false/)
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/statements_limit: 1000/)
          end
        end

        context 'when limit for prepared_statements are specified' do
          before do
            stub_gitlab_rb(gitlab_rails: { db_statements_limit: 12345 })
          end

          it 'uses provided value in database.yml' do
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/statements_limit: 12345/)
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/prepared_statements: false/)
          end
        end

        context 'when SSL compression is enabled' do
          before do
            stub_gitlab_rb(gitlab_rails: { db_sslcompression: 1 })
          end

          it 'uses provided value in database.yml' do
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/sslcompression: 1/)
          end
        end

        context 'when fdw is specified' do
          before do
            stub_gitlab_rb(gitlab_rails: { db_fdw: true })
          end

          it 'uses provided value in database.yml' do
            expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/database.yml').with_content(/fdw: true/)
          end
        end
      end
    end

    describe 'gitlab_workhorse_secret' do
      let(:templatesymlink) { chef_run.templatesymlink('Create a gitlab_workhorse_secret and create a symlink to Rails root') }

      context 'by default' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default')
        end

        it 'creates the template' do
          expect(chef_run).to create_template('/var/opt/gitlab/gitlab-rails/etc/gitlab_workhorse_secret')
            .with(
              owner: 'root',
              group: 'root',
              mode: '0644'
            )
        end

        it 'template triggers notifications' do
          expect(templatesymlink).to notify('service[gitlab-workhorse]').to(:restart).delayed
          expect(templatesymlink).to notify('service[unicorn]').to(:restart).delayed
          expect(templatesymlink).to notify('service[sidekiq]').to(:restart).delayed
        end

        it 'creates the symlink' do
          expect(chef_run).to create_link("Link /opt/gitlab/embedded/service/gitlab-rails/.gitlab_workhorse_secret to /var/opt/gitlab/gitlab-rails/etc/gitlab_workhorse_secret")
        end
      end

      context 'with specific gitlab_workhorse_secret' do
        cached(:chef_run) do
          RSpec::Mocks.with_temporary_scope do
            stub_gitlab_rb(gitlab_workhorse: { secret_token: 'abc123-gitlab-workhorse' })
          end

          ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default')
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
              mode: '0644'
            )
        end

        it 'template triggers notifications' do
          expect(templatesymlink).to notify('service[gitlab-workhorse]').to(:restart).delayed
          expect(templatesymlink).to notify('service[unicorn]').to(:restart).delayed
          expect(templatesymlink).to notify('service[sidekiq]').to(:restart).delayed
        end

        it 'creates the symlink' do
          expect(chef_run).to create_link("Link /opt/gitlab/embedded/service/gitlab-rails/.gitlab_workhorse_secret to /var/opt/gitlab/gitlab-rails/etc/gitlab_workhorse_secret")
        end
      end
    end

    describe 'gitlab_pages_secret' do
      let(:templatesymlink) { chef_run.templatesymlink('Create a gitlab_pages_secret and create a symlink to Rails root') }
      let(:pages_secret_path) { '/var/opt/gitlab/gitlab-rails/etc/gitlab_pages_secret' }

      context 'by default' do
        cached(:chef_run) do
          RSpec::Mocks.with_temporary_scope do
            stub_gitlab_rb(
              external_url: 'http://gitlab.example.com',
              pages_external_url: 'http://pages.example.com'
            )
          end

          ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default')
        end

        it 'creates the template' do
          expect(chef_run).to create_template(pages_secret_path)
            .with(
              owner: 'root',
              group: 'git',
              mode: '0640'
            )
        end

        it 'template triggers notifications' do
          expect(templatesymlink).to notify('service[gitlab-pages]').to(:restart).delayed
          expect(templatesymlink).to notify('service[unicorn]').to(:restart).delayed
          expect(templatesymlink).to notify('service[sidekiq]').to(:restart).delayed
        end

        it 'creates the symlink' do
          expect(chef_run).to create_link("Link /opt/gitlab/embedded/service/gitlab-rails/.gitlab_pages_secret to #{pages_secret_path}")
        end
      end

      context 'with specific gitlab_pages_secret' do
        cached(:chef_run) do
          RSpec::Mocks.with_temporary_scope do
            stub_gitlab_rb(
              external_url: 'http://gitlab.example.com',
              pages_external_url: 'http://pages.example.com',
              gitlab_pages: {
                admin_secret_token: 'abc123-gitlab-pages'
              }
            )
          end

          ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default')
        end

        it 'renders the correct node attribute' do
          expect(chef_run).to render_file(pages_secret_path)
            .with_content('abc123-gitlab-pages')
        end

        it 'uses the correct owner and permissions' do
          expect(chef_run).to create_template(pages_secret_path)
            .with(
              owner: 'root',
              group: 'git',
              mode: '0640'
            )
        end

        it 'template triggers notifications' do
          expect(templatesymlink).to notify('service[gitlab-pages]').to(:restart).delayed
          expect(templatesymlink).to notify('service[unicorn]').to(:restart).delayed
          expect(templatesymlink).to notify('service[sidekiq]').to(:restart).delayed
        end

        it 'creates the symlink' do
          expect(chef_run).to create_link("Link /opt/gitlab/embedded/service/gitlab-rails/.gitlab_pages_secret to #{pages_secret_path}")
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
    end
  end
end
