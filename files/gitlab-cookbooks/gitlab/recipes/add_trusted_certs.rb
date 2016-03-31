# add_trusted_certs.rb

cert_helper = CertificateHelper.new

install_dir = node['package']['install-dir']
trusted_certs_dir = node['gitlab']['gitlab-rails']['trusted_certs_dir']


directory "#{trusted_certs_dir}" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end


directory "#{install_dir}/embedded/ssl/certs" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end


file "#{install_dir}/embedded/ssl/certs/README" do
  owner "root"
  group "root"
  mode "0644"
  content "This directory is managed by omnibus-gitlab. Put certificates you want to add to the store in #{trusted_certs_dir}.\n"
  notifies :run, 'ruby_block[move-existing-certificates]', :before
end


ruby_block 'move-existing-certificates' do
  # move existing certificate(s) into #{trusted_certs_dir}
  block do
    puts "\nPerform (one time) move of certificates existing in #{install_dir}/embedded/ssl/certs/"
    # use glob to get Array of all files
    # - "cacert.pem" -> ignore
    # - "README" -> ignore
    # - if symlink:
    #   - if pointing to #{trusted_certs_dir} -> ignore
    #   - else
    #     - if pointing to non certificate file -> fail
    #     - else
    #       -> copy certificate to #{trusted_certs_dir}
    # - else (not symlink)
    #   - if not valid certifcate -> fail
    #   - else
    #     -> copy certificate to #{trusted_certs_dir}
    Dir.glob("#{install_dir}/embedded/ssl/certs/*") do |file|
      if file == "#{install_dir}/embedded/ssl/certs/cacert.pem"
        next
      elsif file == "#{install_dir}/embedded/ssl/certs/README"
        next
      elsif File.symlink?(file)
        if File.realpath(file).start_with?("#{trusted_certs_dir}")
          next
        else
          if !cert_helper.is_x509_certificate?(file)
            puts "ERROR: Not a certificate: #{file} -> #{File.realpath(file)}"
            puts "=====\n"
            raise
          else
            FileUtils.cp(File.realpath(file), trusted_certs_dir)
          end
        end
      else
        if !cert_helper.is_x509_certificate?(file)
          puts "ERROR: Not a certificate: #{file}"
          puts "=====\n"
          raise
        else
          FileUtils.cp(file, trusted_certs_dir)
        end
      end
    end
  end
  action :nothing
end

ruby_block 'create-certificate-symlinks' do
  block do
    keep_files_array = Array.new
    keep_files_array << "#{install_dir}/embedded/ssl/certs/cacert.pem"
    keep_files_array << "#{install_dir}/embedded/ssl/certs/README"

    Dir.glob("#{trusted_certs_dir}/*") do |trusted_cert|
      if !cert_helper.is_x509_certificate?(trusted_cert)
        puts "ERROR: Not a x509 certificate: #{trusted_cert}"
        puts "=====\n"
        raise
      else
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
      end
    end

    # remove any additional files in dir
    Dir.glob("#{install_dir}/embedded/ssl/certs/*") do |certs_file|
      File.delete(certs_file) if not keep_files_array.include? certs_file
    end
  end
  action :create
end

