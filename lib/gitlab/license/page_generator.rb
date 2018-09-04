require 'erb'
require 'fileutils'
require_relative '../build/info.rb'

module License
  class PageGenerator
    def initialize
      @edition = Build::Info.package
      @license_bucket = ENV['LICENSE_S3_BUCKET']
      @licenses_path = File.absolute_path(@license_bucket)
      @current_minor_version = Build::Info.release_version.split(".")[0, 2].join(".")
      @license_bucket_region = "eu-west-1"
    end

    def execute
      s3_fetch
      copy_license
      generate_html
      s3_upload
    end

    def s3_sync(source, destination)
      system("AWS_ACCESS_KEY_ID=#{ENV['LICENSE_AWS_ACCESS_KEY_ID']} AWS_SECRET_ACCESS_KEY=#{ENV['LICENSE_AWS_SECRET_ACCESS_KEY']} aws s3 sync --region #{@license_bucket_region} #{source} #{destination}")
    end

    def s3_fetch
      s3_sync("s3://#{@license_bucket}", @licenses_path)
    end

    def s3_upload
      s3_sync(@licenses_path, "s3://#{@license_bucket}")
    end

    def copy_license
      # The bucket has the following structure
      #
      # gitlab-licenses
      # |-- gitlab-ce
      # |   |-- 11.0
      # |   |   |-- 11.0.1-ce.0.license.txt
      # |   |   `-- 11.0.2-ce.0.license.txt
      # |   `-- 11.1
      # |       |-- 11.1.1-ce.0.license.txt
      # |       `-- 11.1.2-ce.0.license.txt
      # |-- gitlab-ce.html
      # |-- gitlab-ee
      # |   |-- 11.0
      # |   |   |-- 11.0.1-ee.0.license.txt
      # |   |   `-- 11.0.2-ee.0.license.txt
      # |   `-- 11.1
      # |       |-- 11.1.1-ee.0.license.txt
      # |       `-- 11.1.2-ee.0.license.txt
      # `-- gitlab-ee.html
      #
      dest_dir = File.join(@licenses_path, @edition, @current_minor_version)
      FileUtils.mkdir_p(dest_dir)
      FileUtils.cp("pkg/ubuntu-bionic/license-status.txt", "#{dest_dir}/#{Build::Info.release_version}.license.txt")
    end

    def generate_html
      template = File.read(File.join(File.dirname(__FILE__), "output.html.erb"))
      output_text = ERB.new(template).result(binding)

      output_path = File.join(@licenses_path, "#{@edition}.html")
      FileUtils.mkdir_p(File.dirname(output_path))

      File.open(output_path, "w") do |f|
        f.write(output_text)
      end
    end
  end
end
