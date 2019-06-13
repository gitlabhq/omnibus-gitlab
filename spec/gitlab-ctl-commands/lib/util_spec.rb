require 'spec_helper'

$LOAD_PATH << File.join(__dir__, '../../../files/gitlab-ctl-commands/lib')

require 'gitlab_ctl'

describe GitlabCtl::Util do
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
end
