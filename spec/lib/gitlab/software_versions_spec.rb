require 'spec_helper'
require 'gitlab/software_versions'
require 'tempfile'

RSpec.describe Gitlab::SoftwareVersions do
  # Valid sha256 values are 64 hex characters; use distinct fills so tests read
  # clearly while still passing checksum-format validation.
  sha = ->(char) { char * 64 }
  sha_3311 = sha['a']
  sha_349  = sha['b']
  sha_libffi = sha['c']
  sha_ubt = sha['d']

  let(:yaml_contents) do
    <<~YAML
      # Header comment that must be preserved.
      ---
      ruby:
        current: "3.3.11"
        next: "3.4.9"
        checksums:
          "3.3.11": "#{sha_3311}"
          "3.4.9": "#{sha_349}"
      libffi:
        version: "3.2.1"
        sha256: "#{sha_libffi}"
        ubt:
          revision: "3ubt"
          sha256: "#{sha_ubt}"
    YAML
  end

  let(:file) do
    Tempfile.new('software_versions').tap do |f|
      f.write(yaml_contents)
      f.close
    end
  end

  after { file.unlink }

  subject(:versions) { described_class.new(file.path) }

  describe '#update' do
    let(:new_sha) { 'e' * 64 }

    context 'for a component with a checksums map' do
      it 'adds the checksum and advances the next pin for a newer version' do
        versions.update('ruby', '3.4.10', sha256: new_sha)

        reloaded = YAML.load_file(file.path)
        expect(reloaded.dig('ruby', 'checksums', '3.4.10')).to eq(new_sha)
        expect(reloaded.dig('ruby', 'next')).to eq('3.4.10')
        expect(reloaded.dig('ruby', 'current')).to eq('3.3.11')
      end

      it 'records the checksum without moving next for a patch in the current series' do
        versions.update('ruby', '3.3.12', sha256: new_sha)

        reloaded = YAML.load_file(file.path)
        expect(reloaded.dig('ruby', 'checksums', '3.3.12')).to eq(new_sha)
        expect(reloaded.dig('ruby', 'next')).to eq('3.4.9')
      end
    end

    context 'for a single-version component' do
      it 'replaces version and sha256' do
        versions.update('libffi', '3.4.2', sha256: new_sha)

        reloaded = YAML.load_file(file.path)
        expect(reloaded.dig('libffi', 'version')).to eq('3.4.2')
        expect(reloaded.dig('libffi', 'sha256')).to eq(new_sha)
      end
    end

    it 'fetches the sha256 when not supplied' do
      allow(versions).to receive(:fetch_sha256).with('ruby', '3.4.10').and_return(new_sha)

      expect(versions.update('ruby', '3.4.10')).to eq(new_sha)
      expect(YAML.load_file(file.path).dig('ruby', 'checksums', '3.4.10')).to eq(new_sha)
    end

    it 'rejects a checksum that is not a valid sha256' do
      expect { versions.update('ruby', '3.4.10', sha256: 'not-a-sha') }
        .to raise_error(ArgumentError, /Invalid sha256 for ruby 3.4.10/)
    end

    it 'raises for an unknown component' do
      expect { versions.update('nope', '1.0', sha256: new_sha) }
        .to raise_error(KeyError, /Unknown component 'nope'/)
    end

    it 'preserves the header comment block' do
      versions.update('libffi', '3.4.2', sha256: new_sha)

      expect(File.read(file.path)).to start_with("# Header comment that must be preserved.\n---\n")
    end

    it 'reads versions as strings, never coercing them to floats' do
      # A version like "1.20" would become the float 1.2 under default YAML
      # parsing; the string-forcing loader must preserve it verbatim.
      versions.update('libffi', '1.20', sha256: new_sha)

      reloaded = Gitlab::Version.load_versions_file(file.path)
      expect(reloaded.dig('libffi', 'version')).to eq('1.20')
      expect(reloaded.dig('libffi', 'version')).to be_a(String)
    end

    it 'emits a stable format so re-saving is a no-op (no formatting churn)' do
      versions.update('ruby', '3.4.10', sha256: new_sha)
      once = File.read(file.path)

      # Re-loading and saving without any change must be byte-identical, so an
      # update only ever diffs the lines it actually touches.
      described_class.new(file.path).send(:save)
      expect(File.read(file.path)).to eq(once)
    end
  end

  describe '#malformed_checksums' do
    it 'is empty when every stored checksum is a valid sha256' do
      expect(versions.malformed_checksums).to be_empty
    end

    it 'reports source, map, and ubt checksums that are not valid sha256' do
      File.write(file.path, <<~YAML)
        ---
        ruby:
          current: "3.3.11"
          next: "3.4.9"
          checksums:
            "3.3.11": "#{sha_3311}"
            "3.4.9": "tooshort"
        libffi:
          version: "3.2.1"
          sha256: "#{sha_libffi}"
          ubt:
            revision: "3ubt"
            sha256: "nothex"
      YAML

      expect(described_class.new(file.path).malformed_checksums).to contain_exactly(
        "ruby 3.4.9: 'tooshort' is not a valid sha256",
        "libffi ubt: 'nothex' is not a valid sha256"
      )
    end
  end

  describe '#fetch_ruby_sha256' do
    let(:releases) do
      [
        { 'version' => '3.4.9', 'sha256' => { 'gz' => 'gz-sha', 'xz' => 'xz-sha' } }
      ]
    end

    it 'returns the .tar.gz checksum for the version' do
      expect(versions.fetch_ruby_sha256('3.4.9', releases: releases)).to eq('gz-sha')
    end

    it 'raises when the version is not published upstream' do
      expect { versions.fetch_ruby_sha256('9.9.9', releases: releases) }
        .to raise_error(/Ruby 9.9.9 not found/)
    end
  end

  describe 'HTTP fetching' do
    # Build a real Net::HTTPResponse subclass instance (so `case`/`when` class
    # matching works) without going through its network-oriented constructor.
    def response(klass, body: nil, location: nil, code: nil, message: nil)
      klass.allocate.tap do |resp|
        allow(resp).to receive_messages(body: body, code: code, message: message)
        allow(resp).to receive(:[]).with('location').and_return(location)
      end
    end

    it 'follows redirects' do
      redirect = response(Net::HTTPRedirection, location: 'https://example.com/moved')
      success = response(Net::HTTPSuccess, body: 'payload')
      allow(Net::HTTP).to receive(:get_response).and_return(redirect, success)

      expect(versions.send(:http_get, 'https://example.com/start')).to eq('payload')
    end

    it 'raises after too many redirects' do
      redirect = response(Net::HTTPRedirection, location: 'https://example.com/loop')
      allow(Net::HTTP).to receive(:get_response).and_return(redirect)

      expect { versions.send(:http_get, 'https://example.com/start') }
        .to raise_error(/Too many HTTP redirects/)
    end

    it 'raises on a non-success, non-redirect response' do
      failure = response(Net::HTTPNotFound, code: '404', message: 'Not Found')
      allow(Net::HTTP).to receive(:get_response).and_return(failure)

      expect { versions.send(:http_get, 'https://example.com/missing') }
        .to raise_error(%r{GET https://example.com/missing failed: 404 Not Found})
    end
  end

  describe '#verify' do
    before do
      # libffi has no fetcher, so verify skips it.
      allow(versions).to receive(:fetch_sha256).with('libffi', '3.2.1').and_raise(NotImplementedError)
    end

    it 'returns an empty array when checksums match upstream' do
      allow(versions).to receive(:fetch_sha256).with('ruby', '3.3.11').and_return(sha_3311)
      allow(versions).to receive(:fetch_sha256).with('ruby', '3.4.9').and_return(sha_349)

      expect(versions.verify).to be_empty
    end

    it 'reports mismatches' do
      changed = 'f' * 64
      allow(versions).to receive(:fetch_sha256).with('ruby', '3.3.11').and_return(sha_3311)
      allow(versions).to receive(:fetch_sha256).with('ruby', '3.4.9').and_return(changed)

      expect(versions.verify).to contain_exactly("ruby 3.4.9: pinned #{sha_349}, upstream #{changed}")
    end

    it 'skips components without a fetcher' do
      allow(versions).to receive(:fetch_sha256).with('ruby', '3.3.11').and_return(sha_3311)
      allow(versions).to receive(:fetch_sha256).with('ruby', '3.4.9').and_return(sha_349)

      expect(versions.verify).to be_empty
    end
  end
end
