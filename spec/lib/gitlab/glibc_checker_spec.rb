require 'spec_helper'
require 'gitlab/glibc_checker'

RSpec.describe Gitlab::GlibcChecker do
  let(:checker) { described_class.new }

  describe '#initialize' do
    it 'initializes empty issues array' do
      expect(checker.issues).to eq([])
    end

    it 'initializes max_required_version to nil' do
      expect(checker.max_required_version).to be_nil
    end
  end

  describe '#check_all' do
    before do
      allow(checker).to receive(:find_so_files).and_return([])
      allow(checker).to receive(:find_binaries).and_return([])
      allow(checker).to receive(:get_system_glibc_version).and_return('2.31')
      allow(checker).to receive(:log_info)
      allow(checker).to receive(:log_error)
    end

    it 'gets system GLIBC version' do
      expect(checker).to receive(:get_system_glibc_version)
      checker.check_all
    end

    it 'finds .so files' do
      expect(checker).to receive(:find_so_files)
      checker.check_all
    end

    it 'finds binaries' do
      expect(checker).to receive(:find_binaries)
      checker.check_all
    end

    it 'checks each .so file and binary' do
      so_files = ['/opt/gitlab/lib/libssl.so.1.1', '/opt/gitlab/lib/libcrypto.so.1.1']
      binaries = ['/opt/gitlab/embedded/bin/ruby']
      allow(checker).to receive(:find_so_files).and_return(so_files)
      allow(checker).to receive(:find_binaries).and_return(binaries)
      allow(checker).to receive(:check_file)

      checker.check_all

      (so_files + binaries).each do |file|
        expect(checker).to have_received(:check_file).with(file)
      end
    end

    it 'reports results' do
      expect(checker).to receive(:report_results)
      checker.check_all
    end
  end

  describe '#get_system_glibc_version' do
    it 'returns GLIBC version from ldd output' do
      allow(Gitlab::Util).to receive(:shellout_stdout).and_return('ldd (GNU libc) 2.31')
      expect(checker.send(:get_system_glibc_version)).to eq('2.31')
    end

    it 'returns unknown when ldd fails' do
      allow(Gitlab::Util).to receive(:shellout_stdout).and_raise(Gitlab::Util::ShellOutExecutionError.new('ldd', 1, '', 'error'))
      allow(checker).to receive(:warn)

      expect(checker.send(:get_system_glibc_version)).to eq('unknown')
    end

    it 'returns unknown when version cannot be parsed' do
      allow(Gitlab::Util).to receive(:shellout_stdout).and_return('some output without version')
      expect(checker.send(:get_system_glibc_version)).to eq('unknown')
    end

    it 'handles nil output gracefully' do
      allow(Gitlab::Util).to receive(:shellout_stdout).and_return(nil)
      expect(checker.send(:get_system_glibc_version)).to eq('unknown')
    end
  end

  describe 'ignored symbols' do
    before do
      allow(checker).to receive(:log_info)
      allow(checker).to receive(:log_error)
      allow(File).to receive(:file?).and_return(true)
      allow(File).to receive(:directory?).and_return(true)
    end

    %w[
      /opt/gitlab/embedded/lib/ruby/gems/3.4.0/extensions/x86_64-linux/3.4.0/grpc-1.81.0/grpc/grpc_c.so
      /opt/gitlab/embedded/lib/ruby/gems/3.4.0/gems/grpc-1.81.0/src/ruby/lib/grpc/grpc_c.so
    ].each do |grpc_file|
      it "ignores the _dl_find_object symbol in #{grpc_file}" do
        allow(Dir).to receive(:glob).and_return([grpc_file])

        allow(Gitlab::Util).to receive(:shellout_stdout) do |cmd|
          case cmd
          when /ldd/
            'ldd (GNU libc) 2.34'
          when /file/
            'application/x-sharedlib'
          when /objdump/
            "0000000000000000       F *UND*    0000000000000000              _dl_find_object@GLIBC_2.35\n" \
              "0000000000000000       F *UND*    0000000000000000              memcpy@GLIBC_2.14\n"
          else
            ''
          end
        end

        checker.check_all

        expect(checker.issues).to be_empty
        expect(checker.max_required_version).to eq('2.14')
      end
    end

    it 'still flags other symbols exceeding the system version in the grpc gem' do
      grpc_file = '/opt/gitlab/embedded/lib/ruby/gems/3.4.0/gems/grpc-1.81.0/src/ruby/lib/grpc/grpc_c.so'
      allow(Dir).to receive(:glob).and_return([grpc_file])

      allow(Gitlab::Util).to receive(:shellout_stdout) do |cmd|
        case cmd
        when /ldd/
          'ldd (GNU libc) 2.34'
        when /file/
          'application/x-sharedlib'
        when /objdump/
          "0000000000000000       F *UND*    0000000000000000              _dl_find_object@GLIBC_2.35\n" \
            "0000000000000000       F *UND*    0000000000000000              some_other_symbol@GLIBC_2.38\n"
        else
          ''
        end
      end

      expect { checker.check_all }.to raise_error(/GLIBC check failed/)
      expect(checker.max_required_version).to eq('2.38')
      expect(checker).to have_received(:log_error).with(/some_other_symbol@GLIBC_2\.38/)
      expect(checker).not_to have_received(:log_error).with(/_dl_find_object/)
    end

    it 'does not strip _dl_find_object from unrelated files' do
      other_file = '/opt/gitlab/embedded/lib/libfoo.so'
      allow(Dir).to receive(:glob).and_return([other_file])

      allow(Gitlab::Util).to receive(:shellout_stdout) do |cmd|
        case cmd
        when /ldd/
          'ldd (GNU libc) 2.34'
        when /file/
          'application/x-sharedlib'
        when /objdump/
          "0000000000000000       F *UND*    0000000000000000              _dl_find_object@GLIBC_2.35\n"
        else
          ''
        end
      end

      expect { checker.check_all }.to raise_error(/GLIBC check failed/)
      expect(checker.max_required_version).to eq('2.35')
    end
  end

  describe '#extract_glibc_symbols' do
    it 'extracts symbol names grouped by version' do
      objdump_output = <<~OUTPUT
        0000000000000000       F *UND*    0000000000000000              epoll_pwait2@GLIBC_2.35
        0000000000000000       F *UND*    0000000000000000              memcpy@GLIBC_2.14
        0000000000000000       F *UND*    0000000000000000              close@GLIBC_2.2.5
      OUTPUT

      result = checker.send(:extract_glibc_symbols, objdump_output)

      expect(result['2.35']).to eq(['epoll_pwait2@GLIBC_2.35'])
      expect(result['2.14']).to eq(['memcpy@GLIBC_2.14'])
      expect(result['2.2.5']).to eq(['close@GLIBC_2.2.5'])
    end

    it 'groups multiple symbols under the same version' do
      objdump_output = <<~OUTPUT
        0000000000000000       F *UND*    0000000000000000              epoll_pwait2@GLIBC_2.35
        0000000000000000       F *UND*    0000000000000000              futex_waitv@GLIBC_2.35
      OUTPUT

      result = checker.send(:extract_glibc_symbols, objdump_output)

      expect(result['2.35']).to contain_exactly('epoll_pwait2@GLIBC_2.35', 'futex_waitv@GLIBC_2.35')
    end

    it 'returns empty hash for output with no symbols' do
      expect(checker.send(:extract_glibc_symbols, '')).to eq({})
    end

    it 'returns empty hash for output with only bare GLIBC version references' do
      expect(checker.send(:extract_glibc_symbols, "GLIBC_2.31\n")).to eq({})
    end
  end

  describe 'logging files exceeding system version' do
    before do
      allow(checker).to receive(:log_info)
      allow(checker).to receive(:log_error)
      allow(File).to receive(:file?).and_return(true)
      allow(File).to receive(:directory?).and_return(true)
      allow(Dir).to receive(:glob).and_return(['/opt/gitlab/lib/libssl.so.1.1', '/opt/gitlab/lib/libz.so.1'])
    end

    it 'logs files that exceed system version during check_all' do
      allow(Gitlab::Util).to receive(:shellout_stdout) do |cmd|
        case cmd
        when /ldd/
          'ldd (GNU libc) 2.17'
        when /file/
          'application/x-sharedlib'
        when /objdump.*libssl/
          "0000000000000000       F *UND*    0000000000000000              epoll_pwait2@GLIBC_2.31\n"
        when /objdump.*libz/
          "0000000000000000       F *UND*    0000000000000000              close@GLIBC_2.2.5\n"
        else
          ''
        end
      end

      expect { checker.check_all }.to raise_error(/GLIBC check failed/)

      expect(checker).to have_received(:log_error).with(/Files exceeding system GLIBC version/)
      expect(checker).to have_received(:log_error).with(/libssl.so.1.1/)
      expect(checker).to have_received(:log_error).with(/epoll_pwait2@GLIBC_2\.31/)
    end

    it 'does not log symbols from files that do not exceed system version' do
      allow(Gitlab::Util).to receive(:shellout_stdout) do |cmd|
        case cmd
        when /ldd/
          'ldd (GNU libc) 2.17'
        when /file/
          'application/x-sharedlib'
        when /objdump.*libssl/
          "0000000000000000       F *UND*    0000000000000000              epoll_pwait2@GLIBC_2.31\n"
        when /objdump.*libz/
          "0000000000000000       F *UND*    0000000000000000              close@GLIBC_2.2.5\n"
        else
          ''
        end
      end

      expect { checker.check_all }.to raise_error(/GLIBC check failed/)

      expect(checker).not_to have_received(:log_error).with(/close@GLIBC_2\.2\.5/)
    end

    it 'does not log header when no files exceed system version' do
      allow(Dir).to receive(:glob).and_return(['/opt/gitlab/lib/libz.so.1'])

      allow(Gitlab::Util).to receive(:shellout_stdout) do |cmd|
        case cmd
        when /ldd/
          'ldd (GNU libc) 2.31'
        when /file/
          'application/x-sharedlib'
        when /objdump/
          "0000000000000000       F *UND*    0000000000000000              close@GLIBC_2.2.5\n"
        else
          ''
        end
      end

      checker.check_all

      expect(checker).not_to have_received(:log_error).with(/Files exceeding system GLIBC version/)
    end
  end

  describe '#check_file' do
    it 'records an issue with the objdump failure details when objdump fails' do
      error = Gitlab::Util::ShellOutExecutionError.new('objdump -t /opt/gitlab/lib/libssl.so.1.1', 1, '', 'boom')
      allow(Gitlab::Util).to receive(:shellout_stdout).and_raise(error)

      checker.send(:check_file, '/opt/gitlab/lib/libssl.so.1.1')

      expect(checker.issues).to contain_exactly(
        'Error checking /opt/gitlab/lib/libssl.so.1.1: objdump failed (Execution of command `objdump -t /opt/gitlab/lib/libssl.so.1.1` failed with exit code 1.)'
      )
    end
  end

  describe '.check_all' do
    it 'creates instance and calls check_all' do
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:check_all)

      described_class.check_all

      expect(instance).to have_received(:check_all)
    end
  end
end
