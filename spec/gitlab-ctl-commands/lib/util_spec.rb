require 'spec_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')

require 'gitlab_ctl'

RSpec.describe GitlabCtl::Util do
  context 'when there is no TTY available' do
    before do
      allow(STDIN).to receive(:tty?).and_return(false)
    end

    it 'asks for a database password in a non-interactive mode' do
      allow(STDIN).to receive(:gets).and_return('pass')

      expect(described_class.get_password).to eq('pass')
    end

    it 'strips a new line character from the password' do
      allow(STDIN).to receive(:tty?).and_return(false)
      allow(STDIN).to receive(:gets).and_return("mypass\n")

      expect(described_class.get_password).to eq('mypass')
    end
  end

  context 'when there is TTY available' do
    before do
      allow(STDIN).to receive(:tty?).and_return(true)
    end

    it 'asks for confirmation' do
      expect(STDIN).to receive(:getpass).twice.and_return("mypass")

      expect(described_class.get_password(do_confirm: true)).to eq('mypass')
    end

    it 'skips confirmation' do
      expect(STDIN).to receive(:getpass).and_return("mypass")

      expect(described_class.get_password(do_confirm: false)).to eq('mypass')
    end
  end

  describe '#roles' do
    let(:fake_base_path) { '/foo' }
    let(:fake_hostname) { 'fakehost.fakedomain' }
    let(:fake_node_file) { "#{fake_base_path}/embedded/nodes/#{fake_hostname}.json" }

    before do
      hostname = double('hostname')
      allow(hostname).to receive(:stdout).and_return(fake_hostname)
      allow(GitlabCtl::Util).to receive(:run_command).with('hostname -f').and_return(hostname)
      allow(File).to receive(:exist?).with(fake_node_file).and_return(true)
    end

    it 'returns an empty list when no roles are defined' do
      empty_node = {
        normal: {
          roles: {}
        }
      }
      allow(File).to receive(:read).with(fake_node_file).and_return(empty_node.to_json)
      expect(described_class.roles(fake_base_path)).to eq([])
    end

    it 'returns a list of roles that are defined' do
      roled_node = {
        normal: {
          roles: {
            role_one: {
              enable: true
            },
            role_two: {
              enable: false
            },
            role_three: {
              enable: true
            }
          }
        }
      }
      allow(File).to receive(:read).with(fake_node_file).and_return(roled_node.to_json)
      expect(described_class.roles(fake_base_path)).to eq(%w[role_one role_three])
    end
  end

  describe '#parse_json_file' do
    it 'fails on malformed JSON file' do
      malformed_json = <<~MSG
      {
      'foo': 'bar'
      MSG
      allow(File).to receive(:read).with('/tmp/foo').and_return(malformed_json)

      expect { GitlabCtl::Util.parse_json_file('/tmp/foo') }.to raise_error(GitlabCtl::Errors::NodeError, "Error reading /tmp/foo, has reconfigure been run yet?")
    end

    it 'do not fail on empty json file' do
      allow(File).to receive(:read).with('/tmp/foo').and_return('{}')

      expect(GitlabCtl::Util.parse_json_file('/tmp/foo')).to eq({})
    end

    it 'fails on incomplete but valid node attribute file' do
      incomplete_node_attributes = <<~MSG
      {
        "name": "a-random-server"
      }
      MSG
      allow(File).to receive(:read).with('/opt/gitlab/embedded/nodes/12345.json').and_return(incomplete_node_attributes)

      expect { GitlabCtl::Util.parse_json_file('/opt/gitlab/embedded/nodes/12345.json') }.to raise_error(GitlabCtl::Errors::NodeError, "Attributes not found in /opt/gitlab/embedded/nodes/12345.json, has reconfigure been run yet?")
    end
  end
end
