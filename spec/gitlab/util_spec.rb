require 'spec_helper'
require 'gitlab/util'

RSpec.describe Gitlab::Util do
  describe :get_env do
    it 'strips value of env variable correctly' do
      allow(ENV).to receive(:[]).with('foo').and_return('  bar  ')

      expect(Gitlab::Util.get_env('foo')).to eq('bar')
    end

    it 'does not fail if env variable is nil' do
      allow(ENV).to receive(:[]).with('foo').and_return(nil)

      expect { Gitlab::Util.get_env('foo') }.not_to raise_error
      expect(Gitlab::Util.get_env('foo')).to eq(nil)
    end
  end

  describe :set_env do
    it 'strips value before setting env variable' do
      Gitlab::Util.set_env('foo', '  blahblah ')
      expect(ENV['foo']).to eq('blahblah')
    end

    it 'does not fail if value is nil' do
      expect { Gitlab::Util.set_env('foo', nil) }.not_to raise_error
      expect(ENV['foo']).to eq(nil)
    end
  end

  describe :set_env_if_missing do
    it 'does not override existing value' do
      allow(ENV).to receive(:[]).with('foo').and_return('lorem')

      Gitlab::Util.set_env_if_missing('foo', 'ipsum')
      expect(ENV['foo']).to eq('lorem')
    end

    it 'sets value if env variable is mising' do
      Gitlab::Util.set_env_if_missing('foo', 'ipsum')
      expect(ENV['foo']).to eq('ipsum')
    end

    it 'does not fail if value is nil' do
      expect { Gitlab::Util.set_env_if_missing('bar', nil) }.not_to raise_error
      expect(ENV['bar']).to eq(nil)
    end
  end
end
