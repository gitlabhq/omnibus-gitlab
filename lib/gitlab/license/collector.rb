require 'erb'
require 'fileutils'
require_relative '../build/info.rb'
require_relative "../util.rb"
require_relative 'base.rb'

module License
  class Collector < License::Base
    def initialize
      @license_bucket = Gitlab::Util.get_env('LICENSE_S3_BUCKET')
      @licenses_path = File.absolute_path(@license_bucket)
      @license_bucket_region = "eu-west-1"
      @json_data = nil
    end

    def execute
      s3_fetch
      generate_index_page
    end

    def generate_index_page
      template = File.read(File.join(File.dirname(__FILE__), "licenses.html.erb"))
      output_text = ERB.new(template).result(binding)

      output_path = File.join(@licenses_path, "licenses.html")
      FileUtils.mkdir_p(File.dirname(output_path))

      File.open(output_path, "w") do |f|
        f.write(output_text)
      end
    end
  end
end
