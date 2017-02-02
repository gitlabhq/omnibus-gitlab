require_relative '../../lib/gitlab/package_repository.rb'
require 'chef_helper'

describe PackageRepository do
  let(:repo) { PackageRepository.new }

  describe :repository_for_rc do
    context 'on master' do
      # Example:
      # on non stable branch: 8.1.0+rc1.ce.0-1685-gd2a2c51
      # on tag: 8.12.0+rc1.ee.0
      before do
        allow(repo).to receive(:system).with('git describe | grep -q -e rc').and_return(true)
      end

      it { expect(repo.repository_for_rc).to eq 'unstable' }
    end

    context 'on stable branch' do
      # Example:
      # on non stable branch: 8.12.8+ce.0-1-gdac92d4
      # on tag: 8.12.8+ce.0
      before do
        allow(repo).to receive(:system).with('git describe | grep -q -e rc').and_return(false)
      end

      it { expect(repo.repository_for_rc).to eq nil }
    end
  end

  describe :repository_for_edition do
    context 'when EE' do
      before do
        allow(repo).to receive(:system).with('grep -q -E "\-ee" VERSION').and_return(true)
      end

      it { expect(repo.repository_for_edition).to eq 'gitlab-ee' }
    end

    context 'when CE' do
      before do
        allow(repo).to receive(:system).with('grep -q -E "\-ee" VERSION').and_return(false)
      end

      it { expect(repo.repository_for_edition).to eq 'gitlab-ce' }
    end
  end

  describe :target do

    shared_examples 'with an override repository' do
      context 'with repository override' do
        before do
          set_all_env_variables
        end

        it 'uses the override repository' do
           expect(repo.target).to eq('super-stable-1234')
        end
      end
    end

    shared_examples 'with a nightly repository' do
      context 'with nightly repo' do
        before do
          set_nightly_env_variable
        end

        it 'uses the nightly repository' do
           expect(repo.target).to eq('nightly-builds')
        end
      end
    end

    shared_examples 'with raspberry pi repo' do
      context 'with raspberry pi repo' do
        before do
          set_raspi_env_variable
        end

        it 'uses the raspberry pi repository' do
           expect(repo.target).to eq('raspi')
        end
      end
    end

    context 'on non-stable branch' do
      before do
        allow(repo).to receive(:system).with('git describe | grep -q -e rc').and_return(true)
      end

      it 'prints unstable' do
        expect(repo.target).to eq('unstable')
      end

      it_behaves_like 'with an override repository'
      it_behaves_like 'with a nightly repository'
      it_behaves_like 'with raspberry pi repo'
    end

    context 'on a stable branch' do
      before do
        allow(repo).to receive(:system).with('git describe | grep -q -e rc').and_return(false)
      end

      context 'when EE' do
        before do
          allow(repo).to receive(:system).with('grep -q -E "\-ee" VERSION').and_return(true)
        end

        it 'prints gitlab-ee' do
          expect(repo.target).to eq('gitlab-ee')
        end

        it_behaves_like 'with an override repository'
        it_behaves_like 'with a nightly repository'
        it_behaves_like 'with raspberry pi repo'
      end

      context 'when CE' do
        before do
          allow(repo).to receive(:system).with('grep -q -E "\-ee" VERSION').and_return(false)
        end

        it 'prints gitlab-ce' do
          expect(repo.target).to eq('gitlab-ce')
        end

        it_behaves_like 'with an override repository'
        it_behaves_like 'with a nightly repository'
        it_behaves_like 'with raspberry pi repo'
      end
    end
  end

  def set_all_env_variables
    stub_env_var("PACKAGECLOUD_REPO", "super-stable-1234")
    stub_env_var("NIGHTLY_REPO", "nightly-builds")
    stub_env_var("RASPBERRY_REPO", "raspi")
  end

  def set_nightly_env_variable
    stub_env_var("PACKAGECLOUD_REPO", "")
    stub_env_var("NIGHTLY_REPO", "nightly-builds")
    stub_env_var("RASPBERRY_REPO", "")
  end

  def set_raspi_env_variable
    stub_env_var("PACKAGECLOUD_REPO", "")
    stub_env_var("NIGHTLY_REPO", "nightly-builds")
    stub_env_var("RASPBERRY_REPO", "raspi")
  end
end
