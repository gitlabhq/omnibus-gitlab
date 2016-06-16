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
    keep_files_array = Array.new
    keep_files_array << "#{install_dir}/embedded/ssl/certs/cacert.pem"
    keep_files_array << "#{install_dir}/embedded/ssl/certs/README"

    Dir.glob("#{trusted_certs_dir}/*") do |trusted_cert|
      if cert_helper.is_x509_certificate?(trusted_cert)
        certificate = OpenSSL::X509::Certificate.new(File.read(trusted_cert))
        hash_value = certificate.subject.hash.to_s(16)

        for i in 0..9
          symlink_path_i = "#{install_dir}/embedded/ssl/certs/#{hash_value}.#{i}"
          if File.exist?(symlink_path_i) then
            if File.realpath(symlink_path_i).to_s == trusted_cert.to_s
              keep_files_array << symlink_path_i
              break
            end
          else
            keep_files_array << symlink_path_i
            FileUtils.ln_s trusted_cert, symlink_path_i
            break
          end
        end
      else
        cert_helper.notify_and_raise(trusted_certs_dir)
      end
    end

    # remove any additional files in dir
    Dir.glob("#{install_dir}/embedded/ssl/certs/*") do |certs_file|
      File.delete(certs_file) if not keep_files_array.include? certs_file
    end
  end
  action :create
end
