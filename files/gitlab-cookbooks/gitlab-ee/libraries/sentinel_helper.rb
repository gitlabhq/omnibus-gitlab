class SentinelHelper
  MYID_PATTERN ||= /^[0-9a-f]{40}$/
  JSON_FILE ||= '/etc/gitlab/gitlab-sentinel.json'.freeze

  def initialize(node)
    @node = node
  end

  def myid
    if sentinel['myid']
      restore_from_node
    else
      restore_or_generate_from_file
    end
  end

  private

  # Restore from node definition (gitlab.rb)
  def restore_from_node
    unless MYID_PATTERN.match?(sentinel['myid'])
      raise 'Sentinel myid must be exactly 40 hex-characters lowercase'
    end

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
end
