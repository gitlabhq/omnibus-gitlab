require 'omnibus'
require 'net/http'
require 'json'

require_relative '../build_iteration'
require_relative "../util.rb"
require_relative 'check'
require_relative 'image'

module Build
  class Info
    OMNIBUS_PROJECT_MIRROR_PATH ||= 'gitlab-org/build/omnibus-gitlab-mirror'.freeze

    class << self
      def package
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
          latest_version = latest_git_tag[0, latest_git_tag.match("[+]").begin(0)]
          commit_sha = Build::Info.commit_sha
          ver_tag = "#{latest_version}+" + (Build::Check.is_nightly? ? "rnightly" : "rfbranch")
          [ver_tag, Gitlab::Util.get_env('CI_PIPELINE_ID'), commit_sha].compact.join('.')
        end
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
        `git -c versionsort.prereleaseSuffix=rc tag -l '#{Info.tag_match_pattern}' --sort=-v:refname | head -1`.chomp
      end

      def latest_stable_tag(level: 1)
        # Level decides tag at which position you want. Level one gives you
        # latest stable tag, two gives you the one just before it and so on.
        `git -c versionsort.prereleaseSuffix=rc tag -l '#{Info.tag_match_pattern}' --sort=-v:refname | awk '!/rc/' | head -#{level}`.split("\n").last
      end

      def docker_tag
        Info.release_version.tr('+', '-')
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
        # For normal builds, QA build happens from the gitlab repositories in dev.
        # For triggered builds, they are not available and their gitlab.com mirrors
        # have to be used.
        # CE repo - In com it is gitlab-foss, in dev it is gitlabhq
        # EE repo - In com it is gitlab, in dev it is gitlab-ee

        if Gitlab::Util.get_env('ALTERNATIVE_SOURCES').to_s == "true"
          domain = "https://gitlab.com/gitlab-org"
          project = package == "gitlab-ce" ? "gitlab-foss" : "gitlab"
        else
          domain = "git@dev.gitlab.org:gitlab"
          project = package == "gitlab-ce" ? "gitlabhq" : "gitlab-ee"
        end

        "#{domain}/#{project}.git"
      end

      def edition
        Info.package.gsub("gitlab-", "").strip # 'ee' or 'ce'
      end

      def release_bucket
        # Tag builds are releases and they get pushed to a specific S3 bucket
        # whereas regular branch builds use a separate one
        Check.on_tag? ? "downloads-packages" : "omnibus-builds"
      end

      def log_level
        if Gitlab::Util.get_env('BUILD_LOG_LEVEL') && !Gitlab::Util.get_env('BUILD_LOG_LEVEL').empty?
          Gitlab::Util.get_env('BUILD_LOG_LEVEL')
        else
          'info'
        end
      end

      # Fetch the package from an S3 bucket
      def package_download_url
        package_filename_url_safe = Info.release_version.gsub("+", "%2B")
        "https://#{Info.release_bucket}.s3.amazonaws.com/ubuntu-xenial/#{Info.package}_#{package_filename_url_safe}_amd64.deb"
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
        output = get_api("projects/#{project_id}/pipelines/#{pipeline_id}/jobs")
        output.map { |job| job['id'] if job['name'] == 'Trigger:package' }.compact.max
      end

      def fetch_pipeline_jobs(project_id, pipeline_id, token)
        get_api("projects/#{project_id}/pipelines/#{pipeline_id}/jobs")
      end

      def triggered_build_package_url
        project_id = Gitlab::Util.get_env('CI_PROJECT_ID')
        pipeline_id = Gitlab::Util.get_env('CI_PIPELINE_ID')
        return unless project_id && !project_id.empty? && pipeline_id && !pipeline_id.empty?

        id = fetch_artifact_url(project_id, pipeline_id)
        "https://gitlab.com/api/v4/projects/#{Gitlab::Util.get_env('CI_PROJECT_ID')}/jobs/#{id}/artifacts/pkg/ubuntu-xenial/gitlab.deb"
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
                         Info.package_download_url
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
        if Gitlab::Util.get_env('CI_PROJECT_PATH') == OMNIBUS_PROJECT_MIRROR_PATH && %w[trigger pipeline].include?(Gitlab::Util.get_env('CI_PIPELINE_SOURCE'))
          "#{Build::GitlabImage.gitlab_registry_image_address}:#{Gitlab::Util.get_env('IMAGE_TAG')}"
        elsif Build::Check.is_nightly? || Build::Check.on_tag?
          # We push nightly images to both dockerhub and gitlab registry
          "#{Build::GitlabImage.gitlab_registry_image_address}:#{Info.docker_tag}"
        else
          abort 'unknown pipeline type: only support triggered/nightly/tag pipeline'
        end
      end

      def deploy_env
        key = if Build::Check.is_auto_deploy_tag?
                'AUTO_DEPLOY_ENVIRONMENT'
              elsif Build::Check.is_rc_tag?
                'PATCH_DEPLOY_ENVIRONMENT'
              elsif Build::Check.is_latest_tag?
                'RELEASE_DEPLOY_ENVIRONMENT'
              end

        return nil if key.nil?

        env = Gitlab::Util.get_env(key)

        abort "Unable to determine which environment to deploy too, #{key} is empty" unless env

        puts "Ready to send trigger for environment(s): #{env}"

        env
      end
    end
  end
end
