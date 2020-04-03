require 'aws-sdk'
require_relative 'build/info.rb'
require_relative 'util.rb'

class AWSHelper
  def initialize(version, type)
    # version specifies the GitLab version being processed
    # type specifies whether it is CE or EE being processed

    @version = version
    @type = type || 'ce'
    release_type = Gitlab::Util.get_env('AWS_RELEASE_TYPE')

    if (@type == 'ee') && release_type
      @type = "ee-#{release_type}"
      @license_file = "AWS_#{release_type}_LICENSE_FILE".upcase
    end
    @download_url = Build::Info.package_download_url
  end

  def create_ami
    system(*%W[support/packer/packer_ami.sh #{@version} #{@type} #{@download_url} #{@license_file}])
  end
end
