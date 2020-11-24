require 'chef_helper'

RSpec.describe LoggingHelper do
  let(:log) { spy('Chef::Log') }

  before do
    subject.reset
    stub_const('Chef::Log', log)
  end

  context '.messages' do
    it 'starts with no messages' do
      expect(subject.messages).to eq([])
    end
  end

  context '.log' do
    it 'records into .messages' do
      subject.log('one')
      expect(subject.messages).to contain_exactly(Hash)
    end

    it 'records message' do
      subject.log('two')
      expect(subject.messages).to contain_exactly(hash_including(message: 'two'))
    end

    it 'records two messages' do
      subject.log('one')
      subject.log('two')
      expect(subject.messages).to contain_exactly(
        hash_including(message: 'one'),
        hash_including(message: 'two')
      )
    end

    it 'optionally records kind' do
      subject.log('three', kind: :fake)
      expect(subject.messages).to contain_exactly(hash_including(kind: :fake))
    end
  end

  context '.deprecation' do
    it 'calls Chef::Log.warn' do
      subject.deprecation('hello')
      expect(log).to have_received(:warn).with('hello')
    end

    it 'adds the kind :deprecation' do
      subject.deprecation('basic')
      expect(subject.messages).to contain_exactly(hash_including(kind: :deprecation))
    end
  end

  context '.warning' do
    it 'calls Chef::Log.warn' do
      subject.deprecation('hello')
      expect(log).to have_received(:warn).with('hello')
    end

    it 'adds the kind :warning' do
      subject.warning('basic')
      expect(subject.messages).to contain_exactly(hash_including(kind: :warning))
    end
  end

  context '.note' do
    it 'adds the kind :note' do
      subject.note('basic')
      expect(subject.messages).to contain_exactly(hash_including(kind: :note))
    end
  end

  context '.report' do
    it 'prints nothing if nothing happened' do
      expect { subject.report }.not_to output.to_stdout
    end

    it 'prints a removal header, then removal' do
      subject.removal('one')
      expect { subject.report }.to output(/\nRemovals:\none/).to_stdout
    end

    it 'prints a removal header, then removals' do
      subject.removal('one')
      subject.removal('two')
      expect { subject.report }.to output(/\nRemovals:\none\ntwo/).to_stdout
    end

    it 'prints a deprecation header, then deprecation' do
      subject.deprecation('one')
      expect { subject.report }.to output(/\nDeprecations:\none/).to_stdout
    end

    it 'prints a deprecation header, then deprecations' do
      subject.deprecation('one')
      subject.deprecation('two')
      expect { subject.report }.to output(/\nDeprecations:\none\ntwo/).to_stdout
    end

    it 'prints a warning header, then warning' do
      subject.warning('one')
      expect { subject.report }. to output(/\nWarnings:\none/).to_stdout
    end

    it 'prints a warning header, then warnings' do
      subject.warning('one')
      subject.warning('two')
      expect { subject.report }.to output(/\nWarnings:\none\ntwo/).to_stdout
    end

    it 'prints a note header, then note' do
      subject.note('one')
      expect { subject.report }. to output(/\nNotes:\none/).to_stdout
    end

    it 'prints a note header, then notes' do
      subject.note('one')
      subject.note('two')
      expect { subject.report }.to output(/\nNotes:\none\ntwo/).to_stdout
    end

    it 'prints a removal header, removals, deprecation header, deprecations, warning header, warnings, note header then notes' do
      subject.removal('one')
      subject.removal('two')
      subject.deprecation('three')
      subject.deprecation('four')
      subject.warning('five')
      subject.warning('six')
      subject.note('seven')
      subject.note('eight')

      output = <<~EOS

      Removals:
      one
      two


      Deprecations:
      three
      four


      Warnings:
      five
      six


      Notes:
      seven
      eight

      EOS

      expect { subject.report }
        .to output(output).to_stdout
    end
  end
end
