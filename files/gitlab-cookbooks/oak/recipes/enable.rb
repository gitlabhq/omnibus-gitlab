include_recipe 'nginx::directory'

node['oak']['components'].each do |name, config|
  generate_nginx_conf = if node['gitlab']['nginx']['enable']
                          !!config['enable']
                        else
                          false
                        end

  nginx_configuration name do
    cookbook 'oak'
    variables(
      # lazy evaluate here since letsencrypt::enable sets redirect_http_to_https to true
      lazy do
        case name
        when 'openbao'
          node['gitlab']['nginx'].to_hash.merge(
            fqdn: config['fqdn'],
            listen_port: config['listen_port'],
            openbao_internal_url: config['internal_url'],
            https: config['https'],
            ssl_certificate: config['ssl_certificate'],
            ssl_certificate_key: config['ssl_certificate_key'],
            redirect_http_to_https: config['redirect_http_to_https'],
            letsencrypt_enable: node['letsencrypt']['enable']
          )
        else
          {}
        end
      end
    )
    action generate_nginx_conf ? 'create' : 'delete'
  end
end
