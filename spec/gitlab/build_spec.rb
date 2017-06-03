require_relative '../../lib/gitlab/build.rb'
require 'chef_helper'

describe Build do
  describe 'cmd' do
    describe 'by default' do
      it 'runs build command with log level info' do
        expect(described_class.cmd('gitlab')).to eq 'bundle exec omnibus build gitlab --log-level info'
      end
    end

    describe 'with different log level' do
      it 'runs build command with custom log level' do
        stub_env_var('BUILD_LOG_LEVEL', 'debug')
        expect(described_class.cmd('gitlab')).to eq 'bundle exec omnibus build gitlab --log-level debug'
      end
    end
  end

  describe 'is_ee?' do
    describe 'with environment variables' do
      it 'when ee=true' do
        stub_env_var('ee', 'true')
        expect(described_class.is_ee?).to be_truthy
      end

      it 'when ee=false' do
        stub_env_var('ee', 'false')
        expect(described_class.is_ee?).to be_falsy
      end

      it 'when env variable is not set' do
        expect(described_class.is_ee?).to be_falsy
      end
    end

    describe 'without environment variables' do
      it 'checks the VERSION file' do
        allow(described_class).to receive(:system).with('grep -q -E "\-ee" VERSION').and_return(true)
        expect(described_class.is_ee?).to be_truthy
      end
    end
  end

  describe 'package' do
    describe 'shows EE' do
      it 'when ee=true' do
        stub_env_var('ee', 'true')
        expect(described_class.package).to eq('gitlab-ee')
      end

      it 'when env var is not present, checks VERSION file' do
        allow(described_class).to receive(:system).with('grep -q -E "\-ee" VERSION').and_return(true)
        expect(described_class.package).to eq('gitlab-ee')
      end
    end

    describe 'shows CE' do
      it 'by default' do
        expect(described_class.package).to eq('gitlab-ce')
      end
    end
  end
end
