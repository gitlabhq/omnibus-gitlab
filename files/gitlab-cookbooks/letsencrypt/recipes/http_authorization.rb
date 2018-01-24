site = URI(node['gitlab']['external-url']).host

letsencrypt_certificate site do
  alt_names node['letsencrypt']['alt_names']
  key_size node['letsencrypt']['key_size']
  fullchain node['letsencrypt']['fullchain']
  group node['letsencrypt']['group']
  crt node['gitlab']['nginx']['ssl_certificate']
  key node['gitlab']['nginx']['ssl_certificate_key']
  chain node['letsencrypt']['chain']
  contact node['letsencrypt']['contact']
  wwwroot node['letsencrypt']['wwwroot']
  notifies :run, "execute[reload nginx]", :immediate
  notifies :run, 'ruby_block[display_le_message]'
end
