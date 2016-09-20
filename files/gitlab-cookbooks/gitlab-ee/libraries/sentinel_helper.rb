class SentinelHelper
  MYID_PATTERN = /^[0-9a-f]{40}$/
  JSON_FILE = '/etc/gitlab/gitlab-sentinel.json'

  def initialize(node)
    @node = node
  end

  def myid
    sentinel = @node['gitlab']['sentinel']

    if sentinel['myid']
      unless MYID_PATTERN =~ sentinel['myid']
        Chef::Log.warn 'Sentinel myid must be exactly 40 hex-characters lowercase'
      end

      sentinel['myid']
    else
      existing_data = load
      if existing_data && existing_data['myid']
        existing_data['myid']
      else
        myid = generate_myid
        save({'myid' => myid})

        myid
      end
    end
  end

  private

  def load
    if File.exists?(JSON_FILE)
      Chef::JSONCompat.from_json(File.read(JSON_FILE))
    end
  end

  def save(data)
    if File.directory?('/etc/gitlab')
      File.open(JSON_FILE, 'w') do |f|
        f.puts(
          Chef::JSONCompat.to_json_pretty(data)
        )
        system("chmod 0600 #{JSON_FILE}")
      end
    end
  end

  def generate_myid
    SecureRandom::hex(20) # size will be n*2 -> 40 characters
  end
end
