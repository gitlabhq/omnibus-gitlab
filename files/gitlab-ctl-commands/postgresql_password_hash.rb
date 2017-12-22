require "#{base_path}/embedded/service/omnibus-ctl/lib/postgresql/password_hash"

add_command_under_category('pg-password-md5', 'database', 'Generate MD5 Hash of user password in PostgreSQL format', 2) do |_cmd, user|
  PostgreSQL::PasswordHash.new(user).generate_md5_hash
end
