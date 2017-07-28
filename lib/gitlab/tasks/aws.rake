require_relative '../aws_helper.rb'
require_relative '../build.rb'
require 'omnibus'

namespace :aws do
  desc "Perform operations related to AWS AMI"
  task :process do
    if Build.add_latest_tag?
      AWSHelper.new(Omnibus::BuildVersion.semver, Build.edition).process
    end
  end
end
