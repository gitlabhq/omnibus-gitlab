require 'chef_helper'

describe 'rake-attack' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before { allow(Gitlab).to receive(:[]).and_call_original }

  context 'when rack_attack_paths_to_be_protected is set' do
    it 'adds leading slashes' do
      stub_gitlab_rb(gitlab_rails: { rack_attack_paths_to_be_protected: ['admin/', 'users/password'] })
      expect(chef_run.node['gitlab']['gitlab-rails']['rack_attack_paths_to_be_protected'])
        .to eql(['/admin/', '/users/password'])
    end

    it 'does not add additional slashes' do
      stub_gitlab_rb(gitlab_rails: { rack_attack_paths_to_be_protected: ['/admin/', '/users/password'] })
      expect(chef_run.node['gitlab']['gitlab-rails']['rack_attack_paths_to_be_protected'])
        .to eql(['/admin/', '/users/password'])
    end

    it 'creates rack_attack config file with user defined list' do
      rack_attack_config = '/var/opt/gitlab/gitlab-rails/etc/rack_attack.rb'
      stub_gitlab_rb(gitlab_rails: { rack_attack_paths_to_be_protected: ['/admin/', '/users/password'] })

      expect(chef_run).to create_template(rack_attack_config)

      expect(chef_run).to render_file(rack_attack_config)
        .with_content(/#\{Rails.application.config.relative_url_root\}\/admin\//)
      expect(chef_run).to render_file(rack_attack_config)
        .with_content(/#\{Rails.application.config.relative_url_root\}\/users\/password/)
    end

  end

  context 'when rack_attack_paths_to_be_protected is not set' do
    default_paths_to_be_protected = ['/users/password',
                                     '/users/sign_in',
                                     '/api/#{API::API.version}/session.json',
                                     '/api/#{API::API.version}/session',
                                     '/users',
                                     '/users/confirmation',
                                     '/unsubscribes/',
                                     '/import/github/personal_access_token'
                                    ]
    it 'uses default list' do
      expect(chef_run.node['gitlab']['gitlab-rails']['rack_attack_paths_to_be_protected'])
        .to eql(default_paths_to_be_protected)
    end

    it 'creates rack_attack config file with default list' do
      rack_attack_config = '/var/opt/gitlab/gitlab-rails/etc/rack_attack.rb'
      expect(chef_run).to create_template(rack_attack_config)
      default_paths_to_be_protected.each do |path|
        expect(chef_run).to render_file(rack_attack_config)
          .with_content(/#\{Rails.application.config.relative_url_root\}#{path}/)

      end

    end
  end

end
