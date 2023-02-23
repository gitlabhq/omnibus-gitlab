require 'erb'
require 'fileutils'
require_relative '../build/info.rb'
require_relative "../util.rb"
require_relative 'base.rb'

module Manifest
  # Roots through the LICENSE_S3_BUCKET'and creates an html page with links to
  # all version manifests. The gitlab.com CI "pages" job is later used to upload
  # the results (along with the bucket itself) to the web-site.
  class Collector < Base
    def initialize
      @manifests_bucket = Gitlab::Util.get_env('LICENSE_S3_BUCKET')
      @manifests_bucket_path = File.join(@manifests_bucket, 'gitlab-manifests')
      @manifests_local_path = File.join(File.absolute_path(@manifests_bucket), 'gitlab-manifests')
      @manifests_bucket_region = "eu-west-1"
      @json_data = nil
    end

    def execute
      s3_fetch
      generate_index_page
    end

    def generate_index_page
      template = File.read(File.join(File.dirname(__FILE__), "manifests.html.erb"))
      output_text = ERB.new(template).result(binding)

      output_path = File.join(@manifests_local_path, "manifests.html")
      FileUtils.mkdir_p(File.dirname(output_path))

      File.open(output_path, "w") do |f|
        f.write(output_text)
      end
    end
  end
end
