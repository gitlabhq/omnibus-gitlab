require 'chef_helper'

RSpec.describe 'gitlab::gitlab-selinux' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink storage_directory)).converge('gitlab::default') }
  let(:templatesymlink) { chef_run.templatesymlink('Create a config.yml and create a symlink to Rails root') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_default_should_notify?(true)
  end

  context 'when NOT running on selinux' do
    before do
      allow_any_instance_of(ShellOutHelper).to receive(:success?).with('id -Z').and_return(false)
    end

    it 'should not run the semanage bash command' do
      expect(templatesymlink).to_not notify('bash[Set proper security context on ssh files for selinux]').delayed
    end
  end

  context 'when running on selinux' do
    before do
      allow_any_instance_of(ShellOutHelper).to receive(:success?).with('id -Z').and_return(true)
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/var/opt/gitlab/.ssh').and_return(true)
      allow(File).to receive(:exist?).with('/var/opt/gitlab/.ssh/authorized_keys').and_return(true)
      allow(File).to receive(:exist?).with('/var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret').and_return(true)
      allow(File).to receive(:exist?).with('/var/opt/gitlab/gitlab-shell/config.yml').and_return(true)
      allow(File).to receive(:exist?).with('/var/opt/gitlab/gitlab-workhorse/sockets').and_return(true)
    end

    let(:bash_block) { chef_run.bash('Set proper security context on ssh files for selinux') }

    def semanage_fcontext(filename)
      "semanage fcontext -a -t gitlab_shell_t '#{filename}'"
    end

    it 'should run the semanage bash command' do
      expect(templatesymlink).to notify('bash[Set proper security context on ssh files for selinux]').delayed
    end

    it 'sets the security context of gitlab-shell files' do
      lines = bash_block.code.split("\n")
      files = %w(/var/opt/gitlab/.ssh(/.*)?
                 /var/opt/gitlab/.ssh/authorized_keys
                 /var/opt/gitlab/gitlab-shell/config.yml
                 /var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret
                 /var/opt/gitlab/gitlab-workhorse/sockets)
      managed_files = files.map { |file| semanage_fcontext(file) }

      expect(lines).to include(*managed_files)
      expect(lines).to include("restorecon -R -v '/var/opt/gitlab/.ssh'")
      expect(lines).to include("restorecon -v '/var/opt/gitlab/.ssh/authorized_keys'")
      expect(lines).to include("restorecon -v '/var/opt/gitlab/gitlab-shell/config.yml'")
      expect(lines).to include("restorecon -v '/var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret'")
      expect(lines).to include("restorecon -v '/var/opt/gitlab/gitlab-workhorse/sockets'")
    end

    context 'and the user configured a custom workhorse sockets directory' do
      let(:user_sockets_directory) { '/how/do/you/do' }
      before do
        stub_gitlab_rb(
          gitlab_workhorse: {
            listen_network: 'unix',
            sockets_directory: user_sockets_directory
          }
        )
      end

      it 'sets the security context of a custom workhorse sockets directory' do
        allow(File).to receive(:exist?).with(user_sockets_directory).and_return(true)
        lines = bash_block.code.split("\n")
        files = [user_sockets_directory]
        managed_files = files.map { |file| semanage_fcontext(file) }

        expect(lines).to include(*managed_files)
        expect(lines).to include("restorecon -v '#{user_sockets_directory}'")
      end
    end

    context 'when gitlab-rails is disabled' do
      before do
        stub_gitlab_rb(
          gitlab_rails: {
            enable: false
          }
        )
      end

      it 'should not attempt to set security context' do
        expect(chef_run).not_to run_bash('Set proper security context on ssh files for selinux')
      end
    end
  end
end
