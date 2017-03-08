require 'openssl'

class SecretsHelper
  def self.generate_hex(chars)
    SecureRandom.hex(chars)
  end

  def self.generate_rsa(bits)
    OpenSSL::PKey::RSA.new(bits)
  end

  def self.read_gitlab_secrets
    existing_secrets ||= Hash.new

    if File.exists?("/etc/gitlab/gitlab-secrets.json")
      existing_secrets = Chef::JSONCompat.from_json(File.read("/etc/gitlab/gitlab-secrets.json"))
    end

    existing_secrets.each do |k, v|
      if Gitlab[k]
        v.each do |pk, p|
          # Note: Specifiying a secret in gitlab.rb will take precendence over "gitlab-secrets.json"
          Gitlab[k][pk] ||= p
        end
      else
        warn("Ignoring section #{k} in /etc/gitlab/giltab-secrets.json, does not exist in gitlab.rb")
      end
    end
  end

  def self.write_to_gitlab_secrets
    secret_tokens = {
      'gitlab_workhorse' => {
        'secret_token' => Gitlab['gitlab_workhorse']['secret_token'],
      },
      'gitlab_shell' => {
        'secret_token' => Gitlab['gitlab_shell']['secret_token'],
      },
      'gitlab_rails' => {
        'secret_key_base' => Gitlab['gitlab_rails']['secret_key_base'],
        'db_key_base' => Gitlab['gitlab_rails']['db_key_base'],
        'otp_key_base' => Gitlab['gitlab_rails']['otp_key_base'],
        'jws_private_key' => Gitlab['gitlab_rails']['jws_private_key']
      },
      'registry' => {
        'http_secret' => Gitlab['registry']['http_secret'],
        'internal_certificate' => Gitlab['registry']['internal_certificate'],
        'internal_key' => Gitlab['registry']['internal_key']

      },
      'mattermost' => {
        'email_invite_salt' => Gitlab['mattermost']['email_invite_salt'],
        'file_public_link_salt' => Gitlab['mattermost']['file_public_link_salt'],
        'email_password_reset_salt' => Gitlab['mattermost']['email_password_reset_salt'],
        'sql_at_rest_encrypt_key' => Gitlab['mattermost']['sql_at_rest_encrypt_key']
      }
    }

    if Gitlab['mattermost']['gitlab_enable']
      gitlab_oauth = {
        'gitlab_enable' => Gitlab['mattermost']['gitlab_enable'],
        'gitlab_secret' => Gitlab['mattermost']['gitlab_secret'],
        'gitlab_id' => Gitlab['mattermost']['gitlab_id'],
        'gitlab_scope' => Gitlab['mattermost']['gitlab_scope'],
        'gitlab_auth_endpoint' => Gitlab['mattermost']['gitlab_auth_endpoint'],
        'gitlab_token_endpoint' => Gitlab['mattermost']['gitlab_token_endpoint'],
        'gitlab_user_api_endpoint' => Gitlab['mattermost']['gitlab_user_api_endpoint']
      }
      secret_tokens['mattermost'].merge!(gitlab_oauth)
    end

    if File.directory?('/etc/gitlab')
      File.open('/etc/gitlab/gitlab-secrets.json', 'w', 0600) do |f|
        f.puts(Chef::JSONCompat.to_json_pretty(secret_tokens))
        f.chmod(0600)
      end
    end
  end
end
