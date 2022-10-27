module Consul
  class << self
    def parse_variables
      handle_deprecated_config
    end

    def handle_deprecated_config
      handle_deprecated_tls_config
      handle_renamed_acl_tokens_config
    end

    def handle_deprecated_tls_config
      return unless Gitlab['consul']['configuration']

      all_deprecated_tls_settings = %w[
        cert_file
        key_file
        ca_file
        ca_path
        tls_min_version
        tls_cipher_suites
        verify_incoming
        verify_incoming_rpc
        verify_incoming_https
        verify_outgoing
        verify_server_hostname
      ]

      deprecated_tls_settings = all_deprecated_tls_settings.reject { |setting| Gitlab['consul']['configuration'][setting].nil? }

      return if deprecated_tls_settings.empty?

      Gitlab['consul']['configuration']['tls'] ||= { 'defaults' => {} }

      deprecated_tls_settings.each do |setting|
        next unless Gitlab['consul']['configuration']['tls'][setting].nil?

        Gitlab['consul']['configuration']['tls']['defaults'][setting] = Gitlab['consul']['configuration'][setting]

        Gitlab['consul']['configuration'].delete(setting)

        # We can't use existing deprecation logic because we are deleting the
        # deprecated setting key from the configuration hash
        deprecation_msg = <<~EOS
        * `consul['configuration']['#{setting}']` has been deprecated since 15.5 and will be removed in 16.0. In GitLab 15.5 Consul version has been updated to 1.12.5, starting with which this setting has been moved to a different location. Hence, move this setting to `consul['configuration']['tls']['defaults']['#{setting}']`.
        EOS

        LoggingHelper.deprecation(deprecation_msg)
      end
    end

    def handle_renamed_acl_tokens_config
      return unless Gitlab['consul'].dig('configuration', 'acl', 'tokens')

      all_deprecated_acl_token_settings = {
        'master' => 'initial_management',
        'agent_master' => 'agent_recovery'
      }

      deprecated_actl_token_settings = all_deprecated_acl_token_settings.reject { |setting| Gitlab['consul']['configuration']['acl']['tokens'][setting].nil? }

      return if deprecated_actl_token_settings.empty?

      deprecated_actl_token_settings.each do |setting, replacement|
        Gitlab['consul']['configuration']['acl']['tokens'][replacement] ||= Gitlab['consul']['configuration']['acl']['tokens'][setting]

        Gitlab['consul']['configuration']['acl']['tokens'].delete(setting)

        # We can't use existing deprecation logic because we are deleting the
        # deprecated setting key from the configuration hash
        deprecation_msg = <<~EOS
        * `consul['configuration']['acl']['tokens']['#{setting}']` has been deprecated since 15.5 and will be removed in 16.0. In GitLab 15.5 Consul version has been updated to 1.12.5, starting with which this setting has been renamed. Hence, rename this setting to `consul['configuration']['acl']['tokens']['#{replacement}']`.
        EOS

        LoggingHelper.deprecation(deprecation_msg)
      end
    end
  end
end
