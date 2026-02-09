module RedisHelper
  class GitlabExporter < RedisHelper::Base
    def redis_params
      {
        url: redis_url,
        enable_client: enable_client,
        ssl_params: redis_ssl_params,
        sentinels: redis_sentinels,
        sentinels_password: redis_sentinels_password,
        sentinels_ssl: redis_sentinels_ssl,
        sentinels_tls_ca_cert_file: redis_sentinels_tls_ca_cert_file,
        sentinels_tls_client_cert_file: redis_sentinels_tls_client_cert_file,
        sentinels_tls_client_key_file: redis_sentinels_tls_client_key_file
      }
    end

    private

    def enable_client
      node_attr['redis_enable_client']
    end

    def redis_ssl_params
      return unless redis_ssl

      options = {}
      options[:ca_file] = redis_tls_ca_cert_file if redis_tls_ca_cert_file
      options[:cert] = redis_tls_client_cert_file if redis_tls_client_cert_file
      options[:key] = redis_tls_client_key_file if redis_tls_client_key_file
      options
    end

    # GitLab Exporter uses the same Redis information as GitLab Rails
    def node_access_keys
      %w[gitlab gitlab_rails]
    end

    def support_sentinel_groupname?
      true
    end
  end
end
