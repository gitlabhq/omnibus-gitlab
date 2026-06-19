require 'spec_helper'
require 'gitlab/linker_libs_helper'

RSpec.describe LinkerLibsHelper do
  # Fresh instance per example so internal state never leaks between
  # tests. The keyword arguments mirror what `OpenSSLHelper` would
  # pass at production time.
  let(:helper) do
    described_class.new(
      base_libs: %w[libssl libcrypto],
      pkg_config_files: { 'foo.pc' => nil, 'bar.pc' => nil },
      pkg_config_threshold: 2
    )
  end

  before do
    # Silence the progress `puts` from `find_deps` and `append_deps`. The
    # output is useful at omnibus build time but shows up as noise in the
    # spec runner.
    allow(helper).to receive(:puts)

    allow(IO).to receive(:popen).and_call_original
    allow(LinkerHelper).to receive(:system)
  end

  describe '#find_libs' do
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

  describe '#allowed_libs' do
    context 'when ldconfig returns a single entry per base lib' do
      before do
        allow(LinkerHelper).to receive(:ldconfig).and_return(
          'libssl.so' => '/lib64/libssl.so',
          'libcrypto.so' => '/lib64/libcrypto.so'
        )
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libssl.so').and_return(
          'libcrypto.so' => '/lib64/libcrypto.so'
        )
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libcrypto.so').and_return({})
      end

      it 'includes the base libs and their direct deps' do
        expect(helper.allowed_libs).to include('libssl', 'libcrypto')
      end
    end

    context 'when ldconfig returns multiple versioned entries per base lib' do
      # Mirrors AlmaLinux 9 / Ubuntu where ldconfig returns multiple versioned
      # entries for libssl (libssl.so, libssl.so.3, libssl.so.1.1, etc.). The
      # fixture stages each versioned entry with its own transitive dep so the
      # examples can confirm the walk covers every branch's reachable libs.
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

      it 'includes transitive deps reachable only through the first libssl entry' do
        # libz is only reachable via libcrypto.so.3 which is reached via libssl.so.3.
        expect(helper.allowed_libs).to include('libz')
      end

      it 'includes transitive deps reachable only through the second libssl entry' do
        # libdl is only reachable via libcrypto.so.1.1 which is reached via libssl.so.1.1.
        expect(helper.allowed_libs).to include('libdl')
      end
    end

    context 'when a transitive dep path is inside /opt/gitlab' do
      # Pins the guard that stops the walk once a path crosses into the
      # bundled /opt/gitlab tree. libfoo is reached via libssl's ldd output
      # so its basename lands in allowed_libs, but its own transitive
      # libdeeper must not appear because /opt/gitlab paths are not walked.
      before do
        allow(LinkerHelper).to receive(:ldconfig).and_return(
          'libssl.so' => '/lib64/libssl.so',
          'libcrypto.so' => '/lib64/libcrypto.so'
        )
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libssl.so').and_return(
          'libfoo.so' => '/opt/gitlab/embedded/lib/libfoo.so'
        )
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libcrypto.so').and_return({})
      end

      it 'does not walk transitive deps below the /opt/gitlab path' do
        expect(helper.allowed_libs).not_to include('libdeeper')
        expect(LinkerHelper).not_to have_received(:ldd).with(/^\/opt\/gitlab/)
      end
    end

    context 'when ldd output includes a "statically" entry' do
      # The reject filter inside the walk drops "statically" before it
      # reaches deps, so it never appears in the final allowed_libs list.
      before do
        allow(LinkerHelper).to receive(:ldconfig).and_return(
          'libssl.so' => '/lib64/libssl.so',
          'libcrypto.so' => '/lib64/libcrypto.so'
        )
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libssl.so').and_return(
          'linux-vdso.so.1' => 'statically'
        )
        allow(LinkerHelper).to receive(:ldd).with('/lib64/libcrypto.so').and_return({})
      end

      it 'omits the "statically" entry from the result' do
        expect(helper.allowed_libs).not_to include('statically')
      end
    end

    context 'memoization' do
      before do
        allow(LinkerHelper).to receive(:ldconfig).and_return(
          'libssl.so' => '/lib64/libssl.so',
          'libcrypto.so' => '/lib64/libcrypto.so'
        )
        allow(LinkerHelper).to receive(:ldd).and_return({})
      end

      it 'walks the linker tree only once across repeated calls' do
        3.times { helper.allowed_libs }
        # Two base libs (libssl, libcrypto) -- ldconfig fires once per base
        # lib on the first allowed_libs call, then the memoized result
        # short-circuits every subsequent call.
        expect(LinkerHelper).to have_received(:ldconfig).twice
      end

      it 'returns the same array object across calls' do
        first = helper.allowed_libs
        second = helper.allowed_libs
        expect(first).to equal(second)
      end
    end
  end
end
