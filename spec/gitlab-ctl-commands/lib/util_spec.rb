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
end
