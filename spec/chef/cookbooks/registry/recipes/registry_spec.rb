require 'chef_helper'

RSpec.describe 'registry recipe' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service registry_database_objects nginx_configuration)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  it 'sets default attributes' do
    expect(chef_run.node['registry']['auto_migrate']).to eq(true)
    expect(chef_run.node['registry']['database']['enabled']).to eq(false)
    expect(chef_run.node['registry']['database']['user']).to eq('registry')
    expect(chef_run.node['registry']['database']['dbname']).to eq('registry')
    expect(chef_run.node['registry']['database']['port']).to eq(5432)
    expect(chef_run.node['registry']['database']['sslmode']).to eq('prefer')
  end

  describe 'letsencrypt' do
    before do
      stub_gitlab_rb(
        external_url: 'https://gitlab.example.com',
        registry_external_url: 'https://registry.example.com'
      )

      allow(File).to receive(:exist?).and_call_original
    end

    describe 'HTTP to HTTPS redirection' do
      context 'by default' do
        it 'is enabled' do
          expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/service_conf/gitlab-registry.conf').with_content("return 301 https://registry.example.com$request_uri;")
        end
      end

      context 'if disabled in gitlab.rb' do
        before do
          stub_gitlab_rb(
            external_url: 'https://gitlab.example.com',
            registry_external_url: 'https://registry.example.com',
            registry_nginx: {
              redirect_http_to_https: false
            }
          )
        end

        it 'is disabled' do
          expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/service_conf/gitlab-registry.conf')
          expect(chef_run).not_to render_file('/var/opt/gitlab/nginx/conf/service_conf/gitlab-registry.conf').with_content("return 301 https://registry.example.com$request_uri;")
        end
      end

      context 'registry on gitlab domain with a different port ' do
        before do
          stub_gitlab_rb(
            external_url: 'https://gitlab.example.com',
            registry_external_url: 'https://gitlab.example.com:5005'
          )
        end

        it 'is enabled and has correct redirect URL in nginx config' do
          expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/service_conf/gitlab-registry.conf').with_content("return 301 https://gitlab.example.com:5005$request_uri;")
        end
      end
    end

    context 'default certificate file is missing' do
      before do
        allow(File).to receive(:exist?).with('/etc/gitlab/ssl/registry.example.com.crt').and_return(false)
      end

      it 'adds itself to letsencrypt alt_names' do
        expect(chef_run.node['letsencrypt']['alt_names']).to match_array(['gitlab.example.com', 'registry.example.com'])
      end

      it 'is reflected in the acme_selfsigned' do
        expect(chef_run).to create_acme_selfsigned('gitlab.example.com').with(
          alt_names: match_array(['gitlab.example.com', 'registry.example.com'])
        )
      end
    end

    context 'default certificate file is present' do
      before do
        allow(File).to receive(:exist?).with('/etc/gitlab/ssl/registry.example.com.crt').and_return(true)
      end

      it 'does not alter letsencrypt alt_names' do
        expect(chef_run.node['letsencrypt']['alt_names']).to eql(['gitlab.example.com'])
      end

      it 'is reflected in the acme_selfsigned' do
        expect(chef_run).to create_acme_selfsigned('gitlab.example.com').with(
          alt_names: ['gitlab.example.com']
        )
      end
    end
  end

  context 'when registry is enabled' do
    before { stub_gitlab_rb(registry_external_url: 'https://registry.example.com') }

    it_behaves_like 'enabled registry service'

    it_behaves_like 'renders a valid YAML file', '/var/opt/gitlab/registry/config.yml'

    it 'includes the database_migrations recipe' do
      expect(chef_run).to include_recipe('registry::database_migrations')
    end

    it 'creates the registry user and group with the correct parameters' do
      expect(chef_run).to create_account('Docker registry user and group').with(username: 'registry', groupname: 'registry', shell: '/usr/sbin/nologin', home: '/var/opt/gitlab/registry')
    end

    it 'creates a default VERSION file and restarts service' do
      expect(chef_run).to create_version_file('Create version file for Registry').with(
        version_file_path: '/var/opt/gitlab/registry/VERSION',
        version_check_cmd: '/opt/gitlab/embedded/bin/registry --version'
      )

      expect(chef_run.version_file('Create version file for Registry')).to notify('runit_service[registry]').to(:restart)
    end

    context 'when registry storagedriver health check is disabled' do
      before { stub_gitlab_rb(registry: { health_storagedriver_enabled: false }) }

      it 'creates registry config with specified value' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/health:\s*storagedriver:\s*enabled:\s*false/)
      end
    end

    context 'when registry validation is enabled' do
      before { stub_gitlab_rb(registry: { validation_enabled: true }) }

      it 'creates registry config with specified value' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/^validation:\s*disabled: false$/)
      end
    end

    context 'when registry middleware is enabled' do
      let(:middleware_config) do
        { "storage" => [
          { "name" => "googlecdn",
            "options" => {
              "baseurl" => "https://example.org",
              "privatekey" => "/etc/gitlab/googlecdn.key",
              "keyname" => "example-key"
            } }
        ] }
      end

      before { stub_gitlab_rb(registry: { middleware: middleware_config }) }

      it 'creates registry config with middleware' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(%r(^middleware: {"storage":))
      end
    end

    context "when GitLab-managed PostgreSQL is enabled" do
      before { stub_gitlab_rb(postgresql: { enable: true }) }

      it 'populates default registry database config' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content('database: {"enabled":false,"user":"registry","dbname":"registry","port":5432,"sslmode":"prefer","host":"/var/opt/gitlab/postgresql"}')
      end
    end

    context 'when registry reporting is enabled' do
      let(:reporting_config) do
        { "sentry" => {
          "enabled" => true,
          "dsn" => "https://<key>@sentry.io/<project>",
          "environment" => "production"
        } }
      end

      before { stub_gitlab_rb(registry: { reporting: reporting_config }) }

      it 'creates registry config with reporting' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content('reporting: {"sentry":{"enabled":true,"dsn":"https://<key>@sentry.io/<project>","environment":"production"}}')
      end
    end

    context 'when the registry metadata database is enabled' do
      let(:database_config) do
        { "enabled" => true,
          "host" => "localhost",
          "port" => 5432,
          "user" => "postgres",
          "password" => "postgres",
          "dbname" => "registry",
          "sslmode" => "verify-full",
          "sslcert" => "/path/to/client.crt",
          "sslkey" => "/path/to/client.key",
          "sslrootcert" => "/path/to/root.crt",
          "connecttimeout" => "5s",
          "draintimeout" => "2m",
          "preparedstatements" => false,
          "primary" => "primary.record.fqdn",
          "pool" => {
            "maxidle" => 25,
            "maxopen" => 25,
            "maxlifetime" => "5m"
          } }
      end

      before do
        stub_gitlab_rb(registry: { database: database_config })
        allow_any_instance_of(RegistryPgHelper).to receive(:is_ready?).and_return(true)
      end

      it 'creates registry config with database' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(%r(^database: {"enabled":true))
      end
    end

    context 'when the registry garbage collector configuration is present' do
      let(:gc_config) do
        { "disabled" => false,
          "maxbackoff" => "24h",
          "noidlebackoff" => false,
          "transactiontimeout" => "10s",
          "reviewafter" => "24h",
          "manifests" => {
            "disabled" => false,
            "interval" => "5s"
          },
          "blobs" => {
            "disabled" => false,
            "interval" => "5s",
            "storagetimeout" => "5s"
          } }
      end

      before { stub_gitlab_rb(registry: { gc: gc_config }) }

      it 'creates registry config with gc' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(%r(^gc: {"disabled":false))
      end
    end

    context 'when a log formatter is specified' do
      before { stub_gitlab_rb(registry: { log_formatter: 'json' }) }

      it 'creates the registry config with the specified value' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/log:\s*level: info\s*formatter:\s*json/)
      end

      it 'does not append timestamp in logs if logging format is json' do
        expect(chef_run).to render_file('/opt/gitlab/sv/registry/log/run')
          .with_content(/svlogd \/var\/log\/gitlab\/registry/)
      end
    end

    context 'when schema1 compatibility is enabled' do
      before { stub_gitlab_rb(registry: { compatibility_schema1_enabled: true }) }

      it 'creates registry config with specified value' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/compatibility:\s*schema1:\s*enabled:\s*true/)
      end
    end
  end

  context 'when registry port is specified' do
    before { stub_gitlab_rb(registry_external_url: 'https://registry.example.com', registry: { registry_http_addr: 'localhost:5001' }) }

    it 'creates registry and rails configs with specified value' do
      expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(hash_including('registry_api_url' => 'http://localhost:5001'))

      expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
        .with_content(/addr: localhost:5001/)
    end
  end

  context 'when a debug addr is specified' do
    before { stub_gitlab_rb(registry_external_url: 'https://registry.example.com', registry: { debug_addr: 'localhost:5005' }) }

    it 'creates the registry config with the specified debug value' do
      expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
        .with_content(/debug:\n\s*addr: localhost:5005/)
    end
  end

  context 'registry database objects' do
    context 'when PostgreSQL is enabled' do
      before do
        stub_gitlab_rb(
          registry_external_url: 'https://registry.example.com',
          postgresql: { enable: true }
        )
      end

      it 'creates registry_database_objects resource with only_if condition' do
        expect(chef_run).to create_registry_database_objects('default')

        # Find the resource and verify it exists
        resource = chef_run.find_resource(:registry_database_objects, 'default')
        expect(resource).not_to be_nil

        # Since postgresql is enabled, the resource should be created
        expect(chef_run.node.dig('postgresql', 'enable')).to be_truthy
      end

      it 'creates postgresql_user and postgresql_database when registry_database_objects is executed' do
        expect(chef_run).to create_postgresql_user('registry')
        expect(chef_run).to create_postgresql_database('registry')
      end
    end

    context 'when PostgreSQL is disabled' do
      before do
        stub_gitlab_rb(
          registry_external_url: 'https://registry.example.com',
          postgresql: { enable: false }
        )
      end

      it 'creates registry_database_objects resource but does not execute due to only_if condition' do
        # The resource should not be created at all when postgresql is disabled
        # because the only_if condition prevents it from being included in the resource collection
        expect(chef_run).not_to create_registry_database_objects('default')

        # Verify postgresql is disabled in the node
        expect(chef_run.node.dig('postgresql', 'enable')).to be_falsey
      end

      it 'does not create postgresql_user and postgresql_database when only_if condition is false' do
        expect(chef_run).not_to create_postgresql_user('registry')
        expect(chef_run).not_to create_postgresql_database('registry')
      end
    end
  end

  context 'when user and group are specified' do
    before { stub_gitlab_rb(registry_external_url: 'https://registry.example.com', registry: { username: 'registryuser', group: 'registrygroup' }) }
    it 'make registry run file start registry under correct user' do
      expect(chef_run).to render_file('/opt/gitlab/sv/registry/run')
        .with_content(/-U registryuser:registrygroup/)
      expect(chef_run).to render_file('/opt/gitlab/sv/registry/run')
        .with_content(/-u registryuser:registrygroup/)
    end
  end
end

RSpec.describe 'registry' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service registry_database_objects)).converge('gitlab::default') }
  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/',
      'GODEBUG' => "tlsmlkem=0",
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when registry is enabled' do
    before { stub_gitlab_rb(registry_external_url: 'https://registry.example.com') }

    it_behaves_like 'enabled registry service'

    context 'when custom storage parameters are specified' do
      before do
        stub_gitlab_rb(
          registry: {
            storage: {
              s3: { accesskey: 'awsaccesskey', secretkey: 'awssecretkey', bucketname: 'bucketname' }
            }
          }
        )
      end

      it 'uses custom storage instead of the default rootdirectory' do
        expect(chef_run.node['registry']['storage'])
          .to include(s3: { accesskey: 'awsaccesskey', secretkey: 'awssecretkey', bucketname: 'bucketname' })
        expect(chef_run.node['registry']['storage'])
          .not_to include('rootdirectory' => '/var/opt/gitlab/gitlab-rails/shared/registry')
      end

      it 'uses the default cache and delete settings if not overridden' do
        expect(chef_run.node['registry']['storage']['cache'])
          .to eql('blobdescriptor' => 'inmemory')
        expect(chef_run.node['registry']['storage']['delete'])
          .to eql('enabled' => true)
      end

      it 'allows the cache and delete settings to be overridden' do
        stub_gitlab_rb(registry: { storage: { cache: 'somewhere-else', delete: { enabled: false } } })
        expect(chef_run.node['registry']['storage']['cache'])
          .to eql('somewhere-else')
        expect(chef_run.node['registry']['storage']['delete'])
          .to eql('enabled' => false)
      end
    end

    context 'when storage_delete_enabled is false' do
      before { stub_gitlab_rb(registry: { storage_delete_enabled: false }) }

      it 'sets the delete enabled field on the storage object' do
        expect(chef_run.node['registry']['storage']['delete'])
          .to eql('enabled' => false)
      end
    end

    context 'when notification is configured for Geo replication' do
      before do
        stub_gitlab_rb(
          registry: {
            notifications: [
              {
                'name' => 'geo_event',
                'url' => 'https://registry.example.com/notify',
                'timeout' => '500ms',
                'threshold' => 5,
                'backoff' => '1s',
                'headers' => {
                  "Authorization" => ["mysecret"]
                }
              }
            ]
          }
        )
      end

      it 'assigns registry_notification_secret variable automatically' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"Authorization":\["mysecret"\]/)
        expect(chef_run.node['gitlab']['gitlab_rails']['registry_notification_secret'])
          .to eql('mysecret')
      end
    end

    context 'when registry notification endpoint is configured with the minimum required' do
      before do
        stub_gitlab_rb(
          registry: {
            notifications: [
              name: 'test_endpoint',
              url: 'https://registry.example.com/notify'
            ]
          }
        )
      end

      it 'creates the registry config with the specified endpoint config' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"name":"test_endpoint"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"url":"https:\/\/registry.example.com\/notify"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"timeout":"500ms"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"threshold":5/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"backoff":"1s"/)
      end
    end

    context 'when the default values are overridden' do
      before do
        stub_gitlab_rb(
          registry: {
            notifications: [
              name: 'test_endpoint',
              url: 'https://registry.example.com/notify'
            ],
            default_notifications_timeout: '5000ms',
            default_notifications_threshold: 10,
            default_notifications_maxretries: 5,
            default_notifications_backoff: '50s',
            default_notifications_headers: {
              "Authorization" => %w(AUTHORIZATION_EXAMPLE_TOKEN1 AUTHORIZATION_EXAMPLE_TOKEN2)
            }
          }
        )
      end

      it 'creates the registry config overriding the values not set with the new defaults' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"name":"test_endpoint"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"url":"https:\/\/registry.example.com\/notify"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"timeout":"5000ms"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"threshold":10/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"maxretries":5/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"backoff":"50s"/)
      end
    end

    context 'when registry notification endpoint is configured with all the available variables' do
      before do
        stub_gitlab_rb(
          registry: {
            notifications: [
              {
                'name' => 'test_endpoint',
                'url' => 'https://registry.example.com/notify',
                'timeout' => '500ms',
                'threshold' => 5,
                'backoff' => '1s',
                'headers' => {
                  "Authorization" => ["AUTHORIZATION_EXAMPLE_TOKEN"]
                }
              }
            ]
          }
        )
      end

      it 'creates the registry config with the specified endpoint config' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"name":"test_endpoint"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"url":"https:\/\/registry.example.com\/notify"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"timeout":"500ms"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"threshold":5/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"backoff":"1s"/)
      end
    end

    context 'when 3 registry notification endpoints are configured' do
      before do
        stub_gitlab_rb(
          registry: {
            notifications: [
              {
                'name' => 'test_endpoint',
                'url' => 'https://registry.example.com/notify'
              },
              {
                'name' => 'test_endpoint2',
                'url' => 'https://registry.example.com/notify2',
                'timeout' => '100ms',
                'threshold' => 2,
                'backoff' => '4s',
                'headers' => {
                  "Authorization" => ["AUTHORIZATION_EXAMPLE_TOKEN"]
                }
              },
              {
                'name' => 'test_endpoint3',
                'url' => 'https://registry.example.com/notify3'
              }
            ]
          }
        )
      end

      it 'creates the registry config with the specified endpoint config' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"name":"test_endpoint"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/\"url\":\"https:\/\/registry.example.com\/notify\"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"timeout":"500ms"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"threshold":5/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"backoff":"1s"/)
        # Second endpoint
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"name":"test_endpoint2"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"url":"https:\/\/registry.example.com\/notify2"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"timeout":"100ms"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"threshold":2/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"backoff":"4s"/)
        # Third endpoint
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"name":"test_endpoint3"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"url":"https:\/\/registry.example.com\/notify3"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"timeout":"500ms"/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"threshold":5/)
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/"backoff":"1s"/)
      end
    end

    context 'when registry notification endpoint is not configured' do
      it 'creates the registry config without the endpoint config' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
        expect(chef_run).not_to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content('notifications:')
      end
    end

    context 'when registry load balancing is enabled and configured' do
      before do
        stub_gitlab_rb(
          registry: {
            redis: {
              loadbalancing: {
                enabled: true,
                addr: 'redis1.local:6379,redis2.local:6379',
                username: 'redis',
                password: 'redis_password',
                mainname: 'main-redis',
                sentinelusername: 'sentinel',
                sentinelpassword: 'redis_sentinel_password',
                db: 1,
                dialtimeout: '5s',
                readtimeout: '10s',
                writetimeout: '15s',
                tls: {
                  enabled: true,
                  insecure: true
                },
                pool: {
                  size: 32,
                  maxlifetime: '2h',
                  idletimeout: '500s'
                }
              }
            }
          }
        )
      end

      it 'creates registry config with specified value' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content { |content|
            config = YAML.safe_load(content)

            expect(config['redis']).to eq({
                                            'loadbalancing' => {
                                              'enabled' => true,
                                              'addr' => 'redis1.local:6379,redis2.local:6379',
                                              'username' => 'redis',
                                              'password' => 'redis_password',
                                              'db' => 1,
                                              'mainname' => 'main-redis',
                                              'sentinelusername' => 'sentinel',
                                              'sentinelpassword' => 'redis_sentinel_password',
                                              'dialtimeout' => '5s',
                                              'readtimeout' => '10s',
                                              'writetimeout' => '15s',
                                              'tls' => {
                                                'enabled' => true,
                                                'insecure' => true
                                              },
                                              'pool' => {
                                                'size' => 32,
                                                'maxlifetime' => '2h',
                                                'idletimeout' => '500s'
                                              },
                                            }
                                          })
          }
      end
    end

    context 'when registry has custom environment variables configured' do
      before do
        stub_gitlab_rb(registry: { env: { 'HTTP_PROXY' => 'my-proxy' } })
      end

      it 'creates necessary env variable files' do
        expect(chef_run).to create_env_dir('/opt/gitlab/etc/registry/env').with_variables(
          default_vars.merge(
            {
              'HTTP_PROXY' => 'my-proxy'
            }
          )
        )
      end
    end
  end

  context 'log directory and runit group' do
    context 'default values' do
      before do
        stub_gitlab_rb({ registry_external_url: 'https://registry.example.com' })
      end
      it_behaves_like 'enabled logged service', 'registry', true, { log_directory_owner: 'registry' }
    end

    context 'custom values' do
      before do
        stub_gitlab_rb(
          registry_external_url: 'https://registry.example.com',
          registry: {
            enabled: true,
            log_group: 'fugee'
          }
        )
      end
      it_behaves_like 'enabled logged service', 'registry', true, { log_directory_owner: 'registry', log_group: 'fugee' }
    end
  end
