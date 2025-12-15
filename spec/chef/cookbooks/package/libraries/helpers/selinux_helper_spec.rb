# frozen_string_literal: true
require 'chef_helper'

RSpec.describe SELinuxHelper do
  let(:chef_run) { converge_config }
  let(:node) { chef_run.node }

  context 'when getting GitLab shell file paths' do
    it 'returns a hash with all required file paths' do
      files = SELinuxHelper.gitlab_shell_files(node)

      expect(files).to be_a(Hash)
      expect(files).to include(:ssh_dir, :authorized_keys, :gitlab_shell_config_file, :gitlab_shell_secret_file, :gitlab_workhorse_sockets_directory)
      expect(files[:ssh_dir]).to eq('/var/opt/gitlab/.ssh')
      expect(files[:authorized_keys]).to eq('/var/opt/gitlab/.ssh/authorized_keys')
      expect(files[:gitlab_shell_config_file]).to eq('/var/opt/gitlab/gitlab-shell/config.yml')
      expect(files[:gitlab_shell_secret_file]).to eq('/var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret')
      expect(files[:gitlab_workhorse_sockets_directory]).to eq('/var/opt/gitlab/gitlab-workhorse/sockets')
    end

    context 'when custom paths are configured' do
      it 'returns the custom file paths' do
        # Mock the node attributes directly without triggering full convergence
        allow(node['gitlab']['user']).to receive(:[]).with('home').and_return('/custom/home')
        allow(node['gitlab']['gitlab_shell']).to receive(:[]).with('auth_file').and_return('/custom/authorized_keys')
        allow(node['gitlab']['gitlab_shell']).to receive(:[]).with('dir').and_return('/custom/gitlab-shell')
        allow(node['gitlab']['gitlab_rails']).to receive(:[]).with('dir').and_return('/custom/gitlab-rails')
        allow(node['gitlab']['gitlab_workhorse']).to receive(:[]).with('sockets_directory').and_return('/custom/sockets')

        files = SELinuxHelper.gitlab_shell_files(node)

        expect(files[:ssh_dir]).to eq('/custom/home/.ssh')
        expect(files[:authorized_keys]).to eq('/custom/authorized_keys')
        expect(files[:gitlab_shell_config_file]).to eq('/custom/gitlab-shell/config.yml')
        expect(files[:gitlab_shell_secret_file]).to eq('/custom/gitlab-rails/etc/gitlab_shell_secret')
        expect(files[:gitlab_workhorse_sockets_directory]).to eq('/custom/sockets')
      end
    end
  end

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
        expect(lines).to include("set -e")

        if dry_run
          expect(lines).not_to include("semanage fcontext")
        else
          expect(lines).to include("semanage fcontext")
        end

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

        managed_files = dry_run ? [] : files.map { |file| semanage_fcontext(file) }
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
          managed_files = dry_run ? [] : files.map { |file| semanage_fcontext(file) }

          expect(lines).to include("set -e")
          expect(lines).to include(*managed_files)
          expect(lines).to include("restorecon #{restorecon_options} '#{user_sockets_directory}'")
        end
      end
    end
  end

  context 'when checking if SELinux context is set' do
    context 'when semanage fcontext -l succeeds with all contexts set' do
      let(:semanage_output) do
        <<~OUTPUT
          /var/opt/gitlab/.ssh(/.*)?                         all files          system_u:object_r:gitlab_shell_t:s0
          /var/opt/gitlab/.ssh/authorized_keys               all files          system_u:object_r:gitlab_shell_t:s0
          /var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret all files          system_u:object_r:gitlab_shell_t:s0
          /var/opt/gitlab/gitlab-shell/config.yml            all files          system_u:object_r:gitlab_shell_t:s0
          /var/opt/gitlab/gitlab-workhorse/sockets           all files          system_u:object_r:gitlab_shell_t:s0
        OUTPUT
      end

      before do
        allow(Mixlib::ShellOut).to receive(:new).with('semanage fcontext -l').and_return(
          double(run_command: double(exitstatus: 0, stdout: semanage_output, stderr: ''))
        )
      end

      it 'returns true when all required contexts are set' do
        expect(SELinuxHelper.context_set?(node)).to be true
      end
    end

    context 'when semanage fcontext -l succeeds but some contexts are missing' do
      let(:semanage_output) do
        <<~OUTPUT
          /var/opt/gitlab/.ssh(/.*)?                         all files          system_u:object_r:gitlab_shell_t:s0
          /var/opt/gitlab/.ssh/authorized_keys               all files          system_u:object_r:gitlab_shell_t:s0
        OUTPUT
      end

      before do
        allow(Mixlib::ShellOut).to receive(:new).with('semanage fcontext -l').and_return(
          double(run_command: double(exitstatus: 0, stdout: semanage_output, stderr: ''))
        )
      end

      it 'returns false when not all required contexts are set' do
        expect(SELinuxHelper.context_set?(node)).to be false
      end
    end

    context 'when semanage fcontext -l succeeds but no gitlab_shell_t contexts exist' do
      let(:semanage_output) do
        <<~OUTPUT
          /other/path(/.*)?                                  all files          system_u:object_r:other_t:s0
        OUTPUT
      end

      before do
        allow(Mixlib::ShellOut).to receive(:new).with('semanage fcontext -l').and_return(
          double(run_command: double(exitstatus: 0, stdout: semanage_output, stderr: ''))
        )
      end

      it 'returns false when no gitlab_shell_t contexts are set' do
        expect(SELinuxHelper.context_set?(node)).to be false
      end
    end

    context 'when semanage fcontext -l fails' do
      before do
        allow(Mixlib::ShellOut).to receive(:new).with('semanage fcontext -l').and_return(
          double(run_command: double(exitstatus: 1, stdout: '', stderr: 'error message'))
        )
      end

      it 'raises an error' do
        expect { SELinuxHelper.context_set?(node) }.to raise_error(/error running semanage/)
      end
    end

    context 'when custom paths are configured' do
      let(:semanage_output) do
        <<~OUTPUT
          /custom/home/.ssh(/.*)?                            all files          system_u:object_r:gitlab_shell_t:s0
          /custom/authorized_keys                            all files          system_u:object_r:gitlab_shell_t:s0
          /custom/gitlab-rails/etc/gitlab_shell_secret       all files          system_u:object_r:gitlab_shell_t:s0
          /custom/gitlab-shell/config.yml                    all files          system_u:object_r:gitlab_shell_t:s0
          /custom/sockets                                    all files          system_u:object_r:gitlab_shell_t:s0
        OUTPUT
      end

      before do
        # Mock the node attributes directly without triggering full convergence
        allow(node['gitlab']['user']).to receive(:[]).with('home').and_return('/custom/home')
        allow(node['gitlab']['gitlab_shell']).to receive(:[]).with('auth_file').and_return('/custom/authorized_keys')
        allow(node['gitlab']['gitlab_shell']).to receive(:[]).with('dir').and_return('/custom/gitlab-shell')
        allow(node['gitlab']['gitlab_rails']).to receive(:[]).with('dir').and_return('/custom/gitlab-rails')
        allow(node['gitlab']['gitlab_workhorse']).to receive(:[]).with('sockets_directory').and_return('/custom/sockets')
        allow(Mixlib::ShellOut).to receive(:new).with('semanage fcontext -l').and_return(
          double(run_command: double(exitstatus: 0, stdout: semanage_output, stderr: ''))
        )
      end

      it 'returns true when all custom paths have contexts set' do
        expect(SELinuxHelper.context_set?(node)).to be true
      end
    end
  end
end
