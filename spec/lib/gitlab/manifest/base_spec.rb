require 'spec_helper'
require 'gitlab/manifest/base'

RSpec.describe Manifest::Base do
  subject(:base) { described_class.allocate }

  before { base.instance_variable_set(:@manifests_bucket_region, 'eu-west-1') }

  describe '#s3_sync' do
    it 'raises when the aws executable cannot be spawned (system returns nil)' do
      allow(base).to receive(:system).and_return(nil)

      expect { base.s3_sync('src', 'dst') }.to raise_error(/aws CLI not found/)
    end

    it 'returns true on a successful sync' do
      allow(base).to receive(:system).and_return(true)

      expect(base.s3_sync('src', 'dst')).to be(true)
    end

    it 'returns false on a failed sync (non-zero exit)' do
      allow(base).to receive(:system).and_return(false)

      expect(base.s3_sync('src', 'dst')).to be(false)
    end
  end
end
