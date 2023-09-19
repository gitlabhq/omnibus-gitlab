class SentinelHelper
  MYID_PATTERN ||= /^[0-9a-f]{40}$/.freeze
  JSON_FILE ||= '/etc/gitlab/gitlab-sentinel.json'.freeze

  def initialize(node)
    @node = node
  end

  def myid
    if sentinel.key?('myid') && sentinel['myid']
      restore_from_node
    else
      restore_or_generate_from_file
    end
  end

  def use_hostnames
    # Detect if user is overriding what we want to calculate here
    return sentinel['use_hostnames'] ? 'yes' : 'no' unless sentinel['use_hostnames'].nil?

    return 'yes' if redis['announce_ip_from_hostname']

    # Enable hostnames if a non-IP address value is provided in announce_ip
    return 'yes' if sentinel['announce_ip'] && !Regexp.union([Resolv::IPv4::Regex, Resolv::IPv6::Regex]).match(sentinel['announce_ip'])

    'no'
  end

  def running_version
    return unless OmnibusHelper.new(@node).service_up?('sentinel')

    command = "/opt/gitlab/embedded/bin/redis-cli #{redis_cli_connect_options} INFO"
    env =
      if sentinel['password']
        { 'REDISCLI_AUTH' => sentinel['password'] }
      else
        {}
      end

    command_output = VersionHelper.version(command, env: env)

    raise "Execution of the command `#{command}` failed" unless command_output

    version_match = command_output.match(/redis_version:(?<redis_version>\d*\.\d*\.\d*)/)
    raise "Execution of the command `#{command}` generated unexpected output `#{command_output.strip}`" unless version_match

    version_match['redis_version']
  end

  def installed_version
    return unless OmnibusHelper.new(@node).service_up?('sentinel')

    command = '/opt/gitlab/embedded/bin/redis-sentinel --version'

    command_output = VersionHelper.version(command)
    raise "Execution of the command `#{command}` failed" unless command_output

    version_match = command_output.match(/Redis server v=(?<redis_version>\d*\.\d*\.\d*)/)
    raise "Execution of the command `#{command}` generated unexpected output `#{command_output.strip}`" unless version_match

    version_match['redis_version']
  end

  private

  # Restore from node definition (gitlab.rb)
  def restore_from_node
    raise 'Sentinel myid must be exactly 40 hex-characters lowercase' unless MYID_PATTERN.match?(sentinel['myid'])

    sentinel['myid']
  end

  # Restore from local JSON file or create a new myid
  def restore_or_generate_from_file
    existing_data = load_from_file
    if existing_data && existing_data['myid']
      existing_data['myid']
    else
      myid = generate_myid
      save_to_file({ 'myid' => myid })

      myid
    end
  end

  def sentinel
    @node['gitlab']['sentinel']
  end

  def redis
    @node['redis']
  end

  # Load from local JSON file
  def load_from_file
    Chef::JSONCompat.from_json(File.read(JSON_FILE)) if File.exist?(JSON_FILE)
  end

  # Save to local JSON file
  def save_to_file(data)
    return unless File.directory?('/etc/gitlab')

    File.open(JSON_FILE, 'w', 0600) do |f|
      f.puts(Chef::JSONCompat.to_json_pretty(data))
      f.chmod(0600) # update existing file
    end
  end

  def generate_myid
    SecureRandom.hex(20) # size will be n*2 -> 40 characters
  end

  def redis_cli_connect_options
    args = ["-h #{sentinel['bind']}"]
    port = sentinel['port'].to_i

    if port.zero?
      redis_cli_tls_options(args)
    else
      args << "-p #{port}"
    end

    args.join(' ')
  end

  def redis_cli_tls_options(args)
    tls_port = sentinel['tls_port'].to_i

    raise "No Sentinel port available: sentinel['port'] or sentinel['tls_port'] must be non-zero" if tls_port.zero?

    args << "--tls"
    args << "-p #{tls_port}"
    args << "--cacert '#{sentinel['tls_ca_cert_file']}'" if sentinel['tls_ca_cert_file']
    args << "--cacertdir '#{sentinel['tls_ca_cert_dir']}'" if sentinel['tls_ca_cert_dir']

    return unless client_certs_required?

    raise "Sentinel TLS client authentication requires sentinel['tls_cert_file'] and sentinel['tls_key_file'] options" unless client_cert_and_key_available?

    args << "--cert '#{sentinel['tls_cert_file']}'"
    args << "--key '#{sentinel['tls_key_file']}'"
  end

  def client_certs_required?
    sentinel['tls_auth_clients'] == 'yes'
  end

  def client_cert_and_key_available?
    sentinel['tls_cert_file'] && !sentinel['tls_cert_file'].empty? &&
      sentinel['tls_key_file'] && !sentinel['tls_key_file'].empty?
  end
end
