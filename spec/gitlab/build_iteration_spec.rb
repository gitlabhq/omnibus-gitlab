require_relative '../../lib/gitlab/build_iteration.rb'

describe Gitlab::BuildIteration do
  describe :build_iteration do
    subject { Gitlab::BuildIteration.new(git_describe) }

    context 'with an invalid git_describe' do
      let(:git_describe) { '1.2.3-foo.3' }

      it 'returns 0' do
        expect(subject.build_iteration).to eq(0)
      end
    end

    context 'with a proper git_describe' do
      let(:git_describe) { '1.2.3+foo.4' }

      it 'returns 4' do
        expect(subject.build_iteration).to eq(4)
      end
    end

  end
end
