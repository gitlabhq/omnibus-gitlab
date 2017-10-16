require 'chef_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands-ee/lib')

require 'consul'

describe ConsulHelper::Kv do
  let(:consul_cmd) { '/opt/gitlab/embedded/bin/consul' }

  it 'allows nil values' do
    results = double('results', run_command: [], error!: nil)
    expect(Mixlib::ShellOut).to receive(:new).with("#{consul_cmd} kv put foo ").and_return(results)
    described_class.send(:put, 'foo')
  end
end
