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

    if (@type == 'ee') && release_type
      @type = "ee-#{release_type}"
      @license_file = "AWS_#{release_type}_LICENSE_FILE".upcase
    end

    @download_url = Build::Info.package_download_url

    system(*%W[support/packer/packer_ami.sh #{@version} #{@type} #{@download_url} #{@license_file}])
  end

  def marketplace_release
    @listing_name = Gitlab::Util.get_env('AWS_LISTING_NAME')
    set_marketplace_details

    @ec2_client = Aws::EC2::Client.new(region: 'us-east-1')
    @marketplace_client = Aws::MarketplaceCatalog::Client.new(region: 'us-east-1')

    entity = find_entity
    new_version_details = get_new_version_details(entity)
    changeset_params = get_changeset_params(entity, new_version_details)
    new_change_set = @marketplace_client.start_change_set(changeset_params)

    puts "Changeset ID is #{new_change_set.change_set_id}"
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

  def get_sources(ami_id)
    sources = [{}]
    sources.first['Id'] = "#{@edition} #{@version} source AMI"
    sources.first['Resource'] = ami_id
    sources.first['Type'] = 'Ami'
    sources.first['OperatingSystem'] = {
      "Name" => "UBUNTU",
      "Version" => "16.04",
      "Username" => "ubuntu"
    }

    sources
  end

  def get_delivery_methods(new_version_details)
    delivery_methods = [{}]

    delivery_methods.first['Id'] = "#{@edition} #{@version} Delivery"
    delivery_methods.first['SourceId'] = "#{@edition} #{@version} source AMI"
    delivery_methods.first['Type'] = "SingleAmi"
    delivery_methods.first['Title'] = new_version_details['DeliveryMethods'].first['Title']
    delivery_methods.first['Instructions'] = new_version_details['DeliveryMethods'].first['Instructions']
    delivery_methods.first['Recommendations'] = {
      "SecurityGroups" => new_version_details['DeliveryMethods'].first['Recommendations']['SecurityGroups']
    }
    delivery_methods.first['Lifecycle'] = {
      "State" => new_version_details['DeliveryMethods'].first['Visibility']
    }

    delivery_methods
  end

  def get_provisioning_details(ami_id, details)
    new_version_details = details['Versions'].last.dup

    sources = get_sources(ami_id)
    delivery_methods = get_delivery_methods(new_version_details)

    {
      "ProvisioningOptions" => [
        {
          "Id" => "#{@edition} #{@version} Release",
          "VersionTitle" => "#{@edition} #{@version}",
          "ReleaseNotes" => "#{@edition} #{@version} release. Visit https://about.gitlab.com/releases for details.",
          "Sources" => sources,
          "DeliveryMethods" => delivery_methods
        }
      ]
    }
  end

  def get_presentation_details(details)
    {
      "Title" => details['Description']['Title'],
      "ShortDescription" => details['Description']['Subtitle'],
      "FullDescription" => details['Description']['Overview'],
      "ManufacturerName" => details['Description']['Manufacturer'],
      "Logo" => details['PromotionalResources']['Logo'],
      "Videos" => details['PromotionalResources']['Videos'],
      "Highlights" => details['Description']['Highlights'],
      "AdditionalResources" => details['PromotionalResources']['AdditionalResources'],
      "Support" => {
        "ShortDescription" => details['SupportInformation']['Description'],
      }
    }
  end

  def get_new_version_details(entity)
    image = find_image
    raise "AMI not found" unless image

    ami_id = image.image_id
    details = JSON.parse(entity.details)
    {
      "Presentation" => get_presentation_details(details),
      "Provisioning" => get_provisioning_details(ami_id, details)
    }
  end

  def get_changeset_params(entity, new_version_details)
    {
      catalog: "AWSMarketplace",
      change_set_name: "#{type_of_update} version update",
      change_set: [
        {
          change_type: "UpdatePresentation",
          entity: {
            identifier: entity.entity_identifier,
            type: entity.entity_type
          },
          details: JSON.dump({ "Presentation": new_version_details['Presentation'] })
        },
        {
          change_type: "UpdateProvisioning",
          entity: {
            identifier: entity.entity_identifier,
            type: entity.entity_type
          },
          details: JSON.dump({ "Provisioning": new_version_details['Provisioning'] })
        }
      ]
    }
  end
end
