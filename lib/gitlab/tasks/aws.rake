require_relative '../aws_helper.rb'
require_relative '../build/info.rb'
require_relative '../build/check.rb'
require 'omnibus'

namespace :aws do
  desc "Perform operations related to AWS AMI"
  task :process do
    next unless Build::Check.on_tag?

    next if Build::Check.is_auto_deploy? || Build::Check.is_rc_tag?

    Omnibus.load_configuration('omnibus.rb')
    AWSHelper.new(Omnibus::BuildVersion.semver, Build::Info.edition).create_ami
  end
end
