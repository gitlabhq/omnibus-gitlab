require 'chef_helper'

describe 'registry recipe' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when registry is enabled' do
    before { stub_gitlab_rb(registry_external_url: 'https://registry.example.com') }

    it 'creates default set of directories' do
      expect(chef_run.node['gitlab']['registry']['dir'])
        .to eql('/var/opt/gitlab/registry')
      expect(chef_run.node['gitlab']['registry']['log_directory'])
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
        mode: '0750'
      )
    end

    it 'creates default user and group' do
      expect(chef_run.node['gitlab']['registry']['username'])
        .to eql('registry')
      expect(chef_run.node['gitlab']['registry']['group'])
        .to eql('registry')

      expect(chef_run).to create_group('registry').with(
        gid: nil,
        system: true
      )

      expect(chef_run).to create_user('registry').with(
        uid: nil,
        gid: 'registry',
        home: '/var/opt/gitlab/registry',
        system: true
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
      expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
        .with_content(/version: 0.1/)
      expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
        .with_content(/realm: \/jwt\/auth/)
      expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
        .with_content(/addr: localhost:5000/)
      expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
        .with_content(%r(storage: {"filesystem":{"rootdirectory":"/var/opt/gitlab/gitlab-rails/shared/registry"}))
    end

    it 'creates a default VERSION file' do
      expect(chef_run).to create_file('/var/opt/gitlab/registry/VERSION').with(
        user: nil,
        group: nil
      )
    end

    it 'creates gitlab-rails config with default values' do
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/gitlab.yml')
        .with_content(/api_url: http:\/\/localhost:5000/)
    end
  end

  context 'when registry port is specified' do
    before { stub_gitlab_rb(registry_external_url: 'https://registry.example.com', registry: { registry_http_addr: 'localhost:5001' }) }
    it 'creates registry and rails configs with specified value' do
      expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
        .with_content(/addr: localhost:5001/)
      expect(chef_run).to render_file('/var/opt/gitlab/gitlab-rails/etc/gitlab.yml')
        .with_content(/api_url: http:\/\/localhost:5001/)
    end
  end

  context 'when a debug addr is specified' do
    before { stub_gitlab_rb(registry_external_url: 'https://registry.example.com', registry: { debug_addr: 'localhost:5005' }) }

    it 'creates the registry config with the specified debug value' do
      expect(chef_run).to render_file('/var/opt/gitlab/registry/config.yml')
        .with_content(/debug:\n\s*addr: localhost:5005/)
    end
  end
end

describe 'registry' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when registry is enabled' do
    before { stub_gitlab_rb(registry_external_url: 'https://registry.example.com') }

    it 'sets default storage options' do
      expect(chef_run.node['gitlab']['registry']['storage']['filesystem'])
        .to eql('rootdirectory' => '/var/opt/gitlab/gitlab-rails/shared/registry')
      expect(chef_run.node['gitlab']['registry']['storage']['cache'])
        .to eql('blobdescriptor'=>'inmemory')
      expect(chef_run.node['gitlab']['registry']['storage']['delete'])
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
        expect(chef_run.node['gitlab']['registry']['storage'])
          .to include(s3: { accesskey: 'awsaccesskey', secretkey: 'awssecretkey', bucketname: 'bucketname' })
        expect(chef_run.node['gitlab']['registry']['storage'])
          .not_to include('rootdirectory' => '/var/opt/gitlab/gitlab-rails/shared/registry')
      end

      it 'uses the default cache and delete settings if not overridden' do
        expect(chef_run.node['gitlab']['registry']['storage']['cache'])
          .to eql('blobdescriptor'=>'inmemory')
        expect(chef_run.node['gitlab']['registry']['storage']['delete'])
          .to eql('enabled' => true)
      end

      it 'allows the cache and delete settings to be overridden' do
        stub_gitlab_rb(registry: { storage: {cache: 'somewhere-else', delete: { enabled: false } } })
        expect(chef_run.node['gitlab']['registry']['storage']['cache'])
          .to eql('somewhere-else')
        expect(chef_run.node['gitlab']['registry']['storage']['delete'])
          .to eql('enabled' => false)
      end
    end

    context 'when storage_delete_enabled is false' do
      before { stub_gitlab_rb(registry: { storage_delete_enabled: false }) }

      it 'sets the delete enabled field on the storage object' do
        expect(chef_run.node['gitlab']['registry']['storage']['delete'])
          .to eql('enabled' => false)
      end
    end
  end
end
