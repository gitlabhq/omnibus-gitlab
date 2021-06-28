require_relative "util"
require_relative "ohai_helper"
require_relative "build/check"

require 'gitlab'

class PackageSizeCheck
  CE_MAX_SIZE_MB = Gitlab::Util.get_env('CE_MAX_SIZE_MB')&.to_i || 950
  EE_MAX_SIZE_MB = Gitlab::Util.get_env('EE_MAX_SIZE_MB')&.to_i || 1000
  ALERT_ENDPOINT = Gitlab::Util.get_env('PACKAGE_SIZE_ALERT_ENDPOINT')
  ALERT_TOKEN = Gitlab::Util.get_env('PACKAGE_SIZE_ALERT_TOKEN')

  class << self
    def fetch_sizefile
      api_url = Gitlab::Util.get_env('CI_API_V4_URL')
      project_id = Gitlab::Util.get_env('CI_PROJECT_ID')
      pipeline_id = Gitlab::Util.get_env('CI_PIPELINE_ID')
      token = Gitlab::Util.get_env('PACKAGE_SIZE_CHECK_OMNIBUS_GITLAB_MIRROR_TOKEN')

      gitlab_client = ::Gitlab.client(endpoint: api_url, private_token: token)
      pipeline_jobs = gitlab_client.pipeline_jobs(project_id, pipeline_id)
      trigger_package_job = pipeline_jobs.find { |j| j.name == 'Trigger:package' }

      # We have to use net/http here because `gitlab` gem's `download_job_artifact_file`
      # method doesn't support plain text files. It has to be either binary or valid JSON.
      # https://github.com/NARKOZ/gitlab/issues/621
      sizefile_url = URI("#{api_url}/projects/#{project_id}/jobs/#{trigger_package_job.id}/artifacts/pkg/ubuntu-focal/gitlab.deb.size")
      req = Net::HTTP::Get.new(sizefile_url)
      req['PRIVATE-TOKEN'] = token
      res = Net::HTTP.start(sizefile_url.hostname, sizefile_url.port, use_ssl: true) do |http|
        http.request(req)
      end

      size = res.body

      FileUtils.mkdir_p('pkg/ubuntu-focal')
      File.write('pkg/ubuntu-focal/gitlab.deb.size', size)
    end

    def generate_sizefiles(files)
      files.each do |file|
        File.write("#{file}.size", File.stat(file).size)
      end
    end

    def check_and_alert(package_sizefile = 'pkg/ubuntu-focal/gitlab.deb.size')
      permitted_size = if Build::Check.is_ee?
                         EE_MAX_SIZE_MB
                       else
                         CE_MAX_SIZE_MB
                       end

      package_size = File.read(package_sizefile).strip.to_i / 1024.0**2
      success = package_size <= permitted_size

      return if success

      puts "Package size #{package_size.round(2)}MB above threshold of #{permitted_size}MB."
      alert(package_size, permitted_size)
      exit 1
    end

    def alert(package_size, permitted_size)
      unless ALERT_ENDPOINT && ALERT_TOKEN
        puts 'Alert endpoint and token not defined. Not triggering an alert.'
        return
      end

      uri = URI(ALERT_ENDPOINT)
      result = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        request['Authorization'] = "Bearer #{ALERT_TOKEN}"
        request.body = payload(package_size, permitted_size).to_json
        http.request(request)
      end

      return if result.code == '200'

      puts 'Failed to trigger alert.'
      puts "Response code: #{result.code}"
      puts "Response message: #{result.message}"
      exit 1
    end

    def payload(package_size, permitted_size)
      # In omnibus-gitlab canonical mirror alert settings, we have mapped these
      # custom fields to GitLab alert fields as follows:
      # title => title
      # description => description
      # pipeline => monitoring_tool
      # os => host
      # fingerprint => fingerprint
      #
      # Also, we are setting a custom static value for fingerprint so that
      # alerts will be grouped together.
      {
        title: "#{Build::Info.edition.upcase} package size exceeded threshold of #{permitted_size} MB",
        description: "Package size: #{package_size.round(2)} MB.",
        pipeline: Gitlab::Util.get_env('CI_PIPELINE_URL'),
        os: OhaiHelper.platform_dir,
        fingerprint: "omnibus-gitlab-package-size-#{Build::Info.edition}" # For automatic grouping of alerts
      }
    end
  end
end
