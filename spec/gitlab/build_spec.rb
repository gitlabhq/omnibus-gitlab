require 'spec_helper'
require 'gitlab/build'

RSpec.describe Build do
  describe 'cmd' do
    describe 'by default' do
      it 'runs build command with log level info' do
        expect(described_class.cmd('gitlab')).to eq %w[bundle exec omnibus build gitlab --log-level info]
      end
    end

    describe 'with different log level' do
      it 'runs build command with custom log level' do
        stub_env_var('BUILD_LOG_LEVEL', 'debug')
        expect(described_class.cmd('gitlab')).to eq %w[bundle exec omnibus build gitlab --log-level debug]
      end
    end
  end
end
