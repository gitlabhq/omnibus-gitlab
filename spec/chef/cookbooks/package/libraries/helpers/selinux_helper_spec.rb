# frozen_string_literal: true
require 'chef_helper'

RSpec.describe SELinuxHelper do
  let(:chef_run) { converge_config }

  context 'when building SELinux policy command strings' do
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/var/opt/gitlab/.ssh').and_return(true)
      allow(File).to receive(:exist?).with('/var/opt/gitlab/.ssh/authorized_keys').and_return(true)
      allow(File).to receive(:exist?).with('/var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret').and_return(true)
      allow(File).to receive(:exist?).with('/var/opt/gitlab/gitlab-shell/config.yml').and_return(true)
      allow(File).to receive(:exist?).with('/var/opt/gitlab/gitlab-workhorse/sockets').and_return(true)
    end

    def semanage_fcontext(filename)
      "semanage fcontext -a -t gitlab_shell_t '#{filename}'"
    end

    using RSpec::Parameterized::TableSyntax
    where(:dry_run, :restorecon_options) do
      true  | '-v -n'
      false | '-v'
    end

    with_them do
      let(:node) { chef_run.node }
      let(:lines) { SELinuxHelper.commands(node, dry_run: dry_run) }

      it 'adds the correct parameters to restorecon' do
        expect(lines).to include("restorecon -R #{restorecon_options} '/var/opt/gitlab/.ssh'")
        expect(lines).to include("restorecon #{restorecon_options} '/var/opt/gitlab/.ssh/authorized_keys'")
        expect(lines).to include("restorecon #{restorecon_options} '/var/opt/gitlab/gitlab-shell/config.yml'")
        expect(lines).to include("restorecon #{restorecon_options} '/var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret'")
        expect(lines).to include("restorecon #{restorecon_options} '/var/opt/gitlab/gitlab-workhorse/sockets'")
      end

      it 'adds the correct SELinux file contexts' do
        files = %w(/var/opt/gitlab/.ssh(/.*)?
                   /var/opt/gitlab/.ssh/authorized_keys
                   /var/opt/gitlab/gitlab-shell/config.yml
                   /var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret
                   /var/opt/gitlab/gitlab-workhorse/sockets)

        managed_files = files.map { |file| semanage_fcontext(file) }
        expect(lines).to include(*managed_files)
      end
    end

    with_them do
      let(:user_sockets_directory) { '/how/do/you/do' }
      let(:node) { chef_run.node }
      let(:lines) { SELinuxHelper.commands(node, dry_run: dry_run) }

      before do
        allow(Gitlab).to receive(:[]).and_call_original
        stub_gitlab_rb(
          gitlab_workhorse: {
            listen_network: 'unix',
            sockets_directory: user_sockets_directory
          }
        )
        allow(File).to receive(:exist?).with(user_sockets_directory).and_return(true)
      end

      context 'when the user sets a custom workhorse sockets directory' do
        it 'applies the security context to the custom workhorse sockets directory' do
          files = [user_sockets_directory]
          managed_files = files.map { |file| semanage_fcontext(file) }

          expect(lines).to include(*managed_files)
          expect(lines).to include("restorecon #{restorecon_options} '#{user_sockets_directory}'")
        end
      end
    end
  end
end
