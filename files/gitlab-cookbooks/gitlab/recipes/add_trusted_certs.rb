#
# Copyright:: Copyright (c) 2016 GitLab Inc.
# License:: MIT
#
install_dir = node['package']['install-dir']
trusted_certs_dir = node['gitlab']['gitlab-rails']['trusted_certs_dir']
ssl_certs_directory =  File.join(install_dir, "embedded/ssl/certs")
readme_file = File.join(ssl_certs_directory, "README")
cacert_file = File.join(ssl_certs_directory, "cacert.pem")

cert_helper = CertificateHelper.new(trusted_certs_dir, ssl_certs_directory)

[
  trusted_certs_dir,
  ssl_certs_directory
].each do |directory_name|
   directory directory_name do
     recursive true
     mode "0755"
   end
end

file readme_file do
  mode "0644"
  content "This directory is managed by omnibus-gitlab.\n Any file placed in this directory will be ignored\n. Place certificates in #{trusted_certs_dir}.\n"
  notifies :run, 'ruby_block[copy-existing-certificates]', :before
end

# Copy existing certificate(s) into #{trusted_certs_dir}
ruby_block 'copy-existing-certificates' do
  block do
    puts "\n\nMoving existing certificates found in #{ssl_certs_directory}\n"
    cert_helper.move_existing_certificates
  end
  action :nothing
end

ruby_block 'create-certificate-symlinks' do
  block do
    puts "\n\Symlinking existing certificates found in #{trusted_certs_dir}\n"
    cert_helper.link_certificates
  end
  action :create
end
