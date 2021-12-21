# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ShellOutHelper do
  let(:dummy_class) { Class.new { extend ShellOutHelper } }

  before do
    allow(Mixlib::ShellOut).to receive(:new).and_call_original
  end

  describe '.do_shell_out' do
    context 'without optional arguments' do
      it 'creates Mixlib::ShellOut object without optional arguments' do
        expect(Mixlib::ShellOut).to receive(:new).with('ls', { user: nil, cwd: nil, environment: {} })

        dummy_class.do_shell_out('ls')
      end
    end

    context 'with optional arguments specified' do
      it 'creates Mixlib::ShellOut object with specified optional arguments' do
        expect(Mixlib::ShellOut).to receive(:new).with('ls', { user: 'foobar', cwd: '/tmp', environment: { PATH: '/tmp/bin' } })

        dummy_class.do_shell_out('ls', 'foobar', '/tmp', env: { PATH: '/tmp/bin' })
      end
    end

    context 'when command can not be executed' do
      let(:shellout_object) { double('shellout', run_command: true) }

      it 'logs relevant information' do
        allow(Mixlib::ShellOut).to receive(:new).and_return(shellout_object)
        allow(shellout_object).to receive(:run_command).and_raise(Errno::EACCES)

        expect(Chef::Log).to receive(:info).with("Cannot execute ls.")

        dummy_class.do_shell_out('ls')
      end
    end

    context 'when command not found' do
      let(:shellout_object) { double('shellout', run_command: true) }

      it 'logs relevant information' do
        allow(Mixlib::ShellOut).to receive(:new).and_return(shellout_object)
        allow(shellout_object).to receive(:run_command).and_raise(Errno::ENOENT)

        expect(Chef::Log).to receive(:info).with("ls does not exist.")

        dummy_class.do_shell_out('ls')
      end
    end
  end

  describe '.do_shell_out_with_embedded_path' do
    context 'without optional arguments' do
      it 'calls do_shell_out with embedded bin path prependend to PATH' do
        allow(ENV).to receive(:[]).with('PATH').and_return('/usr/local/bin')

        expect(dummy_class).to receive(:do_shell_out).with('ls', nil, nil, env: { PATH: '/opt/gitlab/embedded/bin:/usr/local/bin' })

        dummy_class.do_shell_out_with_embedded_path('ls')
      end
    end

    context 'without PATH specified in optional env argument' do
      it 'calls do_shell_out with embedded bin path prependend to PATH' do
        allow(ENV).to receive(:[]).with('PATH').and_return('/usr/local/bin')

        expect(dummy_class).to receive(:do_shell_out).with('ls', nil, nil, env: { PATH: '/opt/gitlab/embedded/bin:/tmp/bin:/usr/local/bin' })

        dummy_class.do_shell_out_with_embedded_path('ls', env: { 'PATH' => '/tmp/bin' })
      end
    end
  end
end
