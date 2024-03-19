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
    end

    let(:bash_block) { chef_run.bash('Set proper security context on ssh files for selinux') }

    it 'should run the semanage bash command' do
      expect(templatesymlink).to notify('bash[Set proper security context on ssh files for selinux]').delayed
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
