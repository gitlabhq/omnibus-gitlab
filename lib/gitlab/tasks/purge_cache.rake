require 'fileutils'

desc "Purge existing cache"
namespace :build do
  task :purge_cache do
    [
      # Force a new clone of gitlab-rails because we change remotes for CE/EE
      "/var/cache/omnibus/src/gitlab-rails",

      # Avoid mysterious GitFetcher omnibus errors
      "/var/cache/omnibus/src/gitlab-shell",
      "/var/cache/omnibus/src/gitlab-workhorse",

      # Clear out old packages to prevent uploading them a second time to S3
      "/var/cache/omnibus/pkg"
    ].each do |path|
      FileUtils.rm_r path, force: true, secure: true
    end
    FileUtils.rm_r 'pkg', force: true, secure: true
    FileUtils.mkdir_p 'pkg'
  end
end
