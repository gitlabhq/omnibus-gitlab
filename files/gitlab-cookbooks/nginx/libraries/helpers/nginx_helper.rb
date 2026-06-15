module OmnibusGitlab
  class NginxHelper
    def initialize(node)
      @node = node
    end

    def nginx_dir
      @node['nginx']['dir']
    end

    def conf_dir
      File.join(nginx_dir, "conf")
    end

    def service_conf_dir
      File.join(conf_dir, "service_conf")
    end

    def upstream_definition_dir
      File.join(conf_dir, "upstream_definitions")
    end

    def extra_metrics_dir
      File.join(conf_dir, "extra_metrics_conf")
    end

    def service_conf_path(service, suffix: "conf")
      File.join(service_conf_dir, "gitlab-#{service}.#{suffix}")
    end

    def upstream_definition_conf_path(service)
      File.join(upstream_definition_dir, "#{service}.conf")
    end

    def extra_metrics_conf_path(service)
      File.join(extra_metrics_dir, "#{service}.conf")
    end

    def default_values
      {
        'client_max_body_size' => 0,
        'custom_gitlab_server_config' => nil,
        'dir' => "/var/opt/gitlab/nginx",
        'error_log_level' => "error",
        'gzip_comp_level' => "2",
        'gzip_enabled' => true,
        'gzip_http_version' => "1.1",
        'gzip_proxied' => "no-cache no-store private expired auth",
        'gzip_types' => [
          "text/plain",
          "text/css",
          "application/x-javascript",
          "text/xml",
          "application/xml",
          "application/xml+rss",
          "text/javascript",
          "application/json"
        ],
        'hsts_include_subdomains' => false,
        'hsts_max_age' => 63072000,
        'http2_enabled' => true,
        'listen_addresses' => ['*'],
        'listen_https' => nil,
        'listen_port' => nil,
        'log_directory' => "/var/log/gitlab/nginx",
        'proxy_cache' => 'gitlab',
        'proxy_connect_timeout' => 300,
        'proxy_custom_buffer_size' => nil,
        'proxy_protocol' => false,
        'proxy_read_timeout' => 3600,
        'proxy_set_headers' => {
          "Host" => "$http_host_with_default",
          "X-Real-IP" => "$remote_addr",
          "X-Forwarded-For" => "$remote_addr",
          "Upgrade" => "$http_upgrade",
          "Connection" => "$connection_upgrade"
        },
        'real_ip_header' => nil,
        'real_ip_recursive' => nil,
        'real_ip_trusted_addresses' => [],
        'redirect_http_to_https' => false,
        'redirect_http_to_https_port' => 80,
        'referrer_policy' => 'strict-origin-when-cross-origin',
        'request_buffering_off_path_regex' => "/api/v\\d/jobs/\\d+/artifacts$|/import/gitlab_project$|\\.git/git-receive-pack$|\\.git/ssh-receive-pack$|\\.git/ssh-upload-pack$|\\.git/gitlab-lfs/objects|\\.git/info/lfs/objects/batch$",
        'ssl_certificate' => "/etc/gitlab/ssl/#{@node['fqdn']}.crt",
        'ssl_certificate_key' => "/etc/gitlab/ssl/#{@node['fqdn']}.key",
        'ssl_ciphers' => "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
        'ssl_client_certificate' => nil,
        'ssl_conf_command' => nil,
        'ssl_dhparam' => nil,
        'ssl_ecdh_curve' => nil,
        'ssl_password_file' => nil,
        'ssl_prefer_server_ciphers' => "off",
        'ssl_protocols' => "TLSv1.2 TLSv1.3",
        'ssl_session_cache' => "shared:SSL:10m",
        'ssl_session_tickets' => "off",
        'ssl_session_timeout' => "1d",
        'ssl_verify_client' => nil,
        'ssl_verify_depth' => "1"
      }
    end
  end
end
