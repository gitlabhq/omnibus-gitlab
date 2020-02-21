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
  let(:dummy_client) { AwsDummyClass.new }

  before :all do
    Rake.application.rake_require 'gitlab/tasks/aws'
  end

  before do
    Rake::Task['aws:process'].reenable
    allow_any_instance_of(Kernel).to receive(:system).and_return(true)
    allow(Aws::EC2::Client).to receive(:new).and_return(dummy_client)
  end

  it 'should identify ce category correctly, if specified' do
    allow(Build::Info).to receive(:edition).and_return('ce')
    allow(Omnibus::BuildVersion).to receive(:semver).and_return('9.3.0')

    expect { Rake::Task['aws:process'].invoke }.to output(/Finding existing images of GitLab Community Edition/).to_stdout
  end

  it 'should identify ce category correctly if nothing is specified' do
    allow(Build::Info).to receive(:edition).and_return(nil)
    allow(Omnibus::BuildVersion).to receive(:semver).and_return('9.3.0')

    expect { Rake::Task['aws:process'].invoke }.to output(/Finding existing images of GitLab Community Edition/).to_stdout
  end

  it 'should identify ee category correctly' do
    allow(Build::Info).to receive(:edition).and_return('ee')
    allow(Omnibus::BuildVersion).to receive(:semver).and_return('9.3.0')

    expect { Rake::Task['aws:process'].invoke }.to output(/Finding existing images of GitLab Enterprise Edition/).to_stdout
  end

  it 'should identify ee ultimate category correctly' do
    allow(Build::Info).to receive(:edition).and_return('ee')
    allow(Gitlab::Util).to receive(:get_env).and_call_original
    allow(Gitlab::Util).to receive(:get_env).with("AWS_RELEASE_TYPE").and_return('ultimate')
    allow(Omnibus::BuildVersion).to receive(:semver).and_return('9.3.0')

    expect { Rake::Task['aws:process'].invoke }.to output(/Finding existing images of GitLab Enterprise Edition Ultimate/).to_stdout
  end

  it 'should identify ee premium category correctly' do
    allow(Build::Info).to receive(:edition).and_return('ee')
    allow(Gitlab::Util).to receive(:get_env).and_call_original
    allow(Gitlab::Util).to receive(:get_env).with("AWS_RELEASE_TYPE").and_return('premium')
    allow(Omnibus::BuildVersion).to receive(:semver).and_return('9.3.0')

    expect { Rake::Task['aws:process'].invoke }.to output(/Finding existing images of GitLab Enterprise Edition Premium/).to_stdout
  end

  # it 'should delete existing smaller versioned AMIs' do
  # allow(File).to receive(:read).with('VERSION').and_return('8.16.4-ce')
  # expect_any_instance_of(AwsDummyClass).to receive(:deregister_image).and_return(true)
  # expect { Rake::Task['aws:process'].invoke }.to output(/Found to be smaller. Deleting/).to_stdout
  # end

  it 'should call packer with necessary arguments' do
    allow(Build::Info).to receive(:edition).and_return('ce')
    allow(Build::Info).to receive(:package_download_url).and_return('http://example.com')
    allow(Omnibus::BuildVersion).to receive(:semver).and_return('8.16.4')
    allow(Build::Check).to receive(:is_ee?).and_return(false)
    allow(Build::Check).to receive(:match_tag?).and_return(true)

    expect_any_instance_of(Kernel).to receive(:system).with(*["support/packer/packer_ami.sh", "8.16.4", "ce", "http://example.com", ""])
    expect { Rake::Task['aws:process'].invoke }.to output(/No greater version exists. Creating AMI/).to_stdout
  end

  it 'should identify existing greater versioned AMIs' do
    allow(Build::Info).to receive(:edition).and_return('ee')
    allow(Omnibus::BuildVersion).to receive(:semver).and_return('8.16.4')

    expect { Rake::Task['aws:process'].invoke }.to output(/Greater version already exists. Skipping/).to_stdout
  end

  it 'should not build cloud image for RC versions' do
    allow(Build::Check).to receive(:match_tag?).and_return(false)
    expect(Kernel).not_to receive(:system)
  end
end
