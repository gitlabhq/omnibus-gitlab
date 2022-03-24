postgresql_user 'md5_password' do
  # This is not a secret password:
  #   ruby -rdigest -e 'puts Digest::MD5.hexdigest("toomanysecrets" + "md5_password")'
  password 'e99b79fbdf9b997e6918df2385e60f5c'
end
