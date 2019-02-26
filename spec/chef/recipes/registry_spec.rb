require 'chef_helper'

describe 'registry recipe' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
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
          expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/gitlab-registry.conf').with_content("return 301 https://registry.example.com$request_uri;")
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
          expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/gitlab-registry.conf')
          expect(chef_run).not_to render_file('/var/opt/gitlab/nginx/conf/gitlab-registry.conf').with_content("return 301 https://registry.example.com$request_uri;")
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
          expect(chef_run).to render_file('/var/opt/gitlab/nginx/conf/gitlab-registry.conf').with_content("return 301 https://gitlab.example.com:5005$request_uri;")
        end
      end
    end

    context 'default certificate file is missing' do
      before do
        allow(File).to receive(:exist?).with('/etc/gitlab/ssl/registry.example.com.crt').and_return(false)
      end

      it 'adds itself to letsencrypt alt_names' do
        expect(chef_run.node['letsencrypt']['alt_names']).to eql(['registry.example.com'])
      end

      it 'is reflected in the acme_selfsigned' do
        expect(chef_run).to create_acme_selfsigned('gitlab.example.com').with(
          alt_names: ['registry.example.com']
        )
      end
    end

    context 'default certificate file is present' do
      before do
        allow(File).to receive(:exist?).with('/etc/gitlab/ssl/registry.example.com.crt').and_return(true)
      end

      it 'does not alter letsencrypt alt_names' do
        expect(chef_run.node['letsencrypt']['alt_names']).to eql([])
      end

      it 'is reflected in the acme_selfsigned' do
        expect(chef_run).to create_acme_selfsigned('gitlab.example.com').with(
          alt_names: []
        )
      end
    end
  end

  context 'when registry is enabled' do
    before { stub_gitlab_rb(registry_external_url: 'https://registry.example.com') }

    it 'creates default set of directories' do
      expect(chef_run.node['registry']['dir'])
        .to eql('/var/opt/gitlab/registry')
      expect(chef_run.node['registry']['log_directory'])
        .to eql('/var/log/gitlab/registry')
      expect(chef_run.node['gitlab']['gitlab-rails']['registry_path'])
        .to eql('/var/opt/gitlab/gitlab-rails/shared/registry')

      expect(chef_run).to create_directory('/var/opt/gitlab/registry')
      expect(chef_run).to create_directory('/var/log/gitlab/registry').with(
        owner: 'registry',
        group: nil,
        mode: '0700'
      )
      expect(chef_run).to create_directory('/var/opt/gitlab/gitlab-rails/shared/registry').with(
        owner: 'registry',
        group: 'git',
        mode: '0770'
      )
    end

    it 'creates default user and group' do
      expect(chef_run.node['registry']['username'])
        .to eql('registry')
      expect(chef_run.node['registry']['group'])
        .to eql('registry')

      expect(chef_run).to create_account('Docker registry user and group').with(
        username: 'registry',
        groupname: 'registry',
        uid: nil,
        gid: nil,
        system: true,
        home: '/var/opt/gitlab/registry'
      )
    end

    it 'creates default self signed key-certificate pair' do
      expect(chef_run).to create_file('/var/opt/gitlab/registry/gitlab-registry.crt').with(
        user: 'registry',
        group: 'registry'
      )
      expect(chef_run).to create_file('/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key').with(
        user: 'git',
        group: 'git'
      )

      expect(chef_run).to render_file('/var/opt/gitlab/registry/gitlab-registry.crt')
        .with_content(/-----BEGIN CERTIFICATE-----/)
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key')
        .with_content(/-----BEGIN RSA PRIVATE KEY-----/)
    end

    it 'creates registry config.yml template' do
      expect(chef_run).to create_template('/var/opt/gitlab/registry/config.yml').with(
        owner: 'registry',
        group: nil,
        mode: '0644'
      )
      expect(chef_run).to(
        render_file('/var/opt/gitlab/registry/config.yml').with_content do |content|
          expect(content).to match(/version: 0.1/)
          expect(content).to match(/realm: .*\/jwt\/auth/)
          expect(content).to match(/addr: localhost:5000/)
          expect(content).to match(%r(storage: {"filesystem":{"rootdirectory":"/var/opt/gitlab/gitlab-rails/shared/registry"}))
          expect(content).to match(/health:\s*storagedriver:\s*enabled:\s*true/)
          expect(content).to match(/log:\s*level: info\s*formatter:\s*text/)
          expect(content).to match(/validation:\s*disabled: true$/)
          expect(content).not_to match(/^compatibility:/)
        end
      )
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

    context 'when a log formatter is specified' do
      before { stub_gitlab_rb(registry: { log_formatter: 'json' }) }

      it 'creates the registry config with the specified value' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/log:\s*level: info\s*formatter:\s*json/)
      end
    end

    context 'when schema1 compatibility is enabled' do
      before { stub_gitlab_rb(registry: { compatibility_schema1_enabled: true }) }

      it 'creates registry config with specified value' do
        expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
          .with_content(/compatibility:\s*schema1:\s*enabled:\s*true/)
      end
    end

    it 'creates a default VERSION file' do
      expect(chef_run).to create_file('/var/opt/gitlab/registry/VERSION').with(
        user: nil,
        group: nil
      )
    end

    it 'creates gitlab-rails config with default values' do
      expect(chef_run).to create_templatesymlink('Create a gitlab.yml and create a symlink to Rails root').with_variables(hash_including('registry_api_url' => 'http://localhost:5000'))
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

describe 'registry' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(runit_service)).converge('gitlab::default') }
  let(:default_vars) do
    {
      'SSL_CERT_DIR' => '/opt/gitlab/embedded/ssl/certs/'
    }
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when registry is enabled' do
    before { stub_gitlab_rb(registry_external_url: 'https://registry.example.com') }

    it 'sets default storage options' do
      expect(chef_run.node['registry']['storage']['filesystem'])
        .to eql('rootdirectory' => '/var/opt/gitlab/gitlab-rails/shared/registry')
      expect(chef_run.node['registry']['storage']['cache'])
        .to eql('blobdescriptor' => 'inmemory')
      expect(chef_run.node['registry']['storage']['delete'])
        .to eql('enabled' => true)
    end

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
end
