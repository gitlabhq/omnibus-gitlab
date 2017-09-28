require 'chef_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands-ee/lib')

require 'repmgr'

describe RepmgrHelper do
  let(:repmgr_base_cmd) { '/opt/gitlab/embedded/bin/repmgr  -f /var/opt/gitlab/postgresql/repmgr.conf' }
  let(:shellout) do
    double('shellout', error!: nil, stdout: 'xxxx', stderr: 'yyyy', run_command: nil)
  end

  let(:shellout_args) do
    {
      user: 'gitlab-psql',
      cwd: '/tmp',
      timeout: 604800
    }
  end

  before do
    allow(Mixlib::ShellOut).to receive(:new).and_return(shellout)
  end

  describe RepmgrHelper::Standby do
    context '#follow' do
      it 'calls repmgr with the correct arguments' do
        expect(Mixlib::ShellOut).to receive(:new).with(
          "#{repmgr_base_cmd} -h ahost -U auser -d adatabase -D /a/directory standby follow",
          shellout_args
        )
        args = {
          primary: 'ahost',
          user: 'auser',
          database: 'adatabase',
          directory: '/a/directory'
        }
        described_class.send(:follow, args)
      end
    end

    context '#clone' do
      it 'calls clone with the correct arguments' do
        expect(Mixlib::ShellOut).to receive(:new).with(
          "#{repmgr_base_cmd} -h ahost -U auser -d adatabase -D /a/directory standby clone",
          shellout_args
        )
        args = {
          primary: 'ahost',
          user: 'auser',
          database: 'adatabase',
          directory: '/a/directory'
        }

        described_class.send(:clone, args)
      end
    end

    context '#register' do
      it 'calls register with the correct arguments' do
        expect(Mixlib::ShellOut).to receive(:new).with(
          "#{repmgr_base_cmd} standby register",
          shellout_args
        )
        described_class.send(:register, {})
      end
    end

    context '#unregister' do
      it 'unregisters the current host if no node is specified' do
        expect(Mixlib::ShellOut).to receive(:new).with(
          "#{repmgr_base_cmd} standby unregister",
          shellout_args
        )
        described_class.send(:unregister, {})
      end

      it 'removes a different host if node is specified' do
        expect(Mixlib::ShellOut).to receive(:new).with(
          "#{repmgr_base_cmd} standby unregister --node=1234",
          shellout_args
        )
        described_class.send(:unregister, { node: 1234 })
      end
    end
  end

  describe RepmgrHelper::Cluster do
    context '#show' do
      it 'should call the correct command' do
        expect(Mixlib::ShellOut).to receive(:new).with(
          "#{repmgr_base_cmd} cluster show",
          shellout_args
        )
        described_class.send(:show, {})
      end
    end
  end

  describe RepmgrHelper::Master do
    context '#register' do
      it 'should register the master node' do
        expect(Mixlib::ShellOut).to receive(:new).with(
          "#{repmgr_base_cmd} master register",
          shellout_args
        )
        described_class.send(:register, {})
      end
    end
  end
end
