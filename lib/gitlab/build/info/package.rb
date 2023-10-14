require 'omnibus'

require_relative '../../build_iteration'
require_relative '../../util'
require_relative '../check'

module Build
  class Info
    class Package
      PACKAGE_GLOB = "pkg/**/*.{deb,rpm}".freeze

      class << self
        def name
          return "gitlab-fips" if Check.use_system_ssl?
          return "gitlab-ee" if Check.is_ee?

          "gitlab-ce"
        end

        def edition
          # Returns `ee`, `ce`, or `fips`
          Info::Package.name.gsub("gitlab-", "").strip
        end

        # For auto-deploy builds, we set the semver to the following which is
        # derived directly from the auto-deploy tag:
        #   MAJOR.MINOR.PIPELINE_ID+<ee ref>-<omnibus ref>
        #   See https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/auto-deploy.md#auto-deploy-tagging
        #
        # For nightly builds we fetch all GitLab components from master branch
        # If there was no change inside of the omnibus-gitlab repository, the
        # package version will remain the same but contents of the package will be
        # different.
        # To resolve this, we append a PIPELINE_ID to change the name of the package
        def semver_version
          if Build::Check.on_tag?
            # timestamp is disabled in omnibus configuration
            Omnibus.load_configuration('omnibus.rb')
            Omnibus::BuildVersion.semver
          else
            latest_git_tag = Info::Git.latest_tag.strip
            latest_version = latest_git_tag && !latest_git_tag.empty? ? latest_git_tag[0, latest_git_tag.match("[+]").begin(0)] : '0.0.1'
            commit_sha = Build::Info::Git.commit_sha
            ver_tag = "#{latest_version}+" + (Build::Check.is_nightly? ? "rnightly" : "rfbranch")
            ver_tag += ".fips" if Build::Check.use_system_ssl?
            [ver_tag, Gitlab::Util.get_env('CI_PIPELINE_ID'), commit_sha].compact.join('.')
          end
        end

        def release_version
          semver = Info::Package.semver_version
          "#{semver}-#{Gitlab::BuildIteration.new.build_iteration}"
        end

        def file_list
          Dir.glob(PACKAGE_GLOB)
        end

        def name_version
          # String used by respective package managers to install the specific version of the package
          Omnibus.load_configuration('omnibus.rb')
          project = Omnibus::Project.load('gitlab')
          packager = project.packagers_for_system[0]

          case packager
          when Omnibus::Packager::DEB
            "#{Build::Info::Package.name}=#{packager.safe_version}-#{packager.safe_build_iteration}"
          when Omnibus::Packager::RPM
            "#{Build::Info::Package.name}-#{packager.safe_version}-#{packager.safe_build_iteration}#{packager.dist_tag}"
          else
            raise "Unable to detect version"
          end
        end
      end
    end
  end
end
