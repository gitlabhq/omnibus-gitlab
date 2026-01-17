module RedisHelper
  class GitlabWorkhorse < RedisHelper::Base
    def redis_params
      {
        url: redis_url.to_s,
        password: redis_credentials[:password],
        sentinels: sentinel_urls,
        sentinelMaster: master_name,
        sentinelPassword: redis_sentinels_password,
        sentinelTLS: redis_sentinels_ssl,
        sentinelTLSOptions: sentinel_tls_options,
        redisTLS: redis_tls_options
      }
    end

    private

    def node_access_keys
      %w[gitlab gitlab_workhorse]
    end

    def support_sentinel_groupname?
      true
    end

    def sentinel_tls_options
      return unless redis_sentinels_ssl

      options = {}
      options[:certificate] = redis_sentinels_tls_client_cert_file if redis_sentinels_tls_client_cert_file
      options[:key] = redis_sentinels_tls_client_key_file if redis_sentinels_tls_client_key_file
      options[:ca_certificate] = redis_sentinels_tls_ca_cert_file if redis_sentinels_tls_ca_cert_file
      options
    end

    def redis_tls_options
      return unless redis_ssl

      options = {}
      options[:certificate] = redis_tls_client_cert_file if redis_tls_client_cert_file
      options[:key] = redis_tls_client_key_file if redis_tls_client_key_file
      options[:ca_certificate] = redis_tls_ca_cert_file if redis_tls_ca_cert_file
      options
    end

    def redis_tls_client_cert_file
      node_attr['redis_tls_client_cert_file']
    end

    def redis_tls_client_key_file
      node_attr['redis_tls_client_key_file']
    end

    def redis_tls_ca_cert_file
      node_attr['redis_tls_ca_cert_file']
    end
  end
end
