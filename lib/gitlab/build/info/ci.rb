require_relative '../../util'
require_relative '../../api_client'
require_relative '../check'

module Build
  class Info
    class CI
      class << self
        def branch_name
          Gitlab::Util.get_env('CI_COMMIT_BRANCH')
        end

        def tag_name
          Gitlab::Util.get_env('CI_COMMIT_TAG')
        end

        def project_id
          Gitlab::Util.get_env('CI_PROJECT_ID')
        end

        def pipeline_id
          Gitlab::Util.get_env('CI_PIPELINE_ID')
        end

        def job_id
          Gitlab::Util.get_env('CI_JOB_ID')
        end

        def job_token
          Gitlab::Util.get_env('CI_JOB_TOKEN')
        end

        def api_v4_url
          Gitlab::Util.get_env('CI_API_V4_URL')
        end

        def commit_ref_slug
          Gitlab::Util.get_env('CI_COMMIT_REF_SLUG')
        end

        def artifact_url(job_name, file_path)
          client = Gitlab::APIClient.new
          target_job_id = client.get_job_id(job_name)

          return unless target_job_id

          URI("#{api_v4_url}/projects/#{project_id}/jobs/#{target_job_id}/artifacts/#{file_path}")
        end

        def triggered_package_download_url(fips: Build::Check.use_system_ssl?)
          folder = fips ? 'ubuntu-focal_fips' : 'ubuntu-jammy'
          job_name = fips ? 'Trigger:package:fips' : 'Trigger:package'
          package_path = "pkg/#{folder}/gitlab.deb"

          artifact_url(job_name, package_path)
        end

        def package_download_url(job_name: "Ubuntu-22.04", arch: 'amd64')
          case job_name
          when /AlmaLinux-8/
            # In EL world, amd64 is called x86_64
            arch = 'x86_64' if arch == 'amd64'
            folder = 'el-8'
            package_file_name = "#{Info::Package.name}-#{Info::Package.release_version.gsub('+', '%2B')}.el8.#{arch}.rpm"
          when /Ubuntu-20.04/
            folder = 'ubuntu-focal'
            package_file_name = "#{Info::Package.name}_#{Info::Package.release_version.gsub('+', '%2B')}_#{arch}.deb"
          when /Ubuntu-22.04/
            folder = 'ubuntu-jammy'
            package_file_name = "#{Info::Package.name}_#{Info::Package.release_version.gsub('+', '%2B')}_#{arch}.deb"
          end

          if arch == 'arm64'
            job_name = "#{job_name}-arm64"
            folder = "#{folder}_aarch64"
          end

          job_name = "#{job_name}-branch" unless Build::Info::CI.tag_name

          package_path = "pkg/#{folder}/#{package_file_name}"
          Build::Info::CI.artifact_url(job_name, package_path)
        end
      end
    end
  end
end
