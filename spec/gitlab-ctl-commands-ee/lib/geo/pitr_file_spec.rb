require 'spec_helper'
require 'geo/pitr_file'

RSpec.describe Geo::PitrFile do
  let(:lsn) { 'imafakelsn' }
  let(:filepath) { '/fake/file/path' }
  subject { described_class.new(filepath, consul_key: 'fake-key') }

  context 'with a local file' do
    before do
      allow(Dir).to receive(:exist?).with('/opt/gitlab/service/consul').and_return(false)
    end

    it "doesn't use consul" do
      expect(subject.use_consul?).to be(false)
    end

    context '#create' do
      it 'creates the pitr file' do
        expect(File).to receive(:write).with(filepath, lsn)
        subject.create(lsn)
      end
    end

    context '#delete' do
      it 'removes the pitr file' do
        allow(File).to receive(:exist?).with(filepath).and_return(true)
        expect(File).to receive(:delete).with(filepath)

        subject.delete
      end

      it 'does not raise an error if the file does not exist' do
        allow(File).to receive(:exist?).with(filepath).and_return(false)
        allow(File).to receive(:delete).with(filepath).and_raise(Errno::ENOENT)

        expect { subject.delete }.to_not raise_error(Geo::PitrFileError, "Unable to delete PITR")
      end
    end

    context '#get' do
      before do
        allow(File).to receive(:read).with(filepath).and_return(lsn)
      end

      it 'returns the correct lsn' do
        expect(subject.get).to eq(lsn)
      end

      it 'raises an error if the file does not exist' do
        allow(File).to receive(:read).with(filepath).and_raise(Errno::ENOENT)

        expect { subject.get }.to raise_error(Geo::PitrFileError, "Unable to fetch PITR")
      end
    end
  end

  context 'when consul is enabled' do
    before do
      allow(Dir).to receive(:exist?).with('/opt/gitlab/service/consul').and_return(true)
    end

    it "uses consul" do
      expect(subject.use_consul?).to be(true)
    end

    context '#create' do
      it 'create the write key entry' do
        expect(ConsulHandler::Kv).to receive(:put).with(subject.consul_key, lsn)

        subject.create(lsn)
      end
    end

    context '#delete' do
      it 'removes the consul key' do
        expect(ConsulHandler::Kv).to receive(:delete).with(subject.consul_key)

        subject.delete
      end

      it 'raises an error if the key does not exist' do
        expect { subject.delete }.to raise_error(Geo::PitrFileError, 'Unable to delete PITR')
      end
    end

    context '#get' do
      context 'existing key' do
        before do
          allow(ConsulHandler::Kv).to receive(:get).with(subject.consul_key).and_return(lsn)
        end

        it 'returns the correct lsn' do
          expect(subject.get).to eq(lsn)
        end
      end

      context 'non-existing key' do
        it 'raises an error if the key does not exist' do
          expect { subject.get }.to raise_error(Geo::PitrFileError, 'Unable to fetch PITR')
        end
      end
    end
  end
end
