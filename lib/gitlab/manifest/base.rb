require_relative '../util'

module Manifest
  class Base
    def s3_sync(source, destination)
      result = system(
        {
          'AWS_ACCESS_KEY_ID' => Gitlab::Util.get_env('LICENSE_AWS_ACCESS_KEY_ID'),
          'AWS_SECRET_ACCESS_KEY' => Gitlab::Util.get_env('LICENSE_AWS_SECRET_ACCESS_KEY')
        },
        *%W[aws s3 sync --region #{@manifests_bucket_region} #{source} #{destination}]
      )
      # system returns nil (not false) when the executable cannot be spawned. A
      # missing aws CLI would otherwise make both the fetch and upload silent
      # no-ops while the task still reports success.
      raise 'aws CLI not found on PATH; install awscli to sync manifests.' if result.nil?

      result
    end

    def s3_fetch
      s3_sync("s3://#{@manifests_bucket_path}", @manifests_local_path)
    end

    def s3_upload
      s3_sync(@manifests_local_path, "s3://#{@manifests_bucket_path}")
    end
  end
end
