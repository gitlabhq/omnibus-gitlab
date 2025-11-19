require 'spec_helper'
require 'gitlab/package_repository/package_cloud_repository'

RSpec.describe PackageRepository::PackageCloudRepository do
  let(:repo) { described_class.new }

  before do
    allow(ENV).to receive(:[]).and_call_original
  end

  describe '#target' do
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
        unset_all_env_variables
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
        unset_all_env_variables
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

  describe '#user' do
    context 'when PACKAGECLOUD_USER is set' do
      before do
        stub_env_var('PACKAGECLOUD_USER', 'gitlab')
      end

      it 'returns the packagecloud user' do
        expect(repo.user).to eq('gitlab')
      end
    end

    context 'when PACKAGECLOUD_USER is not set' do
      before do
        stub_env_var('PACKAGECLOUD_USER', nil)
      end

      it 'returns nil' do
        expect(repo.user).to be_nil
      end
    end

    context 'when PACKAGECLOUD_USER is empty string' do
      before do
        stub_env_var('PACKAGECLOUD_USER', '')
      end

      it 'returns nil' do
        expect(repo.user).to be_nil
      end
    end
  end

  describe '#upload' do
    describe 'with staging repository' do
      context 'when upload user is not specified' do
        before do
          unset_all_env_variables
        end

        it 'prints a message and aborts' do
          expect { repo.upload('my-staging-repository', true) }.to output(%r{Owner of the repository to which packages are being uploaded not specified}).to_stdout
        end
      end

      context 'with specified upload user' do
        before do
          stub_env_var('PACKAGECLOUD_USER', "gitlab")
        end

        context 'with artifacts available' do
          before do
            allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/el-9/gitlab-ce.rpm'])
          end

          it 'in dry run mode prints the upload commands' do
            expect { repo.upload('my-staging-repository', true) }.to output(%r{Uploading...\n}).to_stdout
            expect { repo.upload('my-staging-repository', true) }.to output(%r{bin/package_cloud push gitlab/my-staging-repository/ol/9 pkg/el-9/gitlab-ce.rpm --url=https://packages.gitlab.com\n}).to_stdout
            expect { repo.upload('my-staging-repository', true) }.to output(%r{bin/package_cloud push gitlab/my-staging-repository/el/9 pkg/el-9/gitlab-ce.rpm --url=https://packages.gitlab.com\n}).to_stdout
          end

          it 'retries upload if it fails' do
            allow(repo).to receive(:`).and_return('504 Gateway Timeout')
            allow(repo).to receive(:child_process_status).and_return(1)
            allow(repo).to receive(:validate).and_return(nil)

            expect(repo).to receive(:`).exactly(10).times

            expect { repo.upload('my-staging-repository', false) }.to raise_error(PackageRepository::PackageUploadError)
          end

          context 'with OpenSUSE Leap 15.6 artifact' do
            before do
              allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/opensuse-15.6_aarch64/gitlab-ce.rpm'])
            end

            it 'uploads the package to SLES and Leap repositories' do
              expect { repo.upload('my-staging-repository', true) }.to output(%r{Uploading...\n}).to_stdout
              expect { repo.upload('my-staging-repository', true) }.to output(%r{bin/package_cloud push gitlab/my-staging-repository/opensuse/15.6 pkg/opensuse-15.6_aarch64/gitlab-ce.rpm --url=https://packages.gitlab.com\n}).to_stdout
              expect { repo.upload('my-staging-repository', true) }.to output(%r{bin/package_cloud push gitlab/my-staging-repository/sles/15.6 pkg/opensuse-15.6_aarch64/gitlab-ce.rpm --url=https://packages.gitlab.com\n}).to_stdout
            end
          end
        end

        context 'with artifacts unavailable' do
          before do
            allow(Build::Info::Package).to receive(:file_list).and_return([])
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
          allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/ubuntu-focal/gitlab.deb'])
        end

        context 'for stable release' do
          before do
            stub_env_var('PACKAGECLOUD_REPO', nil)
            stub_env_var('RASPBERRY_REPO', nil)
            allow(repo).to receive(:repository_for_rc).and_return(nil)
          end

          context 'of EE' do
            before do
              stub_is_ee(true)
            end

            it 'in dry run mode prints the upload commands' do
              expect { repo.upload(nil, true) }.to output(%r{Uploading...\n}).to_stdout
              expect { repo.upload(nil, true) }.to output(%r{bin/package_cloud push gitlab/gitlab-ee/ubuntu/focal pkg/ubuntu-focal/gitlab.deb --url=https://packages.gitlab.com\n}).to_stdout
            end

            context 'for arm64 packages' do
              before do
                allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/ubuntu-focal_aarch64/gitlab.deb'])
              end

              it 'drops the architecture suffix from repo path' do
                expect { repo.upload(nil, true) }.to output(%r{Uploading...\n}).to_stdout
                expect { repo.upload(nil, true) }.to output(%r{bin/package_cloud push gitlab/gitlab-ee/ubuntu/focal pkg/ubuntu-focal_aarch64/gitlab.deb --url=https://packages.gitlab.com\n}).to_stdout
              end
            end

            context 'for fips packages' do
              before do
                allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/ubuntu-focal_fips/gitlab.deb'])
              end

              it 'drops the fips suffix from repo path' do
                expect { repo.upload(nil, true) }.to output(%r{Uploading...\n}).to_stdout
                expect { repo.upload(nil, true) }.to output(%r{bin/package_cloud push gitlab/gitlab-ee/ubuntu/focal pkg/ubuntu-focal_fips/gitlab.deb --url=https://packages.gitlab.com\n}).to_stdout
              end
            end
          end

          context 'of CE' do
            before do
              stub_is_ee(nil)
            end

            it 'in dry run mode prints the upload commands' do
              expect { repo.upload(nil, true) }.to output(%r{Uploading...\n}).to_stdout
              expect { repo.upload(nil, true) }.to output(%r{bin/package_cloud push gitlab/gitlab-ce/ubuntu/focal pkg/ubuntu-focal/gitlab.deb --url=https://packages.gitlab.com\n}).to_stdout
            end
          end
        end

        context 'for nightly release' do
          before do
            set_nightly_env_variable
            allow(repo).to receive(:repository_for_rc).and_return(nil)
          end

          it 'in dry run mode prints the upload commands' do
            expect { repo.upload(Gitlab::Util.get_env('STAGING_REPO'), true) }.to output(%r{Uploading...\n}).to_stdout
            expect { repo.upload(Gitlab::Util.get_env('STAGING_REPO'), true) }.to output(%r{bin/package_cloud push gitlab/nightly-builds/ubuntu/focal pkg/ubuntu-focal/gitlab.deb --url=https://packages.gitlab.com\n}).to_stdout
          end
        end

        context 'for raspbian release' do
          before do
            set_raspi_env_variable
            allow(repo).to receive(:repository_for_rc).and_return(nil)
          end

          it 'in dry run mode prints the upload commands' do
            expect { repo.upload(nil, true) }.to output(%r{Uploading...\n}).to_stdout
            expect { repo.upload(nil, true) }.to output(%r{bin/package_cloud push gitlab/raspi/ubuntu/focal pkg/ubuntu-focal/gitlab.deb --url=https://packages.gitlab.com\n}).to_stdout
          end
        end
      end
    end

    describe 'when artifacts contain unexpected files' do
      before do
        stub_env_var('PACKAGECLOUD_USER', "gitlab")
        set_all_env_variables
        allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/ubuntu-focal/gitlab.deb', 'pkg/ubuntu-focal/testing/gitlab.deb'])
      end

      it 'raises an exception' do
        expect { repo.upload(nil, true) }.to raise_exception(%r{Found unexpected contents in the directory:})
      end
    end
  end

  def unset_all_env_variables
    stub_env_var('PACKAGECLOUD_TOKEN', nil)
    stub_env_var('PACKAGECLOUD_USER', nil)
    stub_env_var('PACKAGECLOUD_REPO', nil)
    stub_env_var('RASPBERRY_REPO', nil)
    stub_env_var('STAGING_REPO', nil)
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
