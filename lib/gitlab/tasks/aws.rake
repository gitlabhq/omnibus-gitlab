require_relative '../aws_helper.rb'

namespace :aws do

  desc "Perform operations related to AWS AMI"
  task :process do
    content = File.read('VERSION').chomp
    if content.include?('-rc')
      # We are not creating cloud images for RC releases.
      puts 'RC version found. Not building AWS image.'
    else
      match = AWSHelper::VERSION_REGEX.match(content)
      AWSHelper.new(match['version'], match['type']).process
    end
  end
end
