require 'spec_helper'
require 'omnibus-ctl'

RSpec.describe 'gitlab-ctl completion command' do
  let(:ctl) { Omnibus::Ctl.new('testing-ctl') }
  let(:completion_script_path) { '/opt/testing-ctl/embedded/share/bash-completion/completions/gitlab-ctl-bash-completion' }
  let(:ctl_file) { File.join(File.dirname(__FILE__), '../../../files/gitlab-ctl-commands/completion.rb') }

  before do
    ctl.load_file(ctl_file)
  end

  describe 'completion command' do
    context 'when completion script exists' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(completion_script_path).and_return(true)
      end

      it 'outputs instructions for enabling bash completion' do
        expect { ctl.completion('completion') }.to output(/Bash completion for gitlab-ctl is available/).to_stdout
      end

      it 'includes the path to the completion script' do
        expect { ctl.completion('completion') }.to output(%r{source /opt/testing-ctl/embedded/share/bash-completion/completions/gitlab-ctl-bash-completion}).to_stdout
      end

      it 'includes instructions for reloading shell configuration' do
        expect { ctl.completion('completion') }.to output(/source ~\/.bashrc/).to_stdout
      end

      it 'mentions bash-completion package requirement' do
        expect { ctl.completion('completion') }.to output(/bash-completion package must be installed/).to_stdout
      end

      it 'includes documentation link' do
        expect { ctl.completion('completion') }.to output(%r{docs\.gitlab\.com/omnibus/maintenance}).to_stdout
      end
    end

    context 'when completion script does not exist' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(completion_script_path).and_return(false)
      end

      it 'logs an error and exits with status 1' do
        expect(ctl).to receive(:log).with(/Error: Completion script not found/)
        expect(Kernel).to receive(:exit).with(1)
        ctl.completion('completion')
      end
    end
  end
end