end

RSpec.describe 'auto enabling registry' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service registry_database_objects nginx_configuration)).converge('gitlab::default') }
  let(:registry_config) { '/var/opt/gitlab/registry/config.yml' }
  let(:nginx_config) { '/var/opt/gitlab/nginx/conf/service_conf/gitlab-registry.conf' }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_gitlab_rb(
      external_url: 'https://gitlab.example.com'
    )
  end

  it_behaves_like 'enabled registry service'

  it 'should listen on port 5050 with nginx' do
    expect(chef_run).to render_file(nginx_config)
      .with_content { |content|
        expect(content).to include("listen *:5050 ssl;")
        expect(content).to include("server_name gitlab.example.com;")
      }
  end

  it "should use the default Let's Encrypt certificates" do
    expect(chef_run).to render_file(nginx_config)
      .with_content { |content|
        expect(content).to include("ssl_certificate /etc/gitlab/ssl/gitlab.example.com.crt;")
        expect(content).to include("ssl_certificate_key /etc/gitlab/ssl/gitlab.example.com.key;")
      }
  end

  it 'should point gitlab-rails to the registry' do
    expect(chef_run).to create_templatesymlink(
      'Create a gitlab.yml and create a symlink to Rails root'
    ).with_variables(
      hash_including(
        'registry_host' => 'gitlab.example.com',
        'registry_port' => '5050'
      )
    )
  end
end
