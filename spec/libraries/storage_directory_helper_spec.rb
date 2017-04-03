require 'chef_helper'

describe StorageDirectoryHelper do
  let(:success_shell) do
    shell = instance_double(Mixlib::ShellOut)
    allow(shell).to receive(:exitstatus).and_return(0)
    shell
  end

  let(:fail_shell) do
    shell = instance_double(Mixlib::ShellOut)
    allow(shell).to receive(:exitstatus).and_return(1)
    shell
  end

  before { allow(Gitlab).to receive(:[]).and_call_original }

  describe :validate do
    context 'owner provided' do
      subject { ::StorageDirectoryHelper.new('git', nil, nil) }

      it 'checks directory and owner and succeeds' do
        expect(subject).to receive(:run_command).with("set -x && [ -d \"/tmp/validate\" ]", any_args).and_return(success_shell)
        expect(subject).to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%U' $(readlink -f /tmp/validate))\" = 'git' ]", any_args).and_return(success_shell)
        expect(subject.validate('/tmp/validate')).to eq(true)
      end

      it 'fails when path is not a directory' do
        expect(subject).to receive(:run_command).with("set -x && [ -d \"/tmp/validate\" ]", any_args).and_return(fail_shell)
        expect(subject).not_to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%U' $(readlink -f /tmp/validate))\" = 'git' ]", any_args)
        expect(subject.validate('/tmp/validate')).to eq(false)
      end

      it 'fails when owner does not match' do
        expect(subject).to receive(:run_command).with("set -x && [ -d \"/tmp/validate\" ]", any_args).and_return(success_shell)
        expect(subject).to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%U' $(readlink -f /tmp/validate))\" = 'git' ]", any_args).and_return(fail_shell)
        expect(subject.validate('/tmp/validate')).to eq(false)
      end
    end

    context 'owner and group provided' do
      subject { ::StorageDirectoryHelper.new('git', 'root', nil) }

      it 'checks directory, owner and group and succeeds' do
        expect(subject).to receive(:run_command).with("set -x && [ -d \"/tmp/validate\" ]", any_args).and_return(success_shell)
        expect(subject).to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%U:%G' $(readlink -f /tmp/validate))\" = 'git:root' ]", any_args).and_return(success_shell)
        expect(subject.validate('/tmp/validate')).to eq(true)
      end

      it 'fails when path is not a directory' do
        expect(subject).to receive(:run_command).with("set -x && [ -d \"/tmp/validate\" ]", any_args).and_return(fail_shell)
        expect(subject).not_to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%U:%G' $(readlink -f /tmp/validate))\" = 'git:root' ]", any_args)
        expect(subject.validate('/tmp/validate')).to eq(false)
      end

      it 'fails when group does not match' do
        expect(subject).to receive(:run_command).with("set -x && [ -d \"/tmp/validate\" ]", any_args).and_return(success_shell)
        expect(subject).to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%U:%G' $(readlink -f /tmp/validate))\" = 'git:root' ]", any_args).and_return(fail_shell)
        expect(subject.validate('/tmp/validate')).to eq(false)
      end
    end

    context 'owner and permission mode provided' do
      subject { ::StorageDirectoryHelper.new('git', nil, '700') }

      it 'checks directory, owner and permissions and succeeds' do
        expect(subject).to receive(:run_command).with("set -x && [ -d \"/tmp/validate\" ]", any_args).and_return(success_shell)
        expect(subject).to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%U' $(readlink -f /tmp/validate))\" = 'git' ]", any_args).and_return(success_shell)
        expect(subject).to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%04a' $(readlink -f /tmp/validate) | grep -o '...$')\" = '700' ]", any_args).and_return(success_shell)
        expect(subject.validate('/tmp/validate')).to eq(true)
      end

      it 'fails when path is not a directory' do
        expect(subject).to receive(:run_command).with("set -x && [ -d \"/tmp/validate\" ]", any_args).and_return(fail_shell)
        expect(subject).not_to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%U:%G' $(readlink -f /tmp/validate))\" = 'git:root' ]", any_args)
        expect(subject).not_to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%04a' $(readlink -f /tmp/validate) | grep -o '...$')\" = '700' ]", any_args)
        expect(subject.validate('/tmp/validate')).to eq(false)
      end

      it 'fails when owner does not match' do
        expect(subject).to receive(:run_command).with("set -x && [ -d \"/tmp/validate\" ]", any_args).and_return(success_shell)
        expect(subject).to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%U' $(readlink -f /tmp/validate))\" = 'git' ]", any_args).and_return(fail_shell)
        expect(subject).not_to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%04a' $(readlink -f /tmp/validate) | grep -o '...$')\" = '700' ]", any_args)
        expect(subject.validate('/tmp/validate')).to eq(false)
      end

      it 'fails when permissions do not match' do
        expect(subject).to receive(:run_command).with("set -x && [ -d \"/tmp/validate\" ]", any_args).and_return(success_shell)
        expect(subject).to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%U' $(readlink -f /tmp/validate))\" = 'git' ]", any_args).and_return(success_shell)
        expect(subject).to receive(:run_command)
          .with("set -x && [ \"$(stat --printf='%04a' $(readlink -f /tmp/validate) | grep -o '...$')\" = '700' ]", any_args).and_return(fail_shell)
        expect(subject.validate('/tmp/validate')).to eq(false)
      end
    end
  end
end
