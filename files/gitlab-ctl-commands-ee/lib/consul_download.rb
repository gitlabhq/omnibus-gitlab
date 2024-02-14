require 'net/http'
require 'zip'

class ConsulDownloadCommand
  # This version should be keep in sync with consul versions in
  # software/consul.rb and consul_helper.rb.
  DEFAULT_VERSION = '1.16.5'.freeze

  def initialize(args)
    @args = args
    @options = {
      version: DEFAULT_VERSION,
      architecture: default_architecture,
      output: '/usr/local/bin/consul',
      force: false,
    }

    parse_options!
  end

  def run
    if !@options[:force] && File.exist?(@options[:output])
      warn("Consul binary already exists! Use --force to overwrite #{@options[:output]}.")
      return
    end

    response = Net::HTTP.get_response(download_url)

    if response.code != '200'
      warn("Error downloading consul from #{download_url}: #{resp.code}")
      return
    end

    Zip::File.open_buffer(StringIO.new(response.body)) do |zipio|
      zipio.each do |entry|
        next unless entry.file? && entry.name == 'consul'

        File.write(@options[:output], entry.get_input_stream.read)
        File.chmod(0755, @options[:output])
        puts "Successfully downloaded Consul #{@options[:version]} to #{@options[:output]}."
        puts "Start using the external Consul by setting consul['binary_path'] = '#{@options[:output]}' in your `gitlab.rb` and run `gitlab-ctl reconfigure`"
      end
    end
  end

  private

  def parse_options!
    opts_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: gitlab-ctl consul download [options]'

      opts.on('-v', '--version=VERSION', 'Version of the consul binary to be downloaded') do |v|
        @options[:version] = v
      end

      opts.on('-a', '--arch=ARCHITECTURE', 'Architecture of the consul binary to be downloaded') do |v|
        @options[:architecture] = v
      end

      opts.on('-o', '--output=PATH', 'Path to write the consul binary to') do |v|
        @options[:output] = v
      end

      opts.on('-f', '--force', 'Overwrite existing consul binary') do |v|
        @options[:force] = v
      end

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end

    opts_parser.parse!(@args.dup)
  end

  def download_url
    URI.parse("https://releases.hashicorp.com/consul/#{@options[:version]}/consul_#{@options[:version]}_linux_#{@options[:architecture]}.zip")
  end

  def default_architecture
    GitlabCtl::Util.get_node_attributes.dig('kernel', 'machine') || 'amd64'
  end
end
