$LOAD_PATH << File.join(__dir__, '../../../../../../files/gitlab-ctl-commands/lib')
require 'gitlab_ctl'

require_relative '../../../../../../files/gitlab-ctl-commands/lib/gitlab_ctl/registry/garbage_collect'

RSpec.describe GitlabCtl::Registry::GarbageCollect do
  describe '#execute!' do
    let(:ctl) { double('ctl') }
    let(:path) { '/var/opt/gitlab/registry/config.yml' }
    let(:args) { [] }
    let(:garbage_collect) { described_class.new(ctl, path, args) }

    before do
      allow(GitlabCtl::Registry::Database).to receive(:registry_dir).and_return('/var/opt/gitlab/registry')
      allow(garbage_collect).to receive(:enabled?).and_return(true)
      allow(garbage_collect).to receive(:config?).and_return(true)
      allow(garbage_collect).to receive(:stop!)
      allow(garbage_collect).to receive(:start!)
      allow(garbage_collect).to receive(:log)
      allow(ctl).to receive(:run_command).and_return(double(exitstatus: 0))
    end

    it 'changes to the registry directory before executing' do
      expect(Dir).to receive(:chdir).with('/var/opt/gitlab/registry')
      garbage_collect.execute!
    end
  end
end
