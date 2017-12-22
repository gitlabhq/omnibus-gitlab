require 'io/console'

class PostgreSQL
  class PasswordHash
    def initialize(user)
      @user = user
    end

    def generate_md5_hash
      if @user.nil? || @user.empty?
        puts 'You must inform the username for which the password will be encrypted.'
        puts 'PostgreSQL encryption algorithm is salted with the user.'
        exit 1
      end

      puts password_hash(@user, GitlabCtl::Util.get_password)
    end

    private

    def password_hash(db_user, db_pass)
      Digest::MD5.hexdigest("#{db_pass}#{db_user}")
    end
  end
end
