require_relative 'build/info.rb'
require_relative 'util.rb'

require 'aws-sdk-ec2'
require 'aws-sdk-marketplacecatalog'
require 'json'

class AWSHelper
  def initialize(version, type)
    # version specifies the GitLab version being processed
    # type specifies whether it is CE or EE being processed

    @version = version
    @type = type || 'ce'
  end

  def create_ami
    release_type = Gitlab::Util.get_env('AWS_RELEASE_TYPE')
    architecture = Gitlab::Util.get_env('AWS_ARCHITECTURE')
    args = {}

    if (@type == 'ee') && release_type
      @type = "ee-#{release_type}"
      @license_file = "AWS_#{release_type}_LICENSE_FILE".upcase
    end

    if architecture
      args = { arch: architecture }
      @type = "#{@type}-#{architecture}"
    end

    @download_url = Build::Info.deb_package_download_url(**args)

    system(*%W[support/packer/packer_ami.sh #{@version} #{@type} #{@download_url} #{@license_file}])
  end

  def set_marketplace_details
    case @listing_name
    when "GitLab Community Edition"
      @edition = "GitLab CE"
      @ami_edition_tag = "GitLab Community Edition"
    when "GitLab"
      @edition = "GitLab"
      @ami_edition_tag = "GitLab Enterprise Edition"
    when "GitLab Ultimate"
      @edition = "GitLab Ultimate"
      @ami_edition_tag = "GitLab Enterprise Edition Ultimate"
    when "GitLab Premium"
      @edition = "GitLab Premium"
      @ami_edition_tag = "GitLab Enterprise Edition Premium"
    else
      raise "Unknown listing"
    end
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
          values: [@ami_edition_tag]
        },
        {
          name: "tag-key",
          values: ["Version"],
        },
        {
          name: "tag-value",
          values: [@version]
        }
      ],
    }
  end

  def type_of_update
    _, minor, patch = @version.split(".")
    if minor == "0" && patch == "0"
      "Major"
    elsif patch == "0"
      "Minor"
    else
      "Patch"
    end
  end

  def find_entity
    entities = @marketplace_client.list_entities(catalog: 'AWSMarketplace', entity_type: 'ServerProduct')
    entity = entities.entity_summary_list.find { |en| en.name == @listing_name }
    raise "AWS Marketplace listing not found" unless entity

    @marketplace_client.describe_entity({ entity_id: entity.entity_id, catalog: 'AWSMarketplace' })
  end

  def find_image
    resp = @ec2_client.describe_images(image_filter)
    resp.images.first
  end

  def new_version_details(entity)
    image = find_image
    raise "AMI not found" unless image

    ami_id = image.image_id

    {
      "Version" => {
        "VersionTitle" => "#{@edition} #{@version} Release",
        "ReleaseNotes" => "#{@edition} #{@version} release. Visit https://about.gitlab.com/releases for details.",
      },
      "DeliveryOptions" => [
        {
          "Details" => {
            "AmiDeliveryOptionDetails" => {
              "AmiSource" => {
                "AmiId" => ami_id,
                "AccessRoleArn" => Gitlab::Util.get_env('AWS_MARKETPLACE_ARN'),
                "UserName" => "ubuntu",
                "OperatingSystemName" => "UBUNTU",
                "OperatingSystemVersion" => "20.04"
              },
              "UsageInstructions" => "https://docs.gitlab.com/ee/install/aws/",
              "RecommendedInstanceType" => "c5.xlarge",
              "SecurityGroups" => [
                {
                  "IpProtocol" => "tcp",
                  "FromPort" => 22,
                  "ToPort" => 22,
                  "IpRanges" => [
                    "0.0.0.0/0"
                  ]
                },
                {
                  "IpProtocol" => "tcp",
                  "FromPort" => 80,
                  "ToPort" => 80,
                  "IpRanges" => [
                    "0.0.0.0/0"
                  ]
                },
                {
                  "IpProtocol" => "tcp",
                  "FromPort" => 443,
                  "ToPort" => 443,
                  "IpRanges" => [
                    "0.0.0.0/0"
                  ]
                }
              ]
            }
          }
        }
      ]
    }
  end

  def get_changeset_params(entity)
    {
      catalog: "AWSMarketplace",
      change_set_name: "#{type_of_update} version update",
      change_set: [
        {
          change_type: "AddDeliveryOptions",
          entity: {
            identifier: entity.entity_identifier,
            type: 'AmiProduct@1.0'
          },
          details: JSON.dump(new_version_details(entity))
        }
      ]
    }
  end

  def marketplace_release
    @listing_name = Gitlab::Util.get_env('AWS_LISTING_NAME')
    set_marketplace_details

    @ec2_client = Aws::EC2::Client.new(region: 'us-east-1')
    @marketplace_client = Aws::MarketplaceCatalog::Client.new(region: 'us-east-1')

    entity = find_entity
    changeset_params = get_changeset_params(entity)
    new_change_set = @marketplace_client.start_change_set(changeset_params)

    puts "Changeset ID is #{new_change_set.change_set_id}"
  end
end
