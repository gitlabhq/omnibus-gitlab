require 'chef_helper'

RSpec.describe SmtpHelper do
  describe '.parse_smtp_authentication!' do
    def normalize(value)
      config = { 'smtp_authentication' => value }
      described_class.parse_smtp_authentication!(config)
      config['smtp_authentication']
    end

    context 'when set to a valid authentication mechanism' do
      it 'leaves a string mechanism untouched' do
        expect(normalize('login')).to eq('login')
        expect(normalize('plain')).to eq('plain')
        expect(normalize('cram_md5')).to eq('cram_md5')
      end

      it 'leaves a symbol mechanism untouched' do
        expect(normalize(:plain)).to eq(:plain)
      end
    end

    it 'leaves nil untouched' do
      expect(normalize(nil)).to be_nil
    end

    # net-smtp 0.5.x raises ArgumentError on any truthy authtype that is not a
    # known SASL mechanism, so falsey/"disable" values must become nil.
    [false, 'false', 'FALSE', 'none', 'None', ''].each do |value|
      it "normalizes #{value.inspect} to nil" do
        expect(normalize(value)).to be_nil
      end
    end

    context 'when set to an unrecognized authentication mechanism' do
      it 'raises a descriptive error' do
        expect { normalize('plian') }.to raise_error(
          RuntimeError,
          /unrecognized value.*plian.*Valid mechanisms are: login, plain, cram_md5/m
        )
      end

      it 'raises for other unrecognized strings' do
        expect { normalize('xoauth2') }.to raise_error(RuntimeError, /unrecognized value/)
        expect { normalize('bogus') }.to raise_error(RuntimeError, /unrecognized value/)
      end
    end
  end
end
