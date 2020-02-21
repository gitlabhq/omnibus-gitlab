require 'aws-sdk'
require_relative 'build/info.rb'
require_relative 'util.rb'

class AWSHelper
  VERSION_REGEX = /\A(?<version>\d+\.\d+\.\d+)-?(?<type>(ee|ce))?\z/.freeze

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
    @clients = {}
    @download_url = Build::Info.package_download_url
  end

  def ec2_client(region)
    @clients[region] ||= Aws::EC2::Client.new(region: region)
  end

  def image_version(image)
    tag = image.tags.find { |tag| tag.key == "Version" }
    tag.value
  end

  def image_filter
    {
      dry_run: false,
      filters: [
        {
          name: "tag-key",
          values: ["Type"],
        },
        {
          name: "tag-value",
          values: [category]
        }
      ],
    }
  end

  def list_regions
    # AWS API mandatorily requires a region to be set for every client. Hence
    # using us-east-1 as a default region
    client = ec2_client('us-east-1')
    client.describe_regions.regions.map(&:region_name)
  end

  def category
    if @type == "ce"
      "GitLab Community Edition"
    elsif @type == "ee"
      "GitLab Enterprise Edition"
    elsif @type == "ee-ultimate"
      "GitLab Enterprise Edition Ultimate"
    elsif @type == "ee-premium"
      "GitLab Enterprise Edition Premium"
    end
  end

  def list_images(region)
    client = ec2_client(region)
    resp = client.describe_images(image_filter)
    resp.images
  end

  def delete_smaller(region)
    # client = ec2_client(region)
    images = list_images(region)
    images.each do |image|
      next unless Gem::Version.new(image_version(image)) < Gem::Version.new(@version)

      puts "\t#{image.image_id} - #{image.name} - #{image_version(image)}"

      # Commenting out actual deregister code temporarily for first few releases
      # client.deregister_image({
      #  dry_run: false,
      #  image_id: image.image_id
      # })
    end
  end

  def search_for_greater
    puts "Checking if greater version already exists"
    flag = false
    images = list_images('us-east-1')
    images.each do |image|
      if Gem::Version.new(image_version(image)) >= Gem::Version.new(@version)
        flag = true
        break
      end
    end
    flag
  end

  def create_ami
    system(*%W[support/packer/packer_ami.sh #{@version} #{@type} #{@download_url} #{@license_file}])
  end

  def process
    puts "Finding existing images of #{category}"
    greater_exist = search_for_greater
    if greater_exist
      puts "Greater version already exists. Skipping"
    else
      puts "No greater version exists. Creating AMI"
      status = create_ami
      if status
        list_regions.each do |region|
          puts "Deleting smaller images from #{region}"
          delete_smaller(region)
        end
      end
    end
  end
end
