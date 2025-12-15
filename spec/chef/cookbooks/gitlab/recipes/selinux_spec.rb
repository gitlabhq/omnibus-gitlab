require 'chef_helper'

RSpec.describe 'gitlab::gitlab-selinux' do
  before do
    allow(Gitlab).to receive(:[]).and_call_original
    stub_default_should_notify?(true)
  end

  context 'when NOT running on selinux' do
    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink storage_directory)).converge('gitlab::default') }
    let(:templatesymlink) { chef_run.templatesymlink('Create a config.yml and create a symlink to Rails root') }

    before do
      allow_any_instance_of(ShellOutHelper).to receive(:success?).with('id -Z').and_return(false)
    end

    it 'should not run the semanage bash command' do
      expect(templatesymlink).to_not notify('bash[Set proper security context on ssh files for selinux]').delayed
    end
  end

  context 'when running on selinux' do
    let(:chef_run) { ChefSpec::SoloRunner.new(step_into: %w(templatesymlink storage_directory)).converge('gitlab::default') }
    let(:templatesymlink) { chef_run.templatesymlink('Create a config.yml and create a symlink to Rails root') }

    before do
      allow(SELinuxDistroHelper).to receive(:selinux_supported?).and_return(true)
      allow_any_instance_of(ShellOutHelper).to receive(:success?).with('id -Z').and_return(true)
      allow(SELinuxHelper).to receive(:context_set?).and_return(false)
    end

    context 'when using unified policy' do
      before do
        allow(SELinuxHelper).to receive(:use_unified_policy?).and_return(true)
      end

      it 'sets retries to 3 for semodule commands', type: :chef do
        expect(chef_run.execute("semodule -i /opt/gitlab/embedded/selinux/gitlab.pp")).to have_attributes(retries: 3, retry_delay: 5)
        expect(chef_run.execute("semodule -r gitlab-7.2.0-ssh-keygen")).to have_attributes(retries: 3, retry_delay: 5)
        expect(chef_run.execute("semodule -r gitlab-10.5.0-ssh-authorized-keys")).to have_attributes(retries: 3, retry_delay: 5)
        expect(chef_run.execute("semodule -r gitlab-13.5.0-gitlab-shell")).to have_attributes(retries: 3, retry_delay: 5)
      end
    end

    context 'when not using unified policy' do
      before do
        allow(SELinuxHelper).to receive(:use_unified_policy?).and_return(false)
      end

      it 'sets retries to 3 for semodule commands', type: :chef do
        expect(chef_run.execute("semodule -r gitlab")).to have_attributes(retries: 3, retry_delay: 5)
        expect(chef_run.execute("semodule -i /opt/gitlab/embedded/selinux/gitlab-7.2.0-ssh-keygen.pp")).to have_attributes(retries: 3, retry_delay: 5)
        expect(chef_run.execute("semodule -i /opt/gitlab/embedded/selinux/gitlab-10.5.0-ssh-authorized-keys.pp")).to have_attributes(retries: 3, retry_delay: 5)
        expect(chef_run.execute("semodule -i /opt/gitlab/embedded/selinux/gitlab-13.5.0-gitlab-shell.pp")).to have_attributes(retries: 3, retry_delay: 5)
      end
    end

    it 'should run the semanage bash command' do
      expect(templatesymlink).to notify('bash[Set proper security context on ssh files for selinux]').delayed
    end

    it 'should notify selinux context setup at the end of the run' do
      expect(chef_run).to run_ruby_block('Check SELinux setup')
      expect(chef_run.ruby_block('Check SELinux setup')).to notify('bash[Set proper security context on ssh files for selinux]').delayed
    end

    context 'when context is already set' do
      before do
        allow(SELinuxHelper).to receive(:context_set?).and_return(true)
      end

      it 'should not run the semanage bash command' do
        expect(chef_run).not_to run_bash('Set proper security context on ssh files for selinux')
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
