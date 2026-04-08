module GitlabSshd
  class << self
    def parse_variables
      validate_trusted_user_ca_keys
    end

    def validate_trusted_user_ca_keys
      keys = Gitlab['gitlab_sshd']['trusted_user_ca_keys']
      return if keys.nil?

      raise "gitlab_sshd['trusted_user_ca_keys'] must be an Array" unless keys.is_a?(Array)
    end
  end
end
