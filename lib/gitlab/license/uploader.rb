require 'erb'
require 'fileutils'
require_relative '../build/info.rb'
require_relative "../util.rb"
require_relative 'base.rb'

module License
  class Uploader < Base
    def initialize
      @edition = Build::Info.package
      @license_bucket = Gitlab::Util.get_env('LICENSE_S3_BUCKET')
      @licenses_path = File.absolute_path(@license_bucket)
      @current_version = Build::Info.release_version
      @current_minor_version = @current_version.split(".")[0, 2].join(".")
      @license_bucket_region = "eu-west-1"
      @json_data = nil
    end

    def execute
      s3_fetch
      copy_license
      load_data
      generate_package_page
      s3_upload
    end

    def copy_license
      # The bucket has the following structure
      #
      # gitlab-licenses
      # |-- gitlab-ce
      # |   |-- 11.0
      # |   |   |-- 11.0.1-ce.0.json
      # |   |   |-- 11.0.1-ce.0.html
      # |   |   |-- 11.0.2-ce.0.json
      # |   |   `-- 11.0.2-ce.0.html
      # |   `-- 11.1
      # |       |-- 11.1.1-ce.0.json
      # |       |-- 11.1.1-ce.0.html
      # |       |-- 11.1.2-ce.0.json
      # |       `-- 11.1.2-ce.0.html
      # `-- gitlab-ee
      #     |-- 11.0
      #     |   |-- 11.0.1-ee.0.json
      #     |   |-- 11.0.1-ee.0.html
      #     |   |-- 11.0.2-ee.0.json
      #     |   `-- 11.0.2-ee.0.html
      #     `-- 11.1
      #         |-- 11.1.1-ee.0.json
      #         |-- 11.1.1-ee.0.html
      #         |-- 11.1.2-ee.0.json
      #         `-- 11.1.2-ee.0.html
      #
      dest_dir = File.join(@licenses_path, @edition, @current_minor_version)
      FileUtils.mkdir_p(dest_dir)
      FileUtils.cp("pkg/ubuntu-bionic/#{@edition}_#{@current_version}.license-status.json", "#{dest_dir}/#{@current_version}.json")
    end

    def load_data
      dest_dir = File.join(@licenses_path, @edition, @current_minor_version)
      @json_data = JSON.parse(File.read("#{dest_dir}/#{@current_version}.json")).sort
    end

    def generate_package_page
      template = File.read(File.join(File.dirname(__FILE__), "package.html.erb"))
      output_text = ERB.new(template).result(binding)

      output_path = File.join(@licenses_path, @edition, @current_minor_version, "#{@current_version}.html")
      FileUtils.mkdir_p(File.dirname(output_path))

      File.open(output_path, "w") do |f|
        f.write(output_text)
      end
    end
  end
end
