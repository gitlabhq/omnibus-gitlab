site = URI(node['gitlab']['external-url']).host

letsencrypt_certificate site do
  crt node['gitlab']['nginx']['ssl_certificate']
  key node['gitlab']['nginx']['ssl_certificate_key']
  chain node['letsencrypt']['chain']
  wwwroot node['letsencrypt']['wwwroot']
  notifies :run, "execute[reload nginx]", :immediate
  notifies :run, 'ruby[display_le_message]'
end
