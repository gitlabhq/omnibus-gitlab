# Regenerate the versions-manifest.json file setting ALTERNATIVE_SOURCES to true
# so we get the public versions of the repositories. This file is then published
# at https://gitlab-org.gitlab.io/omnibus-gitlab/gitlab-manifests/manifests.html
# using the CI "pages" job.

require 'omnibus'
require 'yaml'
require 'gitlab/version'
require_relative 'base.rb'

module Manifest
  # Creates manifest for one edition based on the value of the "ee" environment
  # variable.
  class Generator
    attr_reader :manifest_dir, :manifest_filename

    def initialize
      @manifest_dir = File.join(Omnibus::Config.base_dir, 'manifests')
      @manifest_filename = 'version-manifest.json'
    end

    def manifest_path
      File.join(@manifest_dir, @manifest_filename)
    end

    def create_manifest
      FileUtils.mkdir_p(manifest_dir) unless File.directory?(manifest_dir)
      Gitlab::Util.set_env('ALTERNATIVE_SOURCES', 'true') # We always want public sources.
      project = Omnibus::Project.load('gitlab') # project is a singleton.
      project.json_manifest_path manifest_path
      project.write_json_manifest
    end
  end

  class Uploader < Base
    # Generates and uploads the manifest to the LICENSE_S3_BUCKET. As the name
    # implies, this bucket is shared with the licenses.
    def initialize
      @generator = Generator.new
      @edition = Build::Info.edition
      @package = Build::Info.package
      @manifests_bucket = Gitlab::Util.get_env('LICENSE_S3_BUCKET')
      @manifests_bucket_path = File.join(@manifests_bucket, 'gitlab-manifests')
      @manifests_local_path = File.join(File.absolute_path(@manifests_bucket), 'gitlab-manifests')
      @current_version = Build::Info.release_version.split("+")[0]
      @current_minor_version = @current_version.split(".")[0, 2].join(".")
      @manifests_bucket_region = "eu-west-1"
      @json_data = nil
    end

    def execute
      @generator.create_manifest
      s3_fetch
      copy_manifests
      s3_upload
    end

    def copy_manifests
      # The bucket has the following structure
      #
      # gitlab-manifests
      # |-- gitlab-ce
      # |   |-- 11.0
      # |   |   |-- 11.0.0-ce.version-manifest.json
      # |   |   |-- 11.0.1-ce.version-manifest.json
      # |   `-- 11.1
      # |       |-- 11.1.0-ce.version-manifest.json
      # |       |-- 11.1.1-ce.version-manifest.json
      # `-- gitlab-ee
      #     |-- 11.0
      #     |   |-- 11.0.0-ee.version-manifest.json
      #     |   |-- 11.0.1-ee.version-manifest.json
      #     `-- 11.1
      #         |-- 11.1.0-ee.version-manifest.json
      #         |-- 11.1.1.ee.version-manifest.json
      #
      dest_dir = File.join(@manifests_local_path, @package, @current_minor_version)
      FileUtils.mkdir_p(dest_dir)
      FileUtils.cp(@generator.manifest_path, File.join(dest_dir, "#{@current_version}-#{@edition}.#{@generator.manifest_filename}"))
    end
  end
end
