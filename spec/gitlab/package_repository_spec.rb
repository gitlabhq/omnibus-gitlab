require 'spec_helper'
require 'gitlab/package_repository'
require 'gitlab/util'

describe PackageRepository do
  let(:repo) { PackageRepository.new }

  before do
    allow(ENV).to receive(:[]).and_call_original
  end

  describe :repository_for_rc do
    context 'on master' do
      # Example:
      # on non stable branch: 8.1.0+rc1.ce.0-1685-gd2a2c51
      # on tag: 8.12.0+rc1.ee.0
      before do
        allow(IO).to receive(:popen).with(%w[git describe]).and_return("8.12.0+rc1.ee.0\n")
      end

      it { expect(repo.repository_for_rc).to eq 'unstable' }
    end

    context 'on stable branch' do
      # Example:
      # on non stable branch: 8.12.8+ce.0-1-gdac92d4
      # on tag: 8.12.8+ce.0
      before do
        allow(IO).to receive(:popen).with(%w[git describe]).and_return("8.12.8+ce.0\n")
      end

      it { expect(repo.repository_for_rc).to eq nil }
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
        allow(IO).to receive(:popen).with(%w[git describe]).and_return("8.1.0+rc1.ce.0-1685-gd2a2c51\n")
      end

      it 'prints unstable' do
        expect(repo.target).to eq('unstable')
      end

      it_behaves_like 'with an override repository'
      it_behaves_like 'with raspberry pi repo'
    end

    context 'on a stable branch' do
      before do
        allow(IO).to receive(:popen).with(%w[git describe]).and_return("8.12.8+ce.0-1-gdac92d4\n")
      end

      context 'when EE' do
        before do
          allow(File).to receive(:read).with('VERSION').and_return("1.2.3-ee\n")
        end

        it 'prints gitlab-ee' do
          expect(repo.target).to eq('gitlab-ee')
        end

        it_behaves_like 'with an override repository'
        it_behaves_like 'with raspberry pi repo'
      end

      context 'when CE' do
        before do
          stub_is_ee(false)
          allow(File).to receive(:read).with('VERSION').and_return("1.2.3\n")
        end

        it 'prints gitlab-ce' do
          expect(repo.target).to eq('gitlab-ce')
        end

        it_behaves_like 'with an override repository'
        it_behaves_like 'with raspberry pi repo'
      end
    end
  end

  describe :validate do
    context 'with artifacts available' do
      before do
        allow(Dir).to receive(:glob).with(PackageRepository::PACKAGE_GLOB).and_return(['pkg/el-6/gitlab-ce.rpm'])
      end

      it 'in dry run mode prints the checksum commands' do
        expect { repo.validate(true) }.to output("sha256sum -c pkg/el-6/gitlab-ce.rpm.sha256\n").to_stdout
      end

      it 'raises an exception when there is a mismatch' do
        expect(repo).to receive(:verify_checksum).with('pkg/el-6/gitlab-ce.rpm.sha256', true).and_return(false)

        expect { repo.validate(true) }.to raise_error(%r{Aborting, package .* has an invalid checksum!})
      end
    end

    context 'with artifacts unavailable' do
      before do
        allow(Dir).to receive(:glob).with(PackageRepository::PACKAGE_GLOB).and_return([])
      end

      it 'prints nothing' do
        expect { repo.validate(true) }.to output('').to_stdout
      end
    end
  end

  describe :upload do
    describe 'with staging repository' do
      context 'when upload user is not specified' do
        it 'prints a message and aborts' do
          expect { repo.upload('my-staging-repository', true) }.to output(%r{User for uploading to package server not specified!\n}).to_stdout
        end
      end

      context 'with specified upload user' do
        before do
          stub_env_var('PACKAGECLOUD_USER', "gitlab")
        end

        context 'with artifacts available' do
          before do
            allow(Dir).to receive(:glob).with(PackageRepository::PACKAGE_GLOB).and_return(['pkg/el-6/gitlab-ce.rpm'])
          end

          it 'in dry run mode prints the upload commands' do
            expect { repo.upload('my-staging-repository', true) }.to output(%r{Uploading...\n}).to_stdout
            expect { repo.upload('my-staging-repository', true) }.to output(%r{bin/package_cloud push gitlab/my-staging-repository/scientific/6 pkg/el-6/gitlab-ce.rpm --url=https://packages.gitlab.com\n}).to_stdout
            expect { repo.upload('my-staging-repository', true) }.to output(%r{bin/package_cloud push gitlab/my-staging-repository/ol/6 pkg/el-6/gitlab-ce.rpm --url=https://packages.gitlab.com\n}).to_stdout
            expect { repo.upload('my-staging-repository', true) }.to output(%r{bin/package_cloud push gitlab/my-staging-repository/el/6 pkg/el-6/gitlab-ce.rpm --url=https://packages.gitlab.com\n}).to_stdout
          end
        end

        context 'with artifacts unavailable' do
          before do
            allow(Dir).to receive(:glob).with("pkg/**/*.{deb,rpm}").and_return([])
          end

          it 'prints a message and aborts' do
            expect { repo.upload('my-staging-repository', true) }.to raise_exception(%r{No packages found for upload. Are artifacts available?})
          end
        end
      end
    end

    describe "with production repository" do
      context 'with artifacts available' do
        before do
          stub_env_var('PACKAGECLOUD_USER', "gitlab")
          allow(Dir).to receive(:glob).with("pkg/**/*.{deb,rpm}").and_return(['pkg/ubuntu-xenial/gitlab.deb'])
        end

        context 'for stable release' do
          before do
            stub_env_var('PACKAGECLOUD_REPO', nil)
            stub_env_var('RASPBERRY_REPO', nil)
            allow_any_instance_of(PackageRepository).to receive(:repository_for_rc).and_return(nil)
          end

          context 'of EE' do
            before do
              stub_is_ee(true)
            end

            it 'in dry run mode prints the upload commands' do
              expect { repo.upload(nil, true) }.to output(%r{Uploading...\n}).to_stdout
              expect { repo.upload(nil, true) }.to output(%r{bin/package_cloud push gitlab/gitlab-ee/ubuntu/xenial pkg/ubuntu-xenial/gitlab.deb --url=https://packages.gitlab.com\n}).to_stdout
            end
          end

          context 'of CE' do
            before do
              stub_is_ee(nil)
            end

            it 'in dry run mode prints the upload commands' do
              expect { repo.upload(nil, true) }.to output(%r{Uploading...\n}).to_stdout
              expect { repo.upload(nil, true) }.to output(%r{bin/package_cloud push gitlab/gitlab-ce/ubuntu/xenial pkg/ubuntu-xenial/gitlab.deb --url=https://packages.gitlab.com\n}).to_stdout
            end
          end
        end

        context 'for nightly release' do
          before do
            set_nightly_env_variable
            allow_any_instance_of(PackageRepository).to receive(:repository_for_rc).and_return(nil)
          end

          it 'in dry run mode prints the upload commands' do
            expect { repo.upload(Gitlab::Util.get_env('STAGING_REPO'), true) }.to output(%r{Uploading...\n}).to_stdout
            expect { repo.upload(Gitlab::Util.get_env('STAGING_REPO'), true) }.to output(%r{bin/package_cloud push gitlab/nightly-builds/ubuntu/xenial pkg/ubuntu-xenial/gitlab.deb --url=https://packages.gitlab.com\n}).to_stdout
          end
        end

        context 'for raspbian release' do
          before do
            set_raspi_env_variable
            allow_any_instance_of(PackageRepository).to receive(:repository_for_rc).and_return(nil)
          end

          it 'in dry run mode prints the upload commands' do
            expect { repo.upload(nil, true) }.to output(%r{Uploading...\n}).to_stdout
            expect { repo.upload(nil, true) }.to output(%r{bin/package_cloud push gitlab/raspi/ubuntu/xenial pkg/ubuntu-xenial/gitlab.deb --url=https://packages.gitlab.com\n}).to_stdout
          end
        end
      end
    end

    describe 'when artifacts contain unexpected files' do
      before do
        stub_env_var('PACKAGECLOUD_USER', "gitlab")
        set_all_env_variables
        allow(Dir).to receive(:glob).with("pkg/**/*.{deb,rpm}").and_return(['pkg/ubuntu-xenial/gitlab.deb', 'pkg/ubuntu-xenial/testing/gitlab.deb'])
      end

      it 'raises an exception' do
        expect { repo.upload(nil, true) }.to raise_exception(%r{Found unexpected contents in the directory:})
      end
    end
  end

  def set_all_env_variables
    stub_env_var("PACKAGECLOUD_REPO", "super-stable-1234")
    stub_env_var("RASPBERRY_REPO", "raspi")
  end

  def set_nightly_env_variable
    stub_env_var("PACKAGECLOUD_REPO", "")
    stub_env_var("RASPBERRY_REPO", "")
    stub_env_var("STAGING_REPO", "nightly-builds")
  end

  def set_raspi_env_variable
    stub_env_var("PACKAGECLOUD_REPO", "")
    stub_env_var("RASPBERRY_REPO", "raspi")
  end
end
