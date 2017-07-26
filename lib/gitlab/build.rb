require_relative "build_iteration.rb"
require 'omnibus'
require 'net/http'
require 'json'

class Build
  class << self
    include FileUtils

    def exec(project)
      sh cmd(project)
    end

    def cmd(project)
      "bundle exec omnibus build #{project} --log-level #{log_level}"
    end

    def is_ee?
      return true if ENV['ee'] == 'true'

      system('grep -q -E "\-ee" VERSION')
    end

    def package
      return "gitlab-ee" if is_ee?

      "gitlab-ce"
    end

    # Docker related commands

    # For nightly builds we fetch all GitLab components from master branch
    # If there was no change inside of the omnibus-gitlab repository, the
    # package version will remain the same but contents of the package will be
    # different.
    # To resolve this, we append a PIPELINE_ID to change the name of the package

    # TODO, duplication of the code in config/project/gitlab.rb should be removed.
    def release_version
      # timestamp is disabled in omnibus configuration
      Omnibus.load_configuration('omnibus.rb')

      semver = Omnibus::BuildVersion.semver
      if ENV['NIGHTLY'] && ENV['CI_PIPELINE_ID']
        semver = "#{semver}.#{ENV['CI_PIPELINE_ID']}"
      end

      "#{semver}-#{Gitlab::BuildIteration.new.build_iteration}"
    end

    # TODO, merge latest_tag with latest_stable_tag
    # TODO, add tests, needs a repo clone
    def latest_tag
      `git -c versionsort.prereleaseSuffix=rc tag -l '#{tag_match_pattern}' --sort=-v:refname | head -1`
    end

    def latest_stable_tag
      `git -c versionsort.prereleaseSuffix=rc tag -l '#{tag_match_pattern}' --sort=-v:refname | awk '!/rc/' | head -1`
    end

    def docker_tag
      release_version.tr('+', '-')
    end

    def add_latest_tag?
      match_tag(latest_stable_tag)
    end

    def add_rc_tag?
      match_tag(latest_tag)
    end

    def add_nightly_tag?
      ENV['NIGHTLY'] == 'true'
    end

    def write_release_file
      contents = release_file_contents
      File.write('docker/RELEASE', contents)
      contents
    end

    private

    def log_level
      if ENV['BUILD_LOG_LEVEL'] && !ENV['BUILD_LOG_LEVEL'].empty?
        ENV['BUILD_LOG_LEVEL']
      else
        'info'
      end
    end

    def tag_match_pattern
      return '*[+.]ee.*' if is_ee?

      '*[+.]ce.*'
    end

    def release_file_contents
      repo = ENV['PACKAGECLOUD_REPO'] # Target repository
      release_package = package # CE/EE
      package_filename = release_version
      token = ENV['TRIGGER_PRIVATE_TOKEN'] # Token used for triggering a build

      download_url = if token && !token.empty?
                       triggered_build_package_url
                     else
                       package_download_url
                     end
      contents = []
      contents << "PACKAGECLOUD_REPO=#{repo.chomp}\n" if repo && !repo.empty?
      contents << "RELEASE_PACKAGE=#{release_package}\n"
      contents << "RELEASE_VERSION=#{package_filename}\n"
      contents << "DOWNLOAD_URL=#{download_url}\n" if download_url
      contents << "TRIGGER_PRIVATE_TOKEN=#{token.chomp}\n" if token && !token.empty?
      contents.join
    end

    # Fetch the package from an S3 bucket
    def package_download_url
      release_bucket = ENV['RELEASE_BUCKET']
      return unless release_bucket

      package_filename_url_safe = release_version.gsub("+", "%2B")
      "https://#{release_bucket}.s3.amazonaws.com/ubuntu-xenial/#{package}_#{package_filename_url_safe}_amd64.deb"
    end

    def triggered_build_package_url
      project_id = ENV['CI_PROJECT_ID']
      pipeline_id = ENV['CI_PIPELINE_ID']
      return unless project_id && !project_id.empty? && pipeline_id && !pipeline_id.empty?

      id = fetch_artifact_url(project_id, pipeline_id)
      "#{ENV['CI_PROJECT_URL']}/builds/#{id}/artifacts/raw/pkg/ubuntu-16.04/gitlab.deb"
    end

    def fetch_artifact_url(project_id, pipeline_id)
      uri = URI("https://gitlab.com/api/v4/projects/#{project_id}/pipelines/#{pipeline_id}/jobs")
      req = Net::HTTP::Get.new(uri)
      req['PRIVATE-TOKEN'] = ENV["TRIGGER_PRIVATE_TOKEN"]
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = true
      res = http.request(req)
      output = JSON.parse(res.body)
      output.find { |job| job['name'] == 'Trigger:package' }['id']
    end

    def match_tag(tag)
      system("git describe --exact-match --match #{tag}")
    end
  end
end
