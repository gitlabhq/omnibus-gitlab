require 'google/cloud/storage'

require_relative 'build/check'
require_relative 'util'

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
      Gitlab::Util.get_env('GITLAB_COM_PKGS_SA_FILE')
    end

    def pkgs_bucket
      # All tagged builds are pushed to the release bucket
      # whereas regular branch builds use a separate one
      gcp_pkgs_release_bucket = Gitlab::Util.get_env('GITLAB_COM_PKGS_RELEASE_BUCKET') || 'gitlab-com-pkgs-release'
      gcp_pkgs_builds_bucket = Gitlab::Util.get_env('GITLAB_COM_PKGS_BUILDS_BUCKET') || 'gitlab-com-pkgs-builds'
      Build::Check.on_tag? ? gcp_pkgs_release_bucket : gcp_pkgs_builds_bucket
    end
  end
end
