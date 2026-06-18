require 'spec_helper'
require 'gitlab/openssl_helper'

RSpec.describe OpenSSLHelper do
  subject(:helper) { described_class }

  # Reset class-level state between examples so tests are independent.
  before do
    helper.instance_variable_set(:@deps, [])
    helper.instance_variable_set(:@system_pkg_config_dirs, nil)

    allow(IO).to receive(:popen).and_call_original
    allow(LinkerHelper).to receive(:system)
  end

  describe '.find_libs' do
    before do
      allow(LinkerHelper).to receive(:ldconfig).and_return(
        'libssl.so.3' => '/lib64/libssl.so.3',
        'libssl.so' => '/lib64/libssl.so',
        'libcrypto.so.3' => '/lib64/libcrypto.so.3',
        'libcrypto.so' => '/lib64/libcrypto.so',
        'libz.so.1' => '/lib64/libz.so.1'
      )
    end

    it 'returns only entries whose name starts with the given prefix' do
      result = helper.find_libs('libssl')
      expect(result.keys).to contain_exactly('libssl.so.3', 'libssl.so')
    end

    it 'does not include unrelated libraries' do
      result = helper.find_libs('libssl')
      expect(result).not_to have_key('libcrypto.so.3')
    end
  end

  describe '.append_deps' do
    context 'when path is inside /opt/gitlab' do
      it 'does not add any deps' do
        helper.append_deps('/opt/gitlab/embedded/lib/libz.so.1')
        expect(helper.instance_variable_get(:@deps)).to be_empty
      end
    end

    context 'when path does not start with /' do
      it 'does not add any deps' do
        helper.append_deps('statically')
        expect(helper.instance_variable_get(:@deps)).to be_empty
      end
    end

    context 'when path is a system library' do
      before do
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libssl.so.3').and_return(
          'libcrypto.so.3' => '/lib64/libcrypto.so.3',
          'libc.so.6' => '/lib64/libc.so.6'
        )
      end

      it 'appends the ldd results to @deps' do
        helper.append_deps('/lib64/libssl.so.3')
        expect(helper.instance_variable_get(:@deps)).to include('/lib64/libcrypto.so.3', '/lib64/libc.so.6')
      end

      it 'does not add "statically" entries' do
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libssl.so.3').and_return(
          'linux-vdso.so.1' => 'statically'
        )
        helper.append_deps('/lib64/libssl.so.3')
        expect(helper.instance_variable_get(:@deps)).not_to include('statically')
      end
    end
  end

  describe '.find_deps' do
    # Simulates AlmaLinux 9 / Ubuntu where ldconfig returns multiple versioned
    # entries for libssl (libssl.so, libssl.so.3, libssl.so.1.1, etc.).
    # The bug: with the old @cursor logic the post-libs.each traversal loop
    # started at cursor = start + libs.length, silently skipping the deps
    # written by the libs.each block and any transitive deps reachable only
    # through them.
    context 'when find_libs returns multiple entries for a base lib' do
      before do
        # ldconfig returns two versioned libssl entries (common on AlmaLinux 9 / Ubuntu)
        allow(LinkerHelper).to receive(:ldconfig).and_return(
          'libssl.so.3' => '/lib64/libssl.so.3',
          'libssl.so.1.1' => '/lib64/libssl.so.1.1'
        )

        # libssl.so.3 depends on libcrypto.so.3 and libc.so.6
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libssl.so.3').and_return(
          'libcrypto.so.3' => '/lib64/libcrypto.so.3',
          'libc.so.6' => '/lib64/libc.so.6'
        )

        # libssl.so.1.1 depends on libcrypto.so.1.1 and libc.so.6
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libssl.so.1.1').and_return(
          'libcrypto.so.1.1' => '/lib64/libcrypto.so.1.1',
          'libc.so.6' => '/lib64/libc.so.6'
        )

        # libcrypto.so.3 has a transitive dep: libz.so.1
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libcrypto.so.3').and_return(
          'libz.so.1' => '/lib64/libz.so.1'
        )

        # libcrypto.so.1.1 has a transitive dep: libdl.so.2
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libcrypto.so.1.1').and_return(
          'libdl.so.2' => '/lib64/libdl.so.2'
        )

        # Leaf libraries have no further deps
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libc.so.6').and_return({})
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libz.so.1').and_return({})
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libdl.so.2').and_return({})
      end

      it 'includes direct deps from the first libssl entry' do
        helper.find_deps('libssl')
        deps = helper.instance_variable_get(:@deps)
        expect(deps).to include('/lib64/libcrypto.so.3')
      end

      it 'includes direct deps from the second libssl entry' do
        helper.find_deps('libssl')
        deps = helper.instance_variable_get(:@deps)
        expect(deps).to include('/lib64/libcrypto.so.1.1')
      end

      it 'includes transitive deps reachable only through the first libssl entry (regression for cursor bug)' do
        helper.find_deps('libssl')
        deps = helper.instance_variable_get(:@deps)
        # libz.so.1 is only reachable via libcrypto.so.3 -> libssl.so.3.
        # The old cursor bug caused the post-libs.each loop to start past
        # these entries, so libz.so.1 was never visited.
        expect(deps).to include('/lib64/libz.so.1')
      end

      it 'includes transitive deps reachable only through the second libssl entry' do
        helper.find_deps('libssl')
        deps = helper.instance_variable_get(:@deps)
        expect(deps).to include('/lib64/libdl.so.2')
      end
    end

    context 'when find_libs returns a single entry' do
      before do
        allow(LinkerHelper).to receive(:ldconfig).and_return(
          'libssl.so' => '/lib64/libssl.so'
        )
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libssl.so').and_return(
          'libcrypto.so' => '/lib64/libcrypto.so'
        )
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libcrypto.so').and_return({})
      end

      it 'includes the direct dep' do
        helper.find_deps('libssl')
        deps = helper.instance_variable_get(:@deps)
        expect(deps).to include('/lib64/libcrypto.so')
      end
    end
  end

  describe '.allowed_libs' do
    # Full integration-style test: two base libs (libssl, libcrypto), each with
    # multiple ldconfig entries, verifying that allowed_libs returns the correct
    # set of basename-stripped library names including all transitive deps.
    before do
      allow(LinkerHelper).to receive(:ldconfig).and_return(
        'libssl.so.3' => '/lib64/libssl.so.3',
        'libssl.so.1.1' => '/lib64/libssl.so.1.1',
        'libcrypto.so.3' => '/lib64/libcrypto.so.3',
        'libcrypto.so.1.1' => '/lib64/libcrypto.so.1.1'
      )

      allow(LinkerHelper).to receive(:ldd).with('/lib64/libssl.so.3').and_return(
        'libcrypto.so.3' => '/lib64/libcrypto.so.3',
        'libc.so.6' => '/lib64/libc.so.6'
      )
      allow(LinkerHelper).to receive(:ldd).with('/lib64/libssl.so.1.1').and_return(
        'libcrypto.so.1.1' => '/lib64/libcrypto.so.1.1',
        'libc.so.6' => '/lib64/libc.so.6'
      )
      allow(LinkerHelper).to receive(:ldd).with('/lib64/libcrypto.so.3').and_return(
        'libz.so.1' => '/lib64/libz.so.1'
      )
      allow(LinkerHelper).to receive(:ldd).with('/lib64/libcrypto.so.1.1').and_return(
        'libdl.so.2' => '/lib64/libdl.so.2'
      )
      allow(LinkerHelper).to receive(:ldd).with('/lib64/libc.so.6').and_return({})
      allow(LinkerHelper).to receive(:ldd).with('/lib64/libz.so.1').and_return({})
      allow(LinkerHelper).to receive(:ldd).with('/lib64/libdl.so.2').and_return({})
    end

    it 'returns basename-stripped library names without duplicates' do
      result = helper.allowed_libs
      expect(result).to include('libssl', 'libcrypto', 'libc', 'libz', 'libdl')
    end

    it 'does not contain duplicates' do
      result = helper.allowed_libs
      expect(result).to eq(result.uniq)
    end

    it 'includes transitive deps from all ldconfig entries (regression for cursor bug)' do
      result = helper.allowed_libs
      # libz is only reachable via libcrypto.so.3 which is reached via libssl.so.3
      expect(result).to include('libz')
      # libdl is only reachable via libcrypto.so.1.1 which is reached via libssl.so.1.1
      expect(result).to include('libdl')
    end
  end
end
