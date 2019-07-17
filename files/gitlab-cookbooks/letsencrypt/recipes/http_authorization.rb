site = URI(node['gitlab']['external-url']).host

omnibus_helper = OmnibusHelper.new(node)

letsencrypt_certificate site do
  crt node['gitlab']['nginx']['ssl_certificate']
  key node['gitlab']['nginx']['ssl_certificate_key']
  notifies :run, "execute[reload nginx]", :immediate
  notifies :run, 'ruby_block[display_le_message]'
  only_if { omnibus_helper.service_up?('nginx') }
end
