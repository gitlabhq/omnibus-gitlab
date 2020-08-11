require 'chef_helper'

RSpec.describe 'gitlab::gitlab-selinux' do
  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink storage_directory)).converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original
  end

  context 'when NOT running on selinux' do
    before { stub_command('id -Z').and_return(false) }

    it 'should not run the semanage bash command' do
      expect(chef_run).not_to run_bash('Set proper security context on ssh files for selinux')
    end
  end

  context 'when running on selinux' do
    before do
      stub_command('id -Z').and_return('')
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/var/opt/gitlab/.ssh').and_return(true)
      allow(File).to receive(:exist?).with('/var/opt/gitlab/.ssh/authorized_keys').and_return(true)
      allow(File).to receive(:exist?).with('/var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret').and_return(true)
      allow(File).to receive(:exist?).with('/var/opt/gitlab/gitlab-shell/config.yml').and_return(true)
    end

    let(:bash_block) { chef_run.bash('Set proper security context on ssh files for selinux') }

    def semanage_fcontext(filename)
      "semanage fcontext -a -t ssh_home_t '#{filename}'"
    end

    it 'should run the semanage bash command' do
      expect(chef_run).to run_bash('Set proper security context on ssh files for selinux')
    end

    it 'sets the security context of gitlab-shell files' do
      lines = bash_block.code.split("\n")
      files = %w(/var/opt/gitlab/.ssh(/.*)?
                 /var/opt/gitlab/.ssh/authorized_keys
                 /var/opt/gitlab/gitlab-shell/config.yml
                 /var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret)
      managed_files = files.map { |file| semanage_fcontext(file) }

      expect(lines).to include(*managed_files)
      expect(lines).to include("restorecon -R -v '/var/opt/gitlab/.ssh'")
      expect(lines).to include("restorecon -v '/var/opt/gitlab/.ssh/authorized_keys'")
      expect(lines).to include("restorecon -v '/var/opt/gitlab/gitlab-shell/config.yml'")
      expect(lines).to include("restorecon -v '/var/opt/gitlab/gitlab-rails/etc/gitlab_shell_secret'")
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
