#
# Copyright:: Copyright (c) 2016 GitLab Inc.
# License:: MIT
#
omnibus_helper = OmnibusHelper.new(node)
install_dir = node['package']['install-dir']
trusted_certs_dir = node['gitlab']['gitlab-rails']['trusted_certs_dir']
ssl_certs_dir = File.join(install_dir, "embedded/ssl/certs")
user_dir = node['gitlab']['user']['home']
readme_file = File.join(ssl_certs_dir, "README")

cert_helper = CertificateHelper.new(trusted_certs_dir, ssl_certs_dir, user_dir)

[
  trusted_certs_dir,
  ssl_certs_dir
].each do |directory_name|
  directory directory_name do
    recursive true
    mode "0755"
  end
end

file readme_file do
  mode "0644"
  content "This directory is managed by omnibus-gitlab.\n Any file placed in this directory will be ignored\n. Place certificates in #{trusted_certs_dir}.\n"
end

ruby_block "Move existing certs and link to #{ssl_certs_dir}" do
  block do
    puts "\n\n  * Moving existing certificates found in #{ssl_certs_dir}\n"
    cert_helper.move_existing_certificates
    puts "\n  * Symlinking existing certificates found in #{trusted_certs_dir}\n"
    cert_helper.link_certificates
  end
  only_if { cert_helper.new_certificate_added? }
  notifies :restart, "service[unicorn]" if omnibus_helper.should_notify?("unicorn")
  notifies :restart, "service[puma]" if omnibus_helper.should_notify?("puma")
  notifies :restart, "service[gitlab-pages]" if omnibus_helper.should_notify?("gitlab-pages")
end
