site = URI(node['gitlab']['external-url'])

ruby_block 'http external-url' do
  block do
    LoggingHelper.warning("Let's Encrypt is enabled, but external_url is using http")
  end
  only_if { site.port == 80 }
end

# If we're using SSL, force http redirection to https
node.default['gitlab']['nginx']['redirect_http_to_https'] = true

include_recipe 'nginx::enable'

# We assume that the certificate and key will be stored in the same directory
ssl_dir = File.dirname(node['gitlab']['nginx']['ssl_certificate'])

directory ssl_dir do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# If this is the first run, then nginx won't be working due to missing certificates
acme_selfsigned site.host do
  alt_names node['letsencrypt']['alt_names']
  crt node['gitlab']['nginx']['ssl_certificate']
  key node['gitlab']['nginx']['ssl_certificate_key']
  notifies :restart, 'runit_service[nginx]', :immediately
end

include_recipe "letsencrypt::#{node['letsencrypt']['authorization_method']}_authorization"

if node['letsencrypt']['auto_renew']
  include_recipe "crond::enable"

  # We seed with the sha1 of the hostname, so we'll default with the same minute
  # until external_url changes
  chosen_minute = Random.new(Digest::SHA1.hexdigest(site.host).hex).rand(60)

  crond_job 'letsencrypt-renew' do
    user "root"
    hour node['letsencrypt']['auto_renew_hour']
    minute node['letsencrypt']['auto_renew_minute'] || chosen_minute
    day_of_month node['letsencrypt']['auto_renew_day_of_month']
    command "/opt/gitlab/bin/gitlab-ctl renew-le-certs"
  end
else
  crond_job 'letsencrypt-renew' do
    action :delete
  end
end

ruby_block 'display_le_message' do
  block do
    LoggingHelper.warning("Let's Encrypt integration does not setup any automatic renewal. Please see https://docs.gitlab.com/omnibus/settings/ssl.html#lets-encrypt-integration for more information") unless node['letsencrypt']['auto_renew']
  end
  action :nothing
end

ruby_block 'save_auto_enabled' do
  block do
    LetsEncrypt.save_auto_enabled
  end
end
