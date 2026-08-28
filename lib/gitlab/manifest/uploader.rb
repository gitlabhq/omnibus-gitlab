# Regenerate the versions-manifest.json file setting ALTERNATIVE_SOURCES to true
# so we get the public versions of the repositories. This file is then published
# at https://gitlab-org.gitlab.io/omnibus-gitlab/gitlab-manifests/manifests.html
# using the CI "pages" job.

require 'omnibus'
require 'yaml'

require_relative 'base'

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
      @edition = Build::Info::Package.edition
      @package = Build::Info::Package.name
      @manifests_bucket = Gitlab::Util.get_env('LICENSE_S3_BUCKET')
      @manifests_bucket_path = File.join(@manifests_bucket, 'gitlab-manifests')
      @manifests_local_path = File.join(File.absolute_path(@manifests_bucket), 'gitlab-manifests')
      @current_version = Build::Info::Package.release_version.split("+")[0]
      @current_minor_version = @current_version.split(".")[0, 2].join(".")
      # eu-west-1 is where the real manifest bucket lives; allow an override so
      # a personal test bucket can be in any region.
      @manifests_bucket_region = Gitlab::Util.get_env('LICENSE_S3_BUCKET_REGION') || 'eu-west-1'
      @json_data = nil
    end

    def execute
      @generator.create_manifest
      fetched = s3_fetch

      unless overwrite?
        # verify_no_overwrite! checks the local mirror s3_fetch produced. If the
        # fetch failed, that mirror is empty and the check would pass against a
        # false absence, so refuse rather than risk clobbering an existing file.
        raise 'S3 fetch of existing manifests failed; cannot safely check for an existing manifest.' unless fetched

        verify_no_overwrite!
      end

      copy_manifests
      s3_upload
    end

    # Whether an existing manifest for this version may be replaced. The default
    # (env unset) preserves historical behaviour -- the release manifest-upload
    # job overwrites freely -- so only tooling that opts in (e.g. the manifest
    # regeneration script/pipeline, which sets MANIFEST_OVERWRITE=false) is
    # guarded against clobbering an already-published manifest.
    def overwrite?
      Gitlab::Util.get_env('MANIFEST_OVERWRITE') != 'false'
    end

    def target_manifest_path
      File.join(@manifests_local_path, @package, @current_minor_version,
                "#{@current_version}-#{@edition}.#{@generator.manifest_filename}")
    end

    # s3_fetch mirrors the bucket locally first, so a file present here means the
    # manifest already exists in S3.
    def verify_no_overwrite!
      return unless File.exist?(target_manifest_path)

      raise "Manifest for #{@current_version}-#{@edition} already exists at " \
            "s3://#{File.join(@manifests_bucket_path, @package, @current_minor_version)}/" \
            "#{@current_version}-#{@edition}.#{@generator.manifest_filename}. " \
            'Set MANIFEST_OVERWRITE=true to replace it.'
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
      FileUtils.mkdir_p(File.dirname(target_manifest_path))
      FileUtils.cp(@generator.manifest_path, target_manifest_path)
    end
  end
end
