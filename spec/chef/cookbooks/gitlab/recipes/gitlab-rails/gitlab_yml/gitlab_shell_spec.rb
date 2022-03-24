require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'GitLab Shell settings' do
    context 'with default values' do
      it 'renders gitlab.yml with default values' do
        expect(gitlab_yml[:production][:gitlab_shell]).to eq(
          authorized_keys_file: '/var/opt/gitlab/.ssh/authorized_keys',
          git_timeout: 10800,
          hooks_path: '/opt/gitlab/embedded/service/gitlab-shell/hooks/',
          path: '/opt/gitlab/embedded/service/gitlab-shell/',
          receive_pack: nil,
          ssh_port: nil,
          upload_pack: nil
        )
      end
    end

    context 'with user specified values' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            gitlab_shell_git_timeout: 99999,
            gitlab_shell_hooks_path: '/tmp/hooks',
            gitlab_shell_path: '/tmp/shell',
            gitlab_shell_upload_pack: true,
            gitlab_shell_receive_pack: true,
            gitlab_shell_ssh_port: 123,
          }
        )
      end

      it 'renders gitlab.yml with user specified values' do
        expect(gitlab_yml[:production][:gitlab_shell]).to eq(
          authorized_keys_file: '/var/opt/gitlab/.ssh/authorized_keys',
          git_timeout: 99999,
          hooks_path: '/tmp/hooks',
          path: '/tmp/shell',
          receive_pack: true,
          ssh_port: 123,
          upload_pack: true
        )
      end

      describe 'authorized_keys_file' do
        context 'when explicitly configured' do
          before do
            stub_gitlab_rb(
              gitlab_shell: {
                auth_file: '/tmp/authorized_keys'
              }
            )
          end

          it 'renders gitlab.yml with user specified path' do
            expect(gitlab_yml[:production][:gitlab_shell][:authorized_keys_file]).to eq('/tmp/authorized_keys')
          end
        end

        context 'when the user home directory is specified' do
          before do
            stub_gitlab_rb(
              user: {
                home: '/tmp/user'
              }
            )
          end

          it 'defaults to auth file within specified home directory' do
            expect(gitlab_yml[:production][:gitlab_shell][:authorized_keys_file]).to eq('/tmp/user/.ssh/authorized_keys')
          end
        end
      end
    end
  end
end
