require 'openssl'

class SecretsHelper
  def self.generate_hex(chars)
    SecureRandom.hex(chars)
  end

  def self.generate_base64(bytes)
    SecureRandom.base64(bytes)
  end

  def self.generate_urlsafe_base64(bytes = 32)
    SecureRandom.urlsafe_base64(bytes)
  end

  def self.generate_rsa(bits)
    OpenSSL::PKey::RSA.new(bits)
  end

  def self.generate_x509(subject:, validity:, key:)
    cert = OpenSSL::X509::Certificate.new
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
    cert.not_before = Time.now
    cert.not_after = (DateTime.now + validity).to_time
    cert.public_key = key.public_key
    cert.serial = 0x0
    cert.version = 2
    cert.sign(key, OpenSSL::Digest.new('SHA256'))

    cert
  end

  def self.generate_keypair(bits:, subject:, validity:)
    key = generate_rsa(bits)
    cert = generate_x509(subject: subject, validity: validity, key: key)

    [key, cert]
  end

  # Load the secrets from disk
  #
  # @return [Hash]  empty if no secrets
  def self.load_gitlab_secrets
    existing_secrets = {}

    existing_secrets = Chef::JSONCompat.from_json(File.read("/etc/gitlab/gitlab-secrets.json")) if File.exist?("/etc/gitlab/gitlab-secrets.json")

    existing_secrets
  end

  # Reads the secrets into the Gitlab config singleton
  def self.read_gitlab_secrets
    existing_secrets = load_gitlab_secrets

    existing_secrets.each do |k, v|
      if Gitlab[k]
        v.each do |pk, p|
          # Note: Specifying a secret in gitlab.rb will take precedence over "gitlab-secrets.json"
          Gitlab[k][pk] ||= p
        end
      else
        warn("Ignoring section #{k} in /etc/gitlab/gitlab-secrets.json, does not exist in gitlab.rb")
      end
    end
  end

  def self.gather_gitlab_secrets # rubocop:disable Metrics/AbcSize
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
        'encrypted_settings_key_base' => Gitlab['gitlab_rails']['encrypted_settings_key_base'],
        'openid_connect_signing_key' => Gitlab['gitlab_rails']['openid_connect_signing_key'],
        'ci_jwt_signing_key' => Gitlab['gitlab_rails']['ci_jwt_signing_key']
      },
      'gitlab_pages' => {
        'gitlab_secret' => Gitlab['gitlab_pages']['gitlab_secret'],
        'gitlab_id' => Gitlab['gitlab_pages']['gitlab_id'],
        'auth_secret' => Gitlab['gitlab_pages']['auth_secret'],
        'api_secret_key' => Gitlab['gitlab_pages']['api_secret_key'],
        'register_as_oauth_app' => Gitlab['gitlab_pages']['register_as_oauth_app']
      },
      'gitlab_kas' => {
        'api_secret_key' => Gitlab['gitlab_kas']['api_secret_key'],
        'private_api_secret_key' => Gitlab['gitlab_kas']['private_api_secret_key']
      },
      'suggested_reviewers' => {
        'api_secret_key' => Gitlab['suggested_reviewers']['api_secret_key']
      },
      'grafana' => {
        'secret_key' => Gitlab['grafana']['secret_key'],
        'gitlab_secret' => Gitlab['grafana']['gitlab_secret'],
        'gitlab_application_id' => Gitlab['grafana']['gitlab_application_id'],
        'admin_password' => Gitlab['grafana']['admin_password'],
        'metrics_basic_auth_password' => Gitlab['grafana']['metrics_basic_auth_password'],
        'register_as_oauth_app' => Gitlab['grafana']['register_as_oauth_app']
      },
      'registry' => {
        'http_secret' => Gitlab['registry']['http_secret'],
        'internal_certificate' => Gitlab['registry']['internal_certificate'],
        'internal_key' => Gitlab['registry']['internal_key']
      },
      'letsencrypt' => {
        'auto_enabled' => Gitlab['letsencrypt']['auto_enabled']
      },
      'mattermost' => {
        'email_invite_salt' => Gitlab['mattermost']['email_invite_salt'],
        'file_public_link_salt' => Gitlab['mattermost']['file_public_link_salt'],
        'sql_at_rest_encrypt_key' => Gitlab['mattermost']['sql_at_rest_encrypt_key'],
        'register_as_oauth_app' => Gitlab['mattermost']['register_as_oauth_app']
      },
      'postgresql' => {
        'internal_certificate' => Gitlab['postgresql']['internal_certificate'],
        'internal_key' => Gitlab['postgresql']['internal_key']
      },
      'mailroom' => {
        'incoming_email_auth_token' => Gitlab['mailroom']['incoming_email_auth_token'],
        'service_desk_email_auth_token' => Gitlab['mailroom']['service_desk_email_auth_token'],
      },
    }

    if Gitlab['mattermost']['gitlab_enable']
      gitlab_oauth = {
        'gitlab_enable' => Gitlab['mattermost']['gitlab_enable'],
        'gitlab_secret' => Gitlab['mattermost']['gitlab_secret'],
        'gitlab_id' => Gitlab['mattermost']['gitlab_id'],
      }
      secret_tokens['mattermost'].merge!(gitlab_oauth)
    end

    secret_tokens
  end

  def self.write_to_gitlab_secrets
    secret_tokens = gather_gitlab_secrets

    if File.directory?('/etc/gitlab')
      File.open('/etc/gitlab/gitlab-secrets.json', 'w', 0600) do |f|
        f.puts(Chef::JSONCompat.to_json_pretty(secret_tokens))
        f.chmod(0600)
      end
    end

    nil
  end
end
