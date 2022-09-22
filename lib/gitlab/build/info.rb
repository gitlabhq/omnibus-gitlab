require 'omnibus'
require 'net/http'
require 'json'

require_relative '../build_iteration'
require_relative "../util.rb"
require_relative 'check'
require_relative 'image'

module Build
  class Info
    DEPLOYER_OS_MAPPING = {
      'AUTO_DEPLOY_ENVIRONMENT' => 'ubuntu-xenial',
      'PATCH_DEPLOY_ENVIRONMENT' => 'ubuntu-bionic',
      'RELEASE_DEPLOY_ENVIRONMENT' => 'ubuntu-focal',
    }.freeze
    PACKAGE_GLOB = "pkg/**/*.{deb,rpm}".freeze

    class << self
      def fetch_fact_from_file(fact)
        return unless File.exist?("build_facts/#{fact}")

        content = File.read("build_facts/#{fact}").strip
        return content unless content.empty?
      end

      def package
        return "gitlab-fips" if Check.use_system_ssl?
        return "gitlab-ee" if Check.is_ee?

        "gitlab-ce"
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
          latest_git_tag = Info.latest_tag.strip
          latest_version = latest_git_tag && !latest_git_tag.empty? ? latest_git_tag[0, latest_git_tag.match("[+]").begin(0)] : '0.0.1'
          commit_sha = Build::Info.commit_sha
          ver_tag = "#{latest_version}+" + (Build::Check.is_nightly? ? "rnightly" : "rfbranch")
          ver_tag += ".fips" if Build::Check.use_system_ssl?
          [ver_tag, Gitlab::Util.get_env('CI_PIPELINE_ID'), commit_sha].compact.join('.')
        end
      end

      def branch_name
        Gitlab::Util.get_env('CI_COMMIT_BRANCH')
      end

      def commit_sha
        commit_sha_raw = Gitlab::Util.get_env('CI_COMMIT_SHA') || `git rev-parse HEAD`.strip
        commit_sha_raw[0, 8]
      end

      def release_version
        semver = Info.semver_version
        "#{semver}-#{Gitlab::BuildIteration.new.build_iteration}"
      end

      # TODO, merge latest_tag with latest_stable_tag
      # TODO, add tests, needs a repo clone
      def latest_tag
        unless (fact_from_file = fetch_fact_from_file(__method__)).nil?
          return fact_from_file
        end

        version = branch_name.delete_suffix('-stable').tr('-', '.') if Build::Check.on_stable_branch?

        `git -c versionsort.prereleaseSuffix=rc tag -l '#{version}#{Info.tag_match_pattern}' --sort=-v:refname | head -1`.chomp
      end

      def latest_stable_tag(level: 1)
        unless (fact_from_file = fetch_fact_from_file(__method__)).nil?
          return fact_from_file
        end

        version = branch_name.delete_suffix('-stable').tr('-', '.') if Build::Check.on_stable_branch?

        # Level decides tag at which position you want. Level one gives you
        # latest stable tag, two gives you the one just before it and so on.
        `git -c versionsort.prereleaseSuffix=rc tag -l '#{version}#{Info.tag_match_pattern}' --sort=-v:refname | awk '!/rc/' | head -#{level}`.split("\n").last
      end

      def docker_tag
        Gitlab::Util.get_env('IMAGE_TAG') || Info.release_version.tr('+', '-')
      end

      def gitlab_version
        # Get the branch/version/commit of GitLab CE/EE repo against which package
        # is built. If GITLAB_VERSION variable is specified, as in triggered builds,
        # we use that. Else, we use the value in VERSION file.

        if Gitlab::Util.get_env('GITLAB_VERSION').nil? || Gitlab::Util.get_env('GITLAB_VERSION').empty?
          File.read('VERSION').strip
        else
          Gitlab::Util.get_env('GITLAB_VERSION')
        end
      end

      def major_minor_version_and_rails_ref
        version_reg = /^(?<major>\d+)\.(?<minor>\d+)\.\d+\+(?<railsref>\w+)\.\w+$/
        match = Gitlab::Util.get_env('CI_COMMIT_TAG').match(version_reg)
        raise "Invalid auto-deploy version '#{Gitlab::Util.get_env('CI_COMMIT_TAG')}'" unless match

        major = match['major']
        minor = match['minor']
        rails_ref = match['railsref']

        "#{major}.#{minor}-#{rails_ref}"
      end

      def previous_version
        # Get the second latest git tag
        previous_tag = Info.latest_stable_tag(level: 2)
        previous_tag.tr("+", "-")
      end

      def gitlab_rails_repo
        gitlab_rails =
          if package == "gitlab-ce"
            "gitlab-rails"
          else
            "gitlab-rails-ee"
          end

        Gitlab::Version.new(gitlab_rails).remote
      end

      def edition
        Info.package.gsub("gitlab-", "").strip # 'ee' or 'ce'
      end

      def release_bucket
        # Tag builds are releases and they get pushed to a specific S3 bucket
        # whereas regular branch builds use a separate one
        downloads_bucket = Gitlab::Util.get_env('RELEASE_BUCKET') || "downloads-packages"
        builds_bucket = Gitlab::Util.get_env('BUILDS_BUCKET') || "omnibus-builds"
        Check.on_tag? ? downloads_bucket : builds_bucket
      end

      def release_bucket_region
        Gitlab::Util.get_env('RELEASE_BUCKET_REGION') || "eu-west-1"
      end

      def release_bucket_s3_endpoint
        Gitlab::Util.get_env('RELEASE_BUCKET_S3_ENDPOINT') || "s3.amazonaws.com"
      end

      def log_level
        if Gitlab::Util.get_env('BUILD_LOG_LEVEL') && !Gitlab::Util.get_env('BUILD_LOG_LEVEL').empty?
          Gitlab::Util.get_env('BUILD_LOG_LEVEL')
        else
          'info'
        end
      end

      # Fetch the package from an S3 bucket
      def deb_package_download_url(arch: 'amd64')
        folder = 'ubuntu-focal'
        folder = "#{folder}_aarch64" if arch == 'arm64'

        package_filename_url_safe = Info.release_version.gsub("+", "%2B")
        "https://#{Info.release_bucket}.#{Info.release_bucket_s3_endpoint}/#{folder}/#{Info.package}_#{package_filename_url_safe}_#{arch}.deb"
      end

      def rpm_package_download_url(arch: 'x86_64')
        folder = 'el-8'
        folder = "#{folder}_aarch64" if arch == 'arm64'
        folder = "#{folder}_fips" if Build::Check.use_system_ssl?

        package_filename_url_safe = Info.release_version.gsub("+", "%2B")
        "https://#{Info.release_bucket}.#{Info.release_bucket_s3_endpoint}/#{folder}/#{Info.package}-#{package_filename_url_safe}.el8.#{arch}.rpm"
      end

      def get_api(path, token: nil)
        uri = URI("https://gitlab.com/api/v4/#{path}")
        req = Net::HTTP::Get.new(uri)
        req['PRIVATE-TOKEN'] = token || Gitlab::Util.get_env('TRIGGER_PRIVATE_TOKEN')
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true
        res = http.request(req)
        JSON.parse(res.body)
      end

      def fetch_artifact_url(project_id, pipeline_id)
        job_name = 'Trigger:package'
        job_name = "#{job_name}:fips" if Build::Check.use_system_ssl?

        output = get_api("projects/#{project_id}/pipelines/#{pipeline_id}/jobs")
        output.map { |job| job['id'] if job['name'] == job_name }.compact.max
      end

      def fetch_pipeline_jobs(project_id, pipeline_id, token)
        get_api("projects/#{project_id}/pipelines/#{pipeline_id}/jobs")
      end

      def triggered_build_package_url
        project_id = Gitlab::Util.get_env('CI_PROJECT_ID')
        pipeline_id = Gitlab::Util.get_env('CI_PIPELINE_ID')
        return unless project_id && !project_id.empty? && pipeline_id && !pipeline_id.empty?

        id = fetch_artifact_url(project_id, pipeline_id)

        folder = 'ubuntu-focal'
        folder = "#{folder}_fips" if Build::Check.use_system_ssl?

        "https://gitlab.com/api/v4/projects/#{Gitlab::Util.get_env('CI_PROJECT_ID')}/jobs/#{id}/artifacts/pkg/#{folder}/gitlab.deb"
      end

      def tag_match_pattern
        return '*[+.]ee.*' if Check.is_ee?

        '*[+.]ce.*'
      end

      def release_file_contents
        repo = Gitlab::Util.get_env('PACKAGECLOUD_REPO') # Target repository
        token = Gitlab::Util.get_env('TRIGGER_PRIVATE_TOKEN') # Token used for triggering a build

        download_url = if token && !token.empty?
                         Info.triggered_build_package_url
                       else
                         Info.deb_package_download_url
                       end
        contents = []
        contents << "PACKAGECLOUD_REPO=#{repo.chomp}\n" if repo && !repo.empty?
        contents << "RELEASE_PACKAGE=#{Info.package}\n"
        contents << "RELEASE_VERSION=#{Info.release_version}\n"
        contents << "DOWNLOAD_URL=#{download_url}\n" if download_url
        contents << "TRIGGER_PRIVATE_TOKEN=#{token.chomp}\n" if token && !token.empty?
        contents.join
      end

      def current_git_tag
        `git describe --exact-match 2>/dev/null`.chomp
      end

      def image_reference
        "#{Build::GitlabImage.gitlab_registry_image_address}:#{Info.docker_tag}"
      end

      def deploy_env_key
        if Build::Check.is_auto_deploy_tag?
          'AUTO_DEPLOY_ENVIRONMENT'
        elsif Build::Check.is_rc_tag?
          'PATCH_DEPLOY_ENVIRONMENT'
        elsif Build::Check.is_latest_stable_tag?
          'RELEASE_DEPLOY_ENVIRONMENT'
        end
      end

      def deploy_env
        key = deploy_env_key

        return nil if key.nil?

        env = Gitlab::Util.get_env(key)

        abort "Unable to determine which environment to deploy too, #{key} is empty" unless env

        puts "Ready to send trigger for environment(s): #{env}"

        env
      end

      def package_list
        Dir.glob(PACKAGE_GLOB)
      end
    end
  end
end
