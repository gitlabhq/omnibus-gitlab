# This spec is to test the Redis helper and whether the values parsed
# are the ones we expect

require 'spec_helper'
require_relative '../../files/gitlab-cookbooks/gitlab/libraries/redis_uri.rb'

RSpec.describe URI::Redis do
  subject { URI('redis://localhost') }

  it { is_expected.to be_a(described_class) }

  context '.parse' do
    it 'delegates to URI.parse' do
      expect(URI).to receive(:parse).with('redis://localhost')

      described_class.parse('redis://localhost')
    end
  end

  context 'port' do
    it 'has a default port' do
      expect(subject.default_port).to eq 6379
    end

    it 'outputs default port when none is defined' do
      expect(subject.port).to eq subject.default_port
    end

    it 'does not include port when it is default port' do
      expect(subject.to_s).to eq 'redis://localhost'
    end

    it 'includes port when it is different than default' do
      subject.port = 6378
      expect(subject.to_s).to eq 'redis://localhost:6378'
    end
  end

  context 'with password' do
    before { subject.password = 'password' }

    it 'allows password to be defined' do
      expect(subject.password).to eq 'password'
    end

    it 'renders url with password' do
      expect(subject.to_s).to eq 'redis://:password@localhost'
    end
  end

  context 'with non-alphanumeric password' do
    let(:password) { "&onBsidv6#XeKFd}=BDDyRrv" }
    let(:escaped) { CGI.escape(password) }

    it 'rejects unencoded passwords' do
      expect { subject.password = password }.to raise_error(URI::InvalidComponentError)
    end

    it 'allows encoded passwords' do
      subject.password = escaped

      expect(subject.password).to eq(escaped)
    end

    it 'renders url with escaped password' do
      subject.password = escaped

      expect(subject.to_s).to eq "redis://:#{escaped}@localhost"
    end
  end

  context 'without password' do
    it 'renders url without authentication division characters' do
      expect(subject.to_s).to eq 'redis://localhost'
    end
  end
end
