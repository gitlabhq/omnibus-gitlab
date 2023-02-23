require_relative "../util.rb"

module Manifest
  class Base
    def s3_sync(source, destination)
      system(
        {
          'AWS_ACCESS_KEY_ID' => Gitlab::Util.get_env('LICENSE_AWS_ACCESS_KEY_ID'),
          'AWS_SECRET_ACCESS_KEY' => Gitlab::Util.get_env('LICENSE_AWS_SECRET_ACCESS_KEY')
        },
        *%W[aws s3 sync --region #{@manifests_bucket_region} #{source} #{destination}]
      )
    end

    def s3_fetch
      s3_sync("s3://#{@manifests_bucket_path}", @manifests_local_path)
    end

    def s3_upload
      s3_sync(@manifests_local_path, "s3://#{@manifests_bucket_path}")
    end
  end
end
