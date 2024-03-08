openssl_software_definition = if Gitlab::Util.get_env('OPENSSL_VERSION')&.start_with?("3")
                                File.join(Omnibus::Config.software_dir, 'openssl_3.rb')
                              else
                                File.join(Omnibus::Config.software_dir, 'openssl_1.rb')
                              end

instance_eval(IO.read(openssl_software_definition))
