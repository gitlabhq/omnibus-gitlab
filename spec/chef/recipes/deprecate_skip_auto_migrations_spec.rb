require 'chef_helper'

describe 'gitlab::deprecate-skip-auto-migrations' do
  let(:chef_run) { ChefSpec::SoloRunner.converge('gitlab::default') }

  before do
    allow(Gitlab).to receive(:[]).and_call_original

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/etc/gitlab/skip-auto-migrations').and_return(true)
  end

  context 'when there is the old file' do
    it 'creates new flag' do
      expect(chef_run).to create_file('/etc/gitlab/skip-auto-reconfigure')
    end

    it 'notifies the user' do
      expect(chef_run).to run_ruby_block('skip-auto-migrations deprecation')
    end
  end

  context 'no file' do
    before do
      allow(File).to receive(:exist?).with('/etc/gitlab/skip-auto-migrations').and_return(false)
    end

    it 'does not create new flag' do
      expect(chef_run).not_to create_file('/etc/gitlab/skip-auto-reconfigure')
    end

    it 'does not notify the user' do
      expect(chef_run).not_to run_ruby_block('skip-auto-migrations deprecation')
    end
  end
end
