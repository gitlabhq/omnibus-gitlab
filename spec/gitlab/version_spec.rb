require_relative '../../lib/gitlab/version.rb'
require 'chef_helper'

describe Gitlab::Version do
  describe :remote do
    subject { Gitlab::Version.new(software) }

    context 'with a valid software name' do
      let(:software) { 'gitlab-rails-ee' }

      it 'returns a link from custom_sources yml' do
        expect(subject.remote).to eq('git@dev.gitlab.org:gitlab/gitlab-ee.git')
      end
    end

    context 'with an invalid software name' do
      let(:software) { 'not a valid software' }

      it 'outputs an empty string' do
        expect(subject.remote).to eq('')
      end
    end
  end

  describe :print do
    subject { Gitlab::Version.new(software, version) }

    context 'with a valid software name and version' do
      let(:software) { 'ruby' }
      let(:version) { '2.3.1' }

      it 'returns a link from custom_sources yml' do
        expect(subject.print).to eq('v2.3.1')
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

    context 'with a valid software name and a branch' do
      let(:software) { 'ruby' }
      let(:version) { 'my-feature-branch' }

      it 'identifies the branch name correctly' do
        expect(subject.print).to eq("my-feature-branch")
      end
    end

    context 'with a valid software name and a sha' do
      let(:software) { 'ruby' }
      let(:version) { '0e413954de03e6a79219103ed897c1ff7bed7653' }

      it 'identifies the SHA and doesn\'t append v' do
        expect(subject.print).to eq("0e413954de03e6a79219103ed897c1ff7bed7653")
      end
    end
  end
end
