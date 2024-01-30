require 'omnibus'

require_relative '../aws_helper'
require_relative '../build/check'
require_relative '../build/info/package'

namespace :aws do
  namespace :ami do
    desc "Create AWS AMI"
    task :create do
      next unless Build::Check.on_tag?

      next if Build::Check.is_auto_deploy? || Build::Check.is_rc_tag?

      Omnibus.load_configuration('omnibus.rb')
      AWSHelper.new(Omnibus::BuildVersion.semver, Build::Info::Package.edition).create_ami
    end
  end

  namespace :marketplace do
    desc "Release AMI to AWS Marketplace"
    task :release do
      next unless Build::Check.is_latest_stable_tag?

      next if Build::Check.is_auto_deploy? || Build::Check.is_rc_tag?

      Omnibus.load_configuration('omnibus.rb')
      AWSHelper.new(Omnibus::BuildVersion.semver, Build::Info::Package.edition).marketplace_release
    end
  end
end
