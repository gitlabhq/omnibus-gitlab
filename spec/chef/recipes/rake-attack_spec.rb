require 'chef_helper'

describe 'rake-attack' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when rack_attack_protected_paths is set' do
    it 'adds leading slashes' do
      stub_gitlab_rb(gitlab_rails: { rack_attack_protected_paths: ['admin/', 'users/password'] })
      expect(chef_run.node['gitlab']['gitlab-rails']['rack_attack_protected_paths'])
        .to eql(['/admin/', '/users/password'])
    end

    it 'does not add additional slashes' do
      stub_gitlab_rb(gitlab_rails: { rack_attack_protected_paths: ['/admin/', '/users/password'] })
      expect(chef_run.node['gitlab']['gitlab-rails']['rack_attack_protected_paths'])
        .to eql(['/admin/', '/users/password'])
    end

    it 'can contain variables in path' do
      stub_gitlab_rb(gitlab_rails: { rack_attack_protected_paths: ['/api/#{API::API.version}/session', "/api/#\{API::API.version\}/session.json"] })
      expect(chef_run.node['gitlab']['gitlab-rails']['rack_attack_protected_paths'])
        .to eql(['/api/#{API::API.version}/session', '/api/#{API::API.version}/session.json'])
    end

    it 'creates rack_attack config file with user defined list' do
      rack_attack_config = '/var/opt/gitlab/gitlab-rails/etc/rack_attack.rb'
      stub_gitlab_rb(gitlab_rails: { rack_attack_protected_paths: ['/admin/', '/users/password'] })

      expect(chef_run).to create_template(rack_attack_config)

      expect(chef_run).to render_file(rack_attack_config)
        .with_content(/#\{Rails.application.config.relative_url_root\}\/admin\//)
      expect(chef_run).to render_file(rack_attack_config)
        .with_content(/#\{Rails.application.config.relative_url_root\}\/users\/password/)
    end

  end

  context 'when rack_attack_protected_paths and relative_url_root are set' do
    it 'adds paths without relative_url' do
      stub_gitlab_rb(gitlab_rails: { rack_attack_protected_paths: ['/profile/keys', '/profile/users/password'] },
                     external_url: 'https://example.com/profile' # crazy idea for relative url
                    )
      expect(chef_run.node['gitlab']['gitlab-rails']['rack_attack_protected_paths'])
        .to eql(['/profile/keys', '/profile/users/password', '/keys', '/users/password'])
    end

    it 'does not add additional paths' do
      stub_gitlab_rb(gitlab_rails: { rack_attack_protected_paths: ['/admin/', '/users/password'] },
                     external_url: 'https://example.com/gitlab'
                    )
      expect(chef_run.node['gitlab']['gitlab-rails']['rack_attack_protected_paths'])
        .to eql(['/admin/', '/users/password'])
    end

    it 'adds paths without relative_url for multi-level relative_url' do
      stub_gitlab_rb(gitlab_rails: { rack_attack_protected_paths: ['/hosting/admin/', '/hosting/gitlab/admin/'] },
                     external_url: 'https://example.com/hosting/gitlab'
                    )
      expect(chef_run.node['gitlab']['gitlab-rails']['rack_attack_protected_paths'])
        .to eql(['/hosting/admin/', '/hosting/gitlab/admin/', '/admin/'])
    end


  end

  context 'when rack_attack_protected_paths is not set' do
    default_protected_paths = ['/users/password',
                               '/users/sign_in',
                               '/api/#{API::API.version}/session.json',
                               '/api/#{API::API.version}/session',
                               '/users',
                               '/users/confirmation',
                               '/unsubscribes/',
                               '/import/github/personal_access_token'
                              ]
    it 'uses default list' do
      stub_gitlab_rb(gitlab_rails: { rack_attack_protected_paths: nil })
      expect(chef_run.node['gitlab']['gitlab-rails']['rack_attack_protected_paths'])
        .to eql(default_protected_paths)
    end

    it 'creates rack_attack config file with default list' do
      stub_gitlab_rb(gitlab_rails: { rack_attack_protected_paths: nil })
      rack_attack_config = '/var/opt/gitlab/gitlab-rails/etc/rack_attack.rb'
      expect(chef_run).to create_template(rack_attack_config)
      default_protected_paths.each do |path|
        expect(chef_run).to render_file(rack_attack_config)
          .with_content(/#\{Rails.application.config.relative_url_root\}#{path}/)

      end

    end
  end



end
