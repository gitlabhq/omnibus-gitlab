require 'spec_helper'

Struct.new("Image", :image_id, :name, :tags)
Struct.new("Region", :region_name)
Struct.new("Response", :images)
Struct.new("Tag", :key, :value)
Struct.new("DescribeRegionResult", :regions)

class AwsDummyClass
  # Dummy class which mimicks AWS::EC2::Client class from aws-sdk and stubs
  # necessary methods

  def describe_images(parameters)
    images = if parameters['filters'.to_sym][1][:values] == ["GitLab Community Edition"]
               [
                 Struct::Image.new("ami-422", "GitLab Community Edition 8.13.2", [Struct::Tag.new("Version", "8.13.2")])
               ]
             else
               [
                 Struct::Image.new("ami-322", "GitLab Enterprise Edition 10.5.4", [Struct::Tag.new("Version", "10.5.4")])
               ]
             end
    @response = Struct::Response.new(images)
  end

  def describe_regions
    Struct::DescribeRegionResult.new([Struct::Region.new('us-east-1')])
  end

  def deregister_image(parameters)
    true
  end
end

describe 'aws:process', type: :rake do
  before :all do
    Rake.application.rake_require 'gitlab/tasks/aws'
  end

  before do
    Rake::Task['aws:process'].reenable
    allow_any_instance_of(Kernel).to receive(:system).and_return(true)
  end

  describe 'on a regular tag' do
    before do
      allow(Build::Check).to receive(:on_tag?).and_return(true)
      allow(Build::Check).to receive(:is_auto_deploy?).and_return(false)
      allow(Build::Check).to receive(:is_rc_tag?).and_return(false)
      allow(Build::Info).to receive(:package_download_url).and_return('http://example.com')
    end

    it 'should identify ce category correctly, if specified' do
      allow(Build::Info).to receive(:edition).and_return('ce')
      allow(Omnibus::BuildVersion).to receive(:semver).and_return('9.3.0')

      expect_any_instance_of(Kernel).to receive(:system).with(*["support/packer/packer_ami.sh", "9.3.0", "ce", "http://example.com", ""])

      Rake::Task['aws:process'].invoke
    end

    it 'should identify ce category correctly if nothing is specified' do
      allow(Build::Info).to receive(:edition).and_return(nil)
      allow(Omnibus::BuildVersion).to receive(:semver).and_return('9.3.0')

      expect_any_instance_of(Kernel).to receive(:system).with(*["support/packer/packer_ami.sh", "9.3.0", "ce", "http://example.com", ""])

      Rake::Task['aws:process'].invoke
    end

    it 'should identify ee category correctly' do
      allow(Build::Info).to receive(:edition).and_return('ee')
      allow(Omnibus::BuildVersion).to receive(:semver).and_return('9.3.0')

      expect_any_instance_of(Kernel).to receive(:system).with(*["support/packer/packer_ami.sh", "9.3.0", "ee", "http://example.com", ""])

      Rake::Task['aws:process'].invoke
    end

    it 'should identify ee ultimate category correctly' do
      allow(Build::Info).to receive(:edition).and_return('ee')
      allow(Gitlab::Util).to receive(:get_env).and_call_original
      allow(Gitlab::Util).to receive(:get_env).with("AWS_RELEASE_TYPE").and_return('ultimate')
      allow(Omnibus::BuildVersion).to receive(:semver).and_return('9.3.0')

      expect_any_instance_of(Kernel).to receive(:system).with(*["support/packer/packer_ami.sh", "9.3.0", "ee-ultimate", "http://example.com", "AWS_ULTIMATE_LICENSE_FILE"])

      Rake::Task['aws:process'].invoke
    end

    it 'should identify ee premium category correctly' do
      allow(Build::Info).to receive(:edition).and_return('ee')
      allow(Gitlab::Util).to receive(:get_env).and_call_original
      allow(Gitlab::Util).to receive(:get_env).with("AWS_RELEASE_TYPE").and_return('premium')
      allow(Omnibus::BuildVersion).to receive(:semver).and_return('9.3.0')

      expect_any_instance_of(Kernel).to receive(:system).with(*["support/packer/packer_ami.sh", "9.3.0", "ee-premium", "http://example.com", "AWS_PREMIUM_LICENSE_FILE"])

      Rake::Task['aws:process'].invoke
    end
  end

  describe 'on an rc tag' do
    before do
      allow(Build::Check).to receive(:on_tag?).and_return(true)
      allow(Build::Check).to receive(:is_auto_deploy?).and_return(false)
      allow(Build::Check).to receive(:is_rc_tag?).and_return(true)
      allow(Build::Info).to receive(:package_download_url).and_return('http://example.com')
    end

    it 'does not do anything' do
      expect(AWSHelper).not_to receive(:new)

      Rake::Task['aws:process'].invoke
    end
  end

  describe 'on an auto-deploy tag' do
    before do
      allow(Build::Check).to receive(:on_tag?).and_return(true)
      allow(Build::Check).to receive(:is_auto_deploy?).and_return(true)
      allow(Build::Check).to receive(:is_rc_tag?).and_return(false)
      allow(Build::Info).to receive(:package_download_url).and_return('http://example.com')
    end

    it 'does not do anything' do
      expect(AWSHelper).not_to receive(:new)

      Rake::Task['aws:process'].invoke
    end
  end
end
