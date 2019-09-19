require 'spec_helper'
require 'gitlab/version'

describe Gitlab::Version do
  describe :remote do
    subject { Gitlab::Version.new(software) }

    context 'with a valid software name' do
      let(:software) { 'gitlab-rails-ee' }

      it 'returns a link from custom_sources yml' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("ALTERNATIVE_SOURCES").and_return("false")
        expect(subject.remote).to eq('git@dev.gitlab.org:gitlab/gitlab-ee.git')
      end
    end

    context 'with an invalid software name' do
      let(:software) { 'not a valid software' }

      it 'outputs an empty string' do
        expect(subject.remote).to eq('')
      end
    end

    context 'without ALTERNATIVE_SOURCES env variable explicitly set' do
      let(:software) { 'gitlab-rails-ee' }

      it 'returns "remote" link from custom_sources yml' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("ALTERNATIVE_SOURCES").and_return("false")
        expect(subject.remote).to eq('git@dev.gitlab.org:gitlab/gitlab-ee.git')
      end
    end

    context 'with ALTERNATIVE_SOURCES env variable explicitly set' do
      let(:software) { 'gitlab-rails-ee' }

      it 'returns "alternative" link from custom_sources yml' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("ALTERNATIVE_SOURCES").and_return("true")
        expect(subject.remote).to eq('https://gitlab.com/gitlab-org/gitlab.git')
      end
    end
  end

  describe :print do
    subject { Gitlab::Version.new(software, version) }

    context 'with a valid software name and version' do
      let(:software) { 'gitlab-rails' }
      let(:version) { '12.34.567' }

      it 'returns correct version with v appended' do
        expect(subject.print).to eq('v12.34.567')
      end
    end

    context 'with a valid software name and version' do
      let(:software) { 'gitlab-rails-ee' }
      let(:version) { '12.34.567-ee' }

      it 'returns correct version with v appended' do
        expect(subject.print).to eq('v12.34.567-ee')
      end
    end

    context 'with a valid software name and no version' do
      let(:software) { 'ruby' }
      let(:version) { nil }

      it 'outputs an empty string' do
        expect(subject.print).to eq(nil)
      end
    end

    context 'with a valid software name and a version' do
      let(:software) { 'ruby' }
      let(:version) { '2.3.1' }

      it 'adds a v prefix' do
        expect(subject.print).to eq("v2.3.1")
      end

      it 'does not add a v prefix if explicitly set' do
        expect(subject.print(false)).to eq("2.3.1")
      end
    end

    context 'with a valid software name and a branch name' do
      let(:software) { 'gitlab-rails' }
      let(:version) { '9-0-stable' }

      it 'does not add a v prefix' do
        expect(subject.print).to eq("9-0-stable")
      end
    end

    context 'with a valid software name and a branch name' do
      let(:software) { 'gitlab-rails' }
      let(:version) { 'master' }

      it 'does not add a v prefix' do
        expect(subject.print).to eq("master")
      end
    end

    context 'with a valid software name and an rc tag ' do
      let(:software) { 'gitlab-rails' }
      let(:version) { '9.1.0-rc1' }

      it 'add a v prefix' do
        expect(subject.print).to eq("v9.1.0-rc1")
      end
    end

    context 'with a valid software name and an rc tag ' do
      let(:software) { 'gitlab-rails' }
      let(:version) { '9.1.0-rc2-ee' }

      it 'add a v prefix' do
        expect(subject.print).to eq("v9.1.0-rc2-ee")
      end
    end

    context 'with a valid software name and a branch name' do
      let(:software) { 'gitlab-rails' }
      let(:version) { '9.1.0-fix' }

      it 'does not add a v prefix' do
        expect(subject.print).to eq("9.1.0-fix")
      end
    end

    context 'with a valid software name and a branch name' do
      let(:software) { 'gitlab-rails' }
      let(:version) { 'fix-9.1.0' }

      it 'does not add a v prefix' do
        expect(subject.print).to eq("fix-9.1.0")
      end
    end

    context 'with a valid software name and a commit sha' do
      let(:software) { 'gitlab-rails' }
      let(:version) { '1076385cb57a03fa254be5604f6c6ceb6e39987f' }

      it 'does not add a v prefix' do
        expect(subject.print).to eq("1076385cb57a03fa254be5604f6c6ceb6e39987f")
      end
    end
  end

  describe :version do
    subject { Gitlab::Version.new(software) }

    context 'env variable for setting version' do
      let(:software) { 'gitlab-rails' }

      it 'identifies correct version from env variable' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("GITLAB_VERSION").and_return("5.6.7")
        allow(File).to receive(:read).and_return("1.2.3")
        expect(subject.print).to eq("v5.6.7")
      end

      it 'falls back to VERSION file if env variable not found' do
        allow(File).to receive(:read).and_return("1.2.3")
        expect(subject.print).to eq("v1.2.3")
      end
    end
  end
end
