require 'spec_helper'
require 'gitlab/build_iteration'

RSpec.describe Gitlab::BuildIteration do
  describe :build_iteration do
    subject { Gitlab::BuildIteration.new }

    context 'when not on a tag' do
      before do
        allow(Build::Check).to receive(:on_tag?).and_return(false)
      end

      it 'returns 0' do
        expect(subject.build_iteration).to eq('0')
      end
    end

    context 'when on a tag' do
      before do
        allow(Build::Check).to receive(:on_tag?).and_return(true)
      end

      context 'that has an invalid format' do
        before do
          allow(Build::Info::Git).to receive(:tag_name).and_return('1.2.3-foo.3')
        end

        it 'returns 0' do
          expect(subject.build_iteration).to eq('0')
        end
      end

      context 'that is a proper CE tag' do
        before do
          allow(Build::Info::Git).to receive(:tag_name).and_return('18.3.0+ce.0')
        end

        it 'returns ce.0' do
          expect(subject.build_iteration).to eq('ce.0')
        end
      end

      context 'that is a proper EE tag' do
        before do
          allow(Build::Info::Git).to receive(:tag_name).and_return('18.3.0+ee.0')
        end

        it 'returns ee.0' do
          expect(subject.build_iteration).to eq('ee.0')
        end
      end

      context 'that is a proper CE RC tag' do
        before do
          allow(Build::Info::Git).to receive(:tag_name).and_return('18.3.0+rc42.ce.0')
        end

        it 'returns rc42.ce.0' do
          expect(subject.build_iteration).to eq('rc42.ce.0')
        end
      end

      context 'that is a proper CE RC tag' do
        before do
          allow(Build::Info::Git).to receive(:tag_name).and_return('18.3.0+rc42.ee.0')
        end

        it 'returns rc42.ee.0' do
          expect(subject.build_iteration).to eq('rc42.ee.0')
        end
      end
    end
  end
end
