require 'google/cloud/storage'
require_relative './build/info.rb'

class GCloudHelper
  class << self
    def upload_packages_and_print_urls(dir)
      if sa_file.nil? || !File.exist?(sa_file)
        warn "Error finding service account file. Can not upload packages to bucket."
        return
      end

      storage = Google::Cloud::Storage.new(credentials: sa_file)
      bucket = storage.bucket(pkgs_bucket)

      signed_urls = []
      dir_path = File.absolute_path(dir)

      puts "Syncing packages to GCS bucket."
      Dir.glob("#{dir_path}/*/**").each do |source|
        destination = source.delete_prefix("#{dir_path}/")

        puts "\tUploading #{destination}"
        bucket.upload_file(source, destination)
        signed_urls << bucket.signed_url(destination, version: :v4)
      end

      puts signed_urls
    end

    private

    def sa_file
      Build::Info.gcp_release_bucket_sa_file
    end

    def pkgs_bucket
      Build::Info.gcp_release_bucket
    end
  end
end
