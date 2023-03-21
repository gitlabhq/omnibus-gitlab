require 'retriable'
require 'open3'
require_relative './build/info.rb'

class GCloudHelper
  GCSSyncError = Class.new(StandardError)
  SAFileNotSetError = Class.new(StandardError)
  SAActivationError = Class.new(StandardError)

  class << self
    def activate_sa!
      raise SAFileNotSetError, 'Service account file not set in environment!' unless sa_file

      out, status = Open3.capture2e("gcloud auth activate-service-account --key-file #{sa_file}")
      raise SAActivationError, "Service account activation failed! ret=#{status.exitstatus} out=#{out}" unless status.success?
    end

    def sa_file
      Build::Info.gcp_release_bucket_sa_file
    end

    def pkgs_bucket
      Build::Info.gcp_release_bucket
    end

    def gcs_sync!(dir)
      begin
        activate_sa!
      rescue SAFileNotSetError, SAActivationError => e
        return e.message
      end

      out = ""

      Retriable.retriable(tries: 4, max_elapsed_time: 900, on: GCSSyncError) do
        out, status = Open3.capture2e("gsutil -o GSUtil:parallel_composite_upload_threshold=150M -m rsync -r #{dir} gs://#{pkgs_bucket}")
        break if status.success?

        raise GCSSyncError, "Gsutil rsync failed! ret=#{status.exitstatus} out=#{out}"
      end

      out
    end

    def signed_urls(paths)
      begin
        activate_sa!
      rescue SAFileNotSetError, SAActivationError => e
        return e.message
      end

      gs_uris = paths.map { |p| "gs://#{pkgs_bucket}/#{p}" }
      # 12 hours is the maximum duration allowed for a signed url that
      # uses a service account
      out, status = Open3.capture2e("gsutil signurl -r us-east1 --use-service-account -d 12h #{gs_uris.join(' ')}")
      return "Unable to generate signed URL for #{gs_uris.join(' ')}! ret=#{status.exitstatus} out=#{out}" unless status.success?

      out
    end
  end
end
