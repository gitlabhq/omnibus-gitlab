require 'spec_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands-ee/lib')

require 'repmgr'

RSpec.describe RepmgrHandler do
  let(:repmgr_base_cmd) { '/opt/gitlab/embedded/bin/repmgr  -f /var/opt/gitlab/postgresql/repmgr.conf' }
  let(:public_attributes) { { 'postgresql' => { 'dir' => '/var/opt/gitlab/postgresql' } } }
  let(:shellout) do
    double('shellout', error!: nil, stdout: 'xxxx', stderr: 'yyyy', run_command: nil)
  end

  let(:shellout_args) do
    {
      user: 'fakeuser',
      cwd: '/tmp',
      timeout: 604800
    }
  end

  before do
    allow(Mixlib::ShellOut).to receive(:new).and_return(shellout)
    allow(Etc).to receive(:getpwuid).and_return(double(name: 'fakeuser'))
    allow(GitlabCtl::Util).to receive(:get_public_node_attributes).and_return(public_attributes)
  end

  describe RepmgrHandler::Standby do
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

  describe RepmgrHandler::Cluster do
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

  describe RepmgrHandler::Master do
    context '#register' do
      it 'should register the master node' do
        expect(Mixlib::ShellOut).to receive(:new).with(
          "#{repmgr_base_cmd} master register",
          shellout_args
        )
        described_class.send(:register, {})
      end
    end

    context '#remove' do
      it 'should run as the current user by default' do
        expect(RepmgrHandler::Base).to receive(:cmd).with(
          "/opt/gitlab/embedded/bin/psql -qt -d gitlab_repmgr -h 127.0.0.1 -p 5432 -c \"DELETE FROM repmgr_gitlab_cluster.repl_nodes WHERE name='fake_node'\" -U fakeuser",
          'fakeuser'
        ).and_return('foo')
        described_class.send(:remove, { host: 'fake_node' })
      end

      it 'should connect as a different user when specified' do
        expect(RepmgrHandler::Base).to receive(:cmd).with(
          "/opt/gitlab/embedded/bin/psql -qt -d gitlab_repmgr -h 127.0.0.1 -p 5432 -c \"DELETE FROM repmgr_gitlab_cluster.repl_nodes WHERE name='fake_node'\" -U fakeuser2",
          'fakeuser'
        ).and_return('foo')
        described_class.send(:remove, { host: 'fake_node', user: 'fakeuser2' })
      end
    end
  end

  describe RepmgrHandler::Events do
    let(:args) do
      [
        nil, nil, nil, 1, 'fake_event', '1', 'fake timestamp', 'fake details'
      ]
    end

    context '#fire' do
      it 'returns nil on invalid ivents' do
        expect(described_class.send(:fire, args)).to be nil
      end

      it 'responds to valid events' do
        expect(described_class).to receive(:fake_event).and_return true
        described_class.send(:fire, args)
      end
    end

    context '#repmgrd_failover_promote' do
      it 'adds the failed master to the consul queue' do
        real_event = [
          nil, nil, nil, 1, 'repmgrd-failover-promote', '1', 'real timestamp', 'node 1 promoted to master; old master 2 marked as failed'
        ]
        expect(ConsulHandler::Kv).to receive(:put).with('gitlab/ha/postgresql/failed_masters/2')
        described_class.send(:fire, real_event)
      end
    end
  end
end
