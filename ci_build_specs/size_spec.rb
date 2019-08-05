require File.join(__dir__, '../lib/gitlab/build/info.rb')
require File.join(__dir__, '../lib/gitlab/util.rb')

describe 'Package size' do
  let(:package_file) { Dir.glob('pkg/*/*.{rpm,deb}').first }
  let(:max_size) { Gitlab::Util.get_env('MAX_PACKAGE_SIZE_MB').to_i * 1024**2 }

  it 'is not too big' do
    new_size = File.stat(package_file).size
    error_message = <<-EOF
      "Generated package size would be #{new_size}, larger than the current limit of #{max_size}. If this is expected, please reach out to the distribution team about upping the limit."
    EOF
    expect(new_size).to be <= max_size, error_message
  end
end
