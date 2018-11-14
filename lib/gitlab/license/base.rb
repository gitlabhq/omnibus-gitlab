module License
  class Base
    def s3_sync(source, destination)
      system("AWS_ACCESS_KEY_ID=#{ENV['LICENSE_AWS_ACCESS_KEY_ID']} AWS_SECRET_ACCESS_KEY=#{ENV['LICENSE_AWS_SECRET_ACCESS_KEY']} aws s3 sync --region #{@license_bucket_region} #{source} #{destination}")
    end

    def s3_fetch
      s3_sync("s3://#{@license_bucket}", @licenses_path)
    end

    def s3_upload
      s3_sync(@licenses_path, "s3://#{@license_bucket}")
    end
  end
end
