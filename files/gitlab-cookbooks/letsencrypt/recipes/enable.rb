site = URI(node['gitlab']['external-url']).host

node.default['gitlab']['nginx']['redirect_http_to_https'] = true

# If this is the first run, then nginx won't be working due to missing certificates
acme_selfsigned site do
  crt node['gitlab']['nginx']['ssl_certificate']
  key node['gitlab']['nginx']['ssl_certificate_key']
  chain node['letsencrypt']['chain']
  notifies :run, "execute[reload nginx]", :immediate
end

include_recipe "letsencrypt::#{node['letsencrypt']['authorization_method']}_authorization"

execute 'reload nginx' do
  command 'gitlab-ctl hup nginx'
  action :nothing
end

ruby 'display_le_message' do
  LoggingHelper.warning("Let's Encrypt has been configured. Please see http://foo for more information")
  action :nothing
end
