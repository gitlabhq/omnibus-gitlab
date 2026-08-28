require 'spec_helper'
require 'gitlab/build/glaz_ffi'

RSpec.describe Build::GlazFFI do
  let(:sha_x86_64) { 'a' * 64 }
  let(:sha_aarch64) { 'b' * 64 }
  let(:version) do
    instance_double(
      Gitlab::Version,
      upstream_version: '1.8.1',
      source_sha256: { 'x86_64' => sha_x86_64, 'aarch64' => sha_aarch64 }
    )
  end

  before do
    allow(Gitlab::Version).to receive(:new).with('glaz-ffi').and_return(version)
    allow(OhaiHelper).to receive(:arch).and_return('aarch64')
  end

  describe '.bundle_dir_name' do
    it 'is the archive top-level directory for the build architecture' do
      expect(described_class.bundle_dir_name).to eq('glaz-ffi-1.8.1-aarch64-unknown-linux-gnu')
    end
  end

  describe '.source_args' do
    it 'points at the per-architecture tarball with its pinned sha256' do
      args = described_class.source_args

      expect(args[:url]).to end_with(
        '/packages/generic/glaz-ffi/1.8.1/glaz-ffi-1.8.1-aarch64-unknown-linux-gnu.tar.gz'
      )
      expect(args[:sha256]).to eq(sha_aarch64)
    end

    it 'fails clearly for an architecture without a published bundle' do
      allow(OhaiHelper).to receive(:arch).and_return('armv7l')

      expect { described_class.source_args }
        .to raise_error(/publishes no armv7l-unknown-linux-gnu bundle/)
    end
  end

  describe '.dir' do
    it 'is the staging directory below the install dir' do
      expect(described_class.dir('/opt/gitlab')).to eq('/opt/gitlab/embedded/glaz-ffi')
    end
  end
end
