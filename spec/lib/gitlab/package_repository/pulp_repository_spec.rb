require 'spec_helper'
require 'gitlab/package_repository/pulp_repository'

RSpec.describe PackageRepository::PulpRepository do
  let(:repo) { described_class.new }

  before do
    allow(ENV).to receive(:[]).and_call_original
    # Prevent any real pulp command execution by default
    # Individual tests will override this with more specific mocks
    allow(Gitlab::Util).to receive(:shellout_stdout).and_return('')
  end

  describe '#target' do
    shared_examples 'with an override repository' do
      context 'with repository override' do
        before do
          set_all_env_variables
        end

        it 'uses the override repository' do
          expect(repo.target).to eq('pulp-stable-5678')
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

  describe '#upload' do
    describe 'authentication validation' do
      before do
        allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/ubuntu-focal/gitlab-ce.deb'])
        allow(repo).to receive(:validate).and_return(nil)
      end

      context 'when PULP_USER is not set' do
        before do
          stub_env_var('PULP_USER', nil)
          stub_env_var('PULP_PASSWORD', 'password123')
        end

        it 'raises an error' do
          expect { repo.upload('my-staging-repository', false) }.to raise_error(
            PackageRepository::PackageUploadError,
            'PULP_USER environment variable is required'
          )
        end
      end

      context 'when PULP_USER is empty' do
        before do
          stub_env_var('PULP_USER', '')
          stub_env_var('PULP_PASSWORD', 'password123')
        end

        it 'raises an error' do
          expect { repo.upload('my-staging-repository', false) }.to raise_error(
            PackageRepository::PackageUploadError,
            'PULP_USER environment variable is required'
          )
        end
      end

      context 'when PULP_PASSWORD is not set' do
        before do
          stub_env_var('PULP_USER', 'gitlab')
          stub_env_var('PULP_PASSWORD', nil)
        end

        it 'raises an error' do
          expect { repo.upload('my-staging-repository', false) }.to raise_error(
            PackageRepository::PackageUploadError,
            'PULP_PASSWORD environment variable is required'
          )
        end
      end

      context 'when PULP_PASSWORD is empty' do
        before do
          stub_env_var('PULP_USER', 'gitlab')
          stub_env_var('PULP_PASSWORD', '')
        end

        it 'raises an error' do
          expect { repo.upload('my-staging-repository', false) }.to raise_error(
            PackageRepository::PackageUploadError,
            'PULP_PASSWORD environment variable is required'
          )
        end
      end

      context 'when both PULP_USER and PULP_PASSWORD are set' do
        before do
          stub_env_var('PULP_USER', 'gitlab')
          stub_env_var('PULP_PASSWORD', 'password123')
          allow(Gitlab::Util).to receive(:shellout_stdout).and_return('')
        end

        it 'does not raise an error' do
          expect { repo.upload('my-staging-repository', false) }.not_to raise_error
        end
      end

      context 'in dry run mode' do
        it 'does not validate credentials when PULP_USER is not set' do
          stub_env_var('PULP_USER', nil)
          stub_env_var('PULP_PASSWORD', 'password123')

          expect { repo.upload('my-staging-repository', true) }.not_to raise_error
        end

        it 'does not validate credentials when PULP_PASSWORD is not set' do
          stub_env_var('PULP_USER', 'gitlab')
          stub_env_var('PULP_PASSWORD', nil)

          expect { repo.upload('my-staging-repository', true) }.not_to raise_error
        end
      end
    end

    describe 'with staging repository' do
      before do
        stub_env_var('PULP_USER', "gitlab")
      end

      context 'with deb artifacts available' do
        before do
          allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/ubuntu-focal/gitlab-ce.deb'])
        end

        it 'in dry run mode does not print the upload command' do
          expect { repo.upload('my-staging-repository', true) }.not_to output(%r{Uploading...\n}).to_stdout
        end

        it 'retries upload if it fails' do
          allow(repo).to receive(:authenticate).and_return(nil)
          allow(repo).to receive(:validate).and_return(nil)
          allow(Gitlab::Util).to receive(:shellout_stdout).and_raise(
            Gitlab::Util::ShellOutExecutionError.new('pulp command', 1, 'MOCK_TEST_ERROR: Simulated upload failure for retry testing', '')
          )

          expect(Gitlab::Util).to receive(:shellout_stdout).exactly(10).times

          expect { repo.upload('my-staging-repository', false) }.to raise_error(PackageRepository::PackageUploadError)
        end
      end

      context 'with rpm artifacts available' do
        before do
          allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/el-9/gitlab-ce.rpm'])
        end

        it 'in dry run mode does not print the upload command' do
          expect { repo.upload('my-staging-repository', true) }.not_to output(%r{Uploading...\n}).to_stdout
        end

        it 'uploads to both EL and OL repositories' do
          allow(repo).to receive(:authenticate).and_return(nil)
          allow(repo).to receive(:validate).and_return(nil)
          allow(Gitlab::Util).to receive(:shellout_stdout).and_return('')

          expect(Gitlab::Util).to receive(:shellout_stdout).twice

          repo.upload('my-staging-repository', false)
        end

        it 'retries upload if it fails' do
          allow(repo).to receive(:authenticate).and_return(nil)
          allow(repo).to receive(:validate).and_return(nil)
          allow(Gitlab::Util).to receive(:shellout_stdout).and_raise(
            Gitlab::Util::ShellOutExecutionError.new('pulp command', 1, 'MOCK_TEST_ERROR: Simulated upload failure for retry testing', '')
          )

          # Expects 10 retries for the first repository, then raises error before attempting second repository
          expect(Gitlab::Util).to receive(:shellout_stdout).exactly(10).times

          expect { repo.upload('my-staging-repository', false) }.to raise_error(PackageRepository::PackageUploadError)
        end
      end

      context 'with opensuse artifacts available' do
        before do
          allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/opensuse-15.5/gitlab-ce.rpm'])
        end

        it 'uploads to both OpenSUSE and SLES repositories' do
          allow(repo).to receive(:authenticate).and_return(nil)
          allow(repo).to receive(:validate).and_return(nil)
          allow(Gitlab::Util).to receive(:shellout_stdout).and_return('')

          expect(Gitlab::Util).to receive(:shellout_stdout).twice

          repo.upload('my-staging-repository', false)
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

    describe "with production repository" do
      context 'with deb artifacts available' do
        before do
          stub_env_var('PULP_USER', "gitlab")
          allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/ubuntu-focal/gitlab.deb'])
        end

        context 'for stable release' do
          before do
            stub_env_var('PULP_REPO', nil)
            stub_env_var('RASPBERRY_REPO', nil)
            allow(repo).to receive(:repository_for_rc).and_return(nil)
          end

          context 'of EE' do
            before do
              stub_is_ee(true)
            end

            it 'in dry run mode does not print the upload command' do
              expect { repo.upload(nil, true) }.not_to output(%r{Uploading...\n}).to_stdout
            end

            context 'for arm64 packages' do
              before do
                allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/ubuntu-focal_aarch64/gitlab.deb'])
              end

              it 'drops the architecture suffix from repo path' do
                expect { repo.upload(nil, true) }.not_to output(%r{Uploading...\n}).to_stdout
              end
            end

            context 'for fips packages' do
              before do
                allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/ubuntu-focal_fips/gitlab.deb'])
              end

              it 'drops the fips suffix from repo path' do
                expect { repo.upload(nil, true) }.not_to output(%r{Uploading...\n}).to_stdout
              end
            end
          end

          context 'of CE' do
            before do
              stub_is_ee(nil)
            end

            it 'in dry run mode does not print the upload command' do
              expect { repo.upload(nil, true) }.not_to output(%r{Uploading...\n}).to_stdout
            end
          end
        end

        context 'for unstable release' do
          before do
            stub_env_var('PULP_REPO', nil)
            stub_env_var('RASPBERRY_REPO', nil)
            allow(repo).to receive(:repository_for_rc).and_return('unstable')
          end

          it 'in dry run mode does not print the upload command' do
            expect { repo.upload(nil, true) }.not_to output(%r{Uploading...\n}).to_stdout
          end
        end

        context 'for raspbian release' do
          before do
            set_raspi_env_variable
            allow(repo).to receive(:repository_for_rc).and_return(nil)
          end

          it 'in dry run mode does not print the upload command' do
            expect { repo.upload(nil, true) }.not_to output(%r{Uploading...\n}).to_stdout
          end
        end
      end
      context 'with rpm artifacts available' do
        before do
          stub_env_var('PULP_USER', "gitlab")
          allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/el-9/gitlab.rpm'])
        end

        context 'for stable release' do
          before do
            stub_env_var('PULP_REPO', nil)
            stub_env_var('RASPBERRY_REPO', nil)
            allow(repo).to receive(:repository_for_rc).and_return(nil)
          end

          context 'of EE' do
            before do
              stub_is_ee(true)
            end

            it 'in dry run mode does not print the upload command' do
              expect { repo.upload(nil, true) }.not_to output(%r{Uploading...\n}).to_stdout
            end

            context 'for arm64 packages' do
              before do
                allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/el-9_aarch64/gitlab.rpm'])
              end

              it 'includes architecture in repository name' do
                expect { repo.upload(nil, true) }.not_to output(%r{Uploading...\n}).to_stdout
              end

              it 'uploads to both EL and OL repositories with architecture' do
                allow(repo).to receive(:authenticate).and_return(nil)
                allow(repo).to receive(:validate).and_return(nil)
                allow(Gitlab::Util).to receive(:shellout_stdout).and_return('')

                expect(Gitlab::Util).to receive(:shellout_stdout).twice

                repo.upload(nil, false)
              end
            end

            context 'for fips packages' do
              before do
                allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/el-9_fips/gitlab.rpm'])
              end

              it 'includes fips in repository name' do
                expect { repo.upload(nil, true) }.not_to output(%r{Uploading...\n}).to_stdout
              end

              it 'uploads to both EL and OL repositories with fips' do
                allow(repo).to receive(:authenticate).and_return(nil)
                allow(repo).to receive(:validate).and_return(nil)
                allow(Gitlab::Util).to receive(:shellout_stdout).and_return('')

                expect(Gitlab::Util).to receive(:shellout_stdout).twice

                repo.upload(nil, false)
              end
            end
          end

          context 'of CE' do
            before do
              stub_is_ee(nil)
            end

            it 'in dry run mode does not print the upload command' do
              expect { repo.upload(nil, true) }.not_to output(%r{Uploading...\n}).to_stdout
            end
          end
        end

        context 'for unstable release' do
          before do
            stub_env_var('PULP_REPO', nil)
            stub_env_var('RASPBERRY_REPO', nil)
            allow(repo).to receive(:repository_for_rc).and_return('unstable')
          end

          it 'in dry run mode does not print the upload command' do
            expect { repo.upload(nil, true) }.not_to output(%r{Uploading...\n}).to_stdout
          end
        end
      end
    end

    describe 'when artifacts contain unexpected files' do
      before do
        stub_env_var('PULP_USER', "gitlab")
        set_all_env_variables
        allow(Build::Info::Package).to receive(:file_list).and_return(['pkg/ubuntu-focal/gitlab.deb', 'pkg/ubuntu-focal/extra-dir/gitlab.deb'])
      end

      it 'raises an exception' do
        expect { repo.upload(nil, true) }.to raise_exception(%r{Found unexpected contents in the directory:})
      end
    end
  end

  describe '#package_list (private method)' do
    context 'with real-world DEB package examples' do
      before do
        # Prevent any real command execution
        allow(Gitlab::Util).to receive(:shellout_stdout).and_return('')
        allow(repo).to receive(:authenticate).and_return(nil)
        allow(repo).to receive(:validate).and_return(nil)
      end

      it 'processes gitlab-ce ubuntu-focal_aarch64 package' do
        file_path = 'pkg/ubuntu-focal_aarch64/gitlab-ce_18.6.0-ce.0_arm64.deb'
        allow(Build::Info::Package).to receive(:file_list).and_return([file_path])
        allow(repo).to receive(:target).and_return('gitlab-ce')

        list = repo.send(:package_list, nil)

        expect(list.length).to eq(1) # DEB packages don't have additional platforms
        expect(list[0][:file_path]).to eq(file_path)
        expect(list[0][:repository]).to eq('gitlab-gitlab-ce-ubuntu-focal')
        expect(list[0][:distribution_version]).to eq('focal')
        expect(list[0][:component]).to eq('main')
      end

      it 'processes gitlab-ee ubuntu-focal_aarch64 package' do
        file_path = 'pkg/ubuntu-focal_aarch64/gitlab-ee_18.6.0-ee.0_arm64.deb'
        allow(Build::Info::Package).to receive(:file_list).and_return([file_path])
        allow(repo).to receive(:target).and_return('gitlab-ee')

        list = repo.send(:package_list, nil)

        expect(list.length).to eq(1)
        expect(list[0][:file_path]).to eq(file_path)
        expect(list[0][:repository]).to eq('gitlab-gitlab-ee-ubuntu-focal')
        expect(list[0][:distribution_version]).to eq('focal')
        expect(list[0][:component]).to eq('main')
      end

      it 'processes nightly-builds ubuntu-focal package' do
        file_path = 'pkg/ubuntu-focal/gitlab-ce_18.6.0+rnightly.2174954246.cc6d74b0-0_amd64.deb'
        allow(Build::Info::Package).to receive(:file_list).and_return([file_path])
        allow(repo).to receive(:target).and_return('nightly-builds')

        list = repo.send(:package_list, nil)

        expect(list.length).to eq(1)
        expect(list[0][:file_path]).to eq(file_path)
        expect(list[0][:repository]).to eq('gitlab-nightly-builds-ubuntu-focal')
        expect(list[0][:distribution_version]).to eq('focal')
        expect(list[0][:component]).to eq('main')
      end

      it 'processes pre-release ubuntu-focal package' do
        file_path = 'pkg/ubuntu-focal/gitlab-ee_18.5.0-ee.0_amd64.deb'
        allow(Build::Info::Package).to receive(:file_list).and_return([file_path])
        allow(repo).to receive(:target).and_return('pre-release')

        list = repo.send(:package_list, nil)

        expect(list.length).to eq(1)
        expect(list[0][:file_path]).to eq(file_path)
        expect(list[0][:repository]).to eq('gitlab-pre-release-ubuntu-focal')
        expect(list[0][:distribution_version]).to eq('focal')
        expect(list[0][:component]).to eq('main')
      end

      it 'processes gitlab-fips ubuntu-focal_fips package' do
        file_path = 'pkg/ubuntu-focal_fips/gitlab-fips_18.3.6-fips.0_amd64.deb'
        allow(Build::Info::Package).to receive(:file_list).and_return([file_path])
        allow(repo).to receive(:target).and_return('gitlab-fips')

        list = repo.send(:package_list, nil)

        expect(list.length).to eq(1)
        expect(list[0][:file_path]).to eq(file_path)
        expect(list[0][:repository]).to eq('gitlab-gitlab-fips-ubuntu-focal')
        expect(list[0][:distribution_version]).to eq('focal')
        expect(list[0][:component]).to eq('main')
      end

      it 'processes nightly-fips-builds ubuntu-focal_fips package' do
        file_path = 'pkg/ubuntu-focal_fips/gitlab-fips_18.6.0+rnightly.fips.2174954242.cc6d74b0-0_amd64.deb'
        allow(Build::Info::Package).to receive(:file_list).and_return([file_path])
        allow(repo).to receive(:target).and_return('nightly-fips-builds')

        list = repo.send(:package_list, nil)

        expect(list.length).to eq(1)
        expect(list[0][:file_path]).to eq(file_path)
        expect(list[0][:repository]).to eq('gitlab-nightly-fips-builds-ubuntu-focal')
        expect(list[0][:distribution_version]).to eq('focal')
        expect(list[0][:component]).to eq('main')
      end
    end

    context 'with real-world RPM package examples' do
      before do
        # Prevent any real command execution
        allow(Gitlab::Util).to receive(:shellout_stdout).and_return('')
        allow(repo).to receive(:authenticate).and_return(nil)
        allow(repo).to receive(:validate).and_return(nil)
      end

      it 'processes gitlab-ce el-8_aarch64 package' do
        file_path = 'pkg/el-8_aarch64/gitlab-ce-18.6.0-ce.0.el8.aarch64.rpm'
        allow(Build::Info::Package).to receive(:file_list).and_return([file_path])
        allow(repo).to receive(:target).and_return('gitlab-ce')

        list = repo.send(:package_list, nil)

        expect(list.length).to eq(2) # Original EL + Oracle Linux
        expect(list[0][:file_path]).to eq(file_path)
        expect(list[0][:repository]).to eq('gitlab-gitlab-ce-el-8-aarch64')
        expect(list[0][:distribution_version]).to eq('8')
        expect(list[0][:component]).to eq('main')

        # Oracle Linux variant
        expect(list[1][:repository]).to eq('gitlab-gitlab-ce-ol-8-aarch64')
        expect(list[1][:distribution_version]).to eq('8')
      end

      it 'processes gitlab-ee el-8 (x86_64) package' do
        file_path = 'pkg/el-8/gitlab-ee-18.5.1-ee.0.el8.x86_64.rpm'
        allow(Build::Info::Package).to receive(:file_list).and_return([file_path])
        allow(repo).to receive(:target).and_return('gitlab-ee')

        list = repo.send(:package_list, nil)

        expect(list.length).to eq(2) # Original EL + Oracle Linux
        expect(list[0][:file_path]).to eq(file_path)
        expect(list[0][:repository]).to eq('gitlab-gitlab-ee-el-8-x86_64')
        expect(list[0][:distribution_version]).to eq('8')
        expect(list[0][:component]).to eq('main')

        # Oracle Linux variant
        expect(list[1][:repository]).to eq('gitlab-gitlab-ee-ol-8-x86_64')
        expect(list[1][:distribution_version]).to eq('8')
      end

      it 'processes opensuse-15.6 package (for SLES transformation)' do
        file_path = 'pkg/opensuse-15.6/gitlab-ee-18.5.1-ee.0.sles15.x86_64.rpm'
        allow(Build::Info::Package).to receive(:file_list).and_return([file_path])
        allow(repo).to receive(:target).and_return('gitlab-ee')

        list = repo.send(:package_list, nil)

        expect(list.length).to eq(2) # Original OpenSUSE + SLES
        expect(list[0][:file_path]).to eq(file_path)
        expect(list[0][:repository]).to eq('gitlab-gitlab-ee-opensuse-15.6-x86_64')
        expect(list[0][:distribution_version]).to eq('15.6')
        expect(list[0][:component]).to eq('main')

        # SLES variant
        expect(list[1][:repository]).to eq('gitlab-gitlab-ee-sles-15.6-x86_64')
        expect(list[1][:distribution_version]).to eq('15.6')
      end

      it 'processes amazon-2023_aarch64 package' do
        file_path = 'pkg/amazon-2023_aarch64/gitlab-ce-18.6.0-ce.0.amazon2023.aarch64.rpm'
        allow(Build::Info::Package).to receive(:file_list).and_return([file_path])
        allow(repo).to receive(:target).and_return('gitlab-ce')

        list = repo.send(:package_list, nil)

        expect(list.length).to eq(1) # Amazon Linux only (no additional platforms)
        expect(list[0][:file_path]).to eq(file_path)
        expect(list[0][:repository]).to eq('gitlab-gitlab-ce-amazon-2023-aarch64')
        expect(list[0][:distribution_version]).to eq('2023')
        expect(list[0][:component]).to eq('main')
      end

      it 'processes el-9_fips package' do
        file_path = 'pkg/el-9_fips/gitlab-fips-18.5.2-fips.0.el9.x86_64.rpm'
        allow(Build::Info::Package).to receive(:file_list).and_return([file_path])
        allow(repo).to receive(:target).and_return('gitlab-fips')

        list = repo.send(:package_list, nil)

        expect(list.length).to eq(2) # Original EL + Oracle Linux
        expect(list[0][:file_path]).to eq(file_path)
        expect(list[0][:repository]).to eq('gitlab-gitlab-fips-el-9-x86_64')
        expect(list[0][:distribution_version]).to eq('9')
        expect(list[0][:component]).to eq('main')

        # Oracle Linux variant
        expect(list[1][:repository]).to eq('gitlab-gitlab-fips-ol-9-x86_64')
        expect(list[1][:distribution_version]).to eq('9')
      end
    end
  end

  def unset_all_env_variables
    stub_env_var('PULP_USER', nil)
    stub_env_var('PULP_REPO', nil)
    stub_env_var('RASPBERRY_REPO', nil)
  end

  def set_all_env_variables
    stub_env_var("PULP_REPO", "pulp-stable-5678")
    stub_env_var("RASPBERRY_REPO", "raspi")
  end

  def set_raspi_env_variable
    stub_env_var("PULP_REPO", "")
    stub_env_var("RASPBERRY_REPO", "raspi")
  end
end
