require_relative '../../lib/gitlab/build.rb'

describe Build do
  describe 'by default' do
    it 'runs build command with log level info' do
      expect(described_class.cmd('gitlab')).to eq 'bundle exec omnibus build gitlab --log-level info'
    end
  end

  describe 'with different log level' do
    it 'runs build command with custom log level' do
      allow(ENV).to receive(:[]).with('BUILD_LOG_LEVEL').and_return('debug')
      expect(described_class.cmd('gitlab')).to eq 'bundle exec omnibus build gitlab --log-level debug'
    end
  end
end
