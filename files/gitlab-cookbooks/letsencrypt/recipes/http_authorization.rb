site = URI(node['gitlab']['external-url']).host

letsencrypt_certificate site do
  fullchain node['gitlab']['nginx']['ssl_certificate']
  key node['gitlab']['nginx']['ssl_certificate_key']
  notifies :run, "execute[reload nginx]", :immediate
  notifies :run, 'ruby_block[display_le_message]'
end
