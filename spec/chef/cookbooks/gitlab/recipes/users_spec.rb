require 'chef_helper'

RSpec.describe 'gitlab::users' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'with default attributes' do
    it 'creates gitlab user' do
      account_params = {
        username: 'git',
        groupname: 'git',
        home: '/var/opt/gitlab',
        shell: '/bin/sh'
      }

      expect(chef_run).to create_directory('/var/opt/gitlab')
      expect(chef_run).to create_account('GitLab user and group').with(account_params)
    end

    it 'creates .bundle directory' do
      directory_params = {
        owner: 'git',
        group: 'git'
      }

      expect(chef_run).to create_directory('/var/opt/gitlab/.bundle').with(directory_params)
    end
  end

  context 'user gitconfig' do
    let(:gitconfig_header) do
      <<-EOF
# This file is managed by gitlab-ctl. Manual changes will be
# erased! To change the contents below, edit /etc/gitlab/gitlab.rb
# and run `sudo gitlab-ctl reconfigure`.
      EOF
    end

    shared_examples 'a rendered .gitconfig' do
      it 'creates the template' do
        template_params = {
          owner: 'git',
          group: 'git',
          mode: '0644',
          variables: {
            user_options: {
              "gid" => nil,
              "git_user_email" => "gitlab@fauxhai.local",
              "git_user_name" => "GitLab",
              "group" => "git",
              "home" => "/var/opt/gitlab",
              "shell" => "/bin/sh",
              "uid" => nil,
              "username" => "git"
            },
            system_core_options: expected_options,
          }
        }

        expect(chef_run).to create_template('/var/opt/gitlab/.gitconfig').with(template_params)
      end

      it 'renders the gitconfig' do
        expect(chef_run).to render_file('/var/opt/gitlab/.gitconfig').with_content { |content|
          expect(content).to match(expected_content)
        }
      end
    end

    context 'with default attributes' do
      let(:expected_options) { [] }
      let(:expected_content) do
        # rubocop:disable Layout/TrailingWhitespace
        <<-EOF
#{gitconfig_header}
[user]
        name = GitLab
        email = gitlab@fauxhai.local
[core]
        autocrlf = input
        
[gc]
        auto = 0
        EOF
        # rubocop:enable Layout/TrailingWhitespace
      end

      it_behaves_like 'a rendered .gitconfig'
    end

    context 'with non-core gitconfig' do
      let(:expected_options) { [] }
      let(:expected_content) do
        # rubocop:disable Layout/TrailingWhitespace
        <<-EOF
#{gitconfig_header}
[user]
        name = GitLab
        email = gitlab@fauxhai.local
[core]
        autocrlf = input
        
[gc]
        auto = 0
        EOF
        # rubocop:enable Layout/TrailingWhitespace
      end

      before do
        stub_gitlab_rb(
          omnibus_gitconfig: {
            system: {
              pack: ["threads=1"],
            }
          }
        )
      end

      it_behaves_like 'a rendered .gitconfig'
    end

    context 'with core gitconfig' do
      let(:expected_options) do
        [
          'example = value'
        ]
      end

      let(:expected_content) do
        <<-EOF
#{gitconfig_header}
[user]
        name = GitLab
        email = gitlab@fauxhai.local
[core]
        autocrlf = input
        example = value
[gc]
        auto = 0
        EOF
      end

      before do
        stub_gitlab_rb(
          omnibus_gitconfig: {
            system: {
              core: ["example = value"],
            }
          }
        )
      end

      it_behaves_like 'a rendered .gitconfig'
    end
  end
end
