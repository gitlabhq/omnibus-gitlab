class GitlabSshdHelper
  OMNIBUS_KEYS = %w[enable dir generate_host_keys log_directory env_directory host_keys_dir host_keys_glob host_certs_dir host_certs_glob].freeze

  def initialize(node)
    @node = node
  end

  # This returns the configuration needed to start gitlab-sshd inside the gitlab-shell
  # configuration file.
  #
  # We purposely don't memoize this call since find_host_keys! and find_host_certs!
  # may change if new host keys are created.
  def json_config
    config = @node['gitlab']['gitlab_sshd'].dup

    find_host_keys!(config)
    find_host_certs!(config)

    config['listen'] = config.delete('listen_address')
    config['web_listen'] = config.delete('metrics_address')
    OMNIBUS_KEYS.each { |key| config.delete(key) }

    config
  end

  def no_host_keys?
    json_config['host_key_files'].empty?
  end

  private

  def find_host_keys!(config)
    host_keys_dir = config['host_keys_dir']
    host_keys_glob = config['host_keys_glob']

    return unless host_keys_glob && host_keys_dir

    path = File.join(host_keys_dir, host_keys_glob)

    host_keys = Dir[path]
    config['host_key_files'] = host_keys
  end

  def find_host_certs!(config)
    host_certs_dir = config['host_certs_dir']
    host_certs_glob = config['host_certs_glob']

    return unless host_certs_glob && host_certs_dir

    path = File.join(host_certs_dir, host_certs_glob)

    host_certs = Dir[path]
    config['host_key_certs'] = host_certs
  end
end
