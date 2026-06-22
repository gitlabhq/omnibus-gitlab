require 'chef_helper'

RSpec.describe 'oak::enable' do
  let(:base_chef_runner) do
    ChefSpec::SoloRunner.new do |node|
      node.normal['package']['install-dir'] = '/opt/gitlab'
      node.normal['oak']['enable'] = true
      node.normal['oak']['network_address'] = '10.0.0.1'
      node.normal['postgresql']['port'] = 5432
      node.normal['gitlab']['external_url'] = 'http://gitlab.example.com'
    end
  end

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(Gitlab).to receive(:[]).with('node') { chef_runner.node }
  end

  let(:helm_values_path) { '/etc/gitlab/openbao-helm-values.yaml' }

  context 'when the openbao component is enabled' do
    let(:chef_runner) do
      base_chef_runner.tap do |runner|
        node = runner.node
        node.normal['oak']['components']['openbao'] = {
          'enable' => true,
          'external_url' => 'http://openbao.example.com',
          'internal_url' => 'http://10.0.0.5:8200',
          'helm_values_path' => helm_values_path
        }
      end
    end

    let(:chef_run) { chef_runner.converge('gitlab-base::config', 'oak::enable') }

    it 'renders the Helm values file' do
      expect(chef_run).to render_file(helm_values_path)
    end

    it 'sets the PostgreSQL host to the OAK network address' do
      expect(chef_run).to render_file(helm_values_path)
        .with_content(/host: "10\.0\.0\.1"/)
    end

    it 'includes the PostgreSQL port' do
      expect(chef_run).to render_file(helm_values_path)
        .with_content(/port: 5432/)
    end

    it 'enables PostgreSQL HA mode' do
      expect(chef_run).to render_file(helm_values_path)
        .with_content(/haEnabled: true/)
    end

    it 'sets the default database name and username' do
      expect(chef_run).to render_file(helm_values_path)
        .with_content(/database: "openbao"/)
      expect(chef_run).to render_file(helm_values_path)
        .with_content(/username: "openbao"/)
    end

    it 'references the default password secret' do
      expect(chef_run).to render_file(helm_values_path)
        .with_content(/secret: openbao-db-password/)
    end

    it 'sets oidcDiscoveryUrl and boundIssuer to the GitLab external URL' do
      expect(chef_run).to render_file(helm_values_path)
        .with_content(/oidcDiscoveryUrl: "http:\/\/gitlab\.example\.com"/)
      expect(chef_run).to render_file(helm_values_path)
        .with_content(/boundIssuer: "http:\/\/gitlab\.example\.com"/)
    end

    it 'sets boundAudiences to the OpenBao external URL' do
      expect(chef_run).to render_file(helm_values_path)
        .with_content(/boundAudiences:.*openbao\.example\.com/)
    end
  end

  context 'when the openbao component is disabled' do
    let(:chef_runner) do
      base_chef_runner.tap do |runner|
        node = runner.node
        node.normal['oak']['components']['openbao'] = {
          'enable' => false,
          'external_url' => 'http://openbao.example.com',
          'internal_url' => 'http://10.0.0.5:8200',
          'helm_values_path' => helm_values_path
        }
      end
    end

    let(:chef_run) { chef_runner.converge('gitlab-base::config', 'oak::enable') }

    it 'deletes the Helm values file' do
      expect(chef_run).to delete_template(helm_values_path)
    end
  end

  context 'when a component has no helm_values_path' do
    let(:chef_runner) do
      base_chef_runner.tap do |runner|
        node = runner.node
        node.normal['oak']['components']['future-component'] = {
          'enable' => true,
          'internal_url' => 'http://10.0.0.9:9000'
        }
      end
    end

    let(:chef_run) { chef_runner.converge('gitlab-base::config', 'oak::enable') }

    it 'does not raise an error' do
      expect { chef_run }.not_to raise_error
    end
  end
end

RSpec.describe 'oak::disable' do
  let(:chef_runner) do
    ChefSpec::SoloRunner.new do |node|
      node.normal['package']['install-dir'] = '/opt/gitlab'
      node.normal['oak']['enable'] = false
      node.normal['oak']['components']['openbao'] = {
        'enable' => true,
        'internal_url' => 'http://10.0.0.5:8200',
        'helm_values_path' => '/etc/gitlab/openbao-helm-values.yaml'
      }
    end
  end

  let(:chef_run) { chef_runner.converge('gitlab-base::config', 'oak::disable') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    allow(Gitlab).to receive(:[]).with('node') { chef_runner.node }
  end

  it 'deletes the Helm values file even when the component is marked enabled' do
    expect(chef_run).to delete_file('/etc/gitlab/openbao-helm-values.yaml')
  end
end
