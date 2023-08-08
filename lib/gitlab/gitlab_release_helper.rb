require 'json'

class GitlabReleaseHelper
  class << self
    def release_details
      content = release_contents

      return if content.empty?

      content.unshift("# GitLab #{Build::Info::Package.edition.upcase} #{Build::Info::Package.semver_version}").join("\n")
    end

    def release_contents
      content = []

      content += package_details_content
      content += docker_details_content
      content += ami_details_content

      content
    end

    def package_details_content
      []
    end

    def docker_details_content
      []
    end

    def ami_details_content
      result = ami_details

      return [] if result.empty?

      content = ["## Amazon AMIs"]
      result.each do |name, details|
        content << "#### #{name}"
        content << "| Region | AMI ID |"
        content << "| ------ |:------:|"
        details.each do |region, id|
          content << "| #{region} | #{id} |"
        end
      end

      content
    end

    def ami_details
      result = {}

      Dir.glob("support/packer/manifests/*.json").sort.each do |manifest_file|
        # We don't want details of Premium and Ultimate AMIs in the release
        # page, as they are only accessible via AWS Marketplace
        next if manifest_file.match?(/(premium|ultimate)/)

        manifest_data = JSON.parse(File.read(manifest_file))

        name = manifest_data['builds'].first['custom_data']['name']

        ami_id_string = manifest_data['builds'].first['artifact_id']
        ami_ids = {}.tap do |ami_ids|
          ami_id_string.split(',').each do |region_id_string|
            region, id = region_id_string.split(':')
            ami_ids[region] = id
          end
        end

        result[name] = ami_ids
      end

      result
    end
  end
end
