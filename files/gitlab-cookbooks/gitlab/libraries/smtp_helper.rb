# frozen_string_literal: true

class SmtpHelper
  # Values that mean "no SMTP authentication". net-smtp 0.5.x raises an
  # ArgumentError on any truthy authtype that is not a known SASL mechanism,
  # so these must be normalized to nil rather than rendered as symbols like
  # :false or :none.
  DISABLED_AUTHENTICATION_VALUES = %w[false none].freeze

  # SASL mechanisms recognised by net-smtp. Any other non-empty, non-disabled
  # value is rejected at reconfigure time so the user gets a clear error
  # message rather than a cryptic ArgumentError when GitLab tries to send mail.
  VALID_AUTHENTICATION_MECHANISMS = %w[login plain cram_md5].freeze

  # Normalizes gitlab_rails['smtp_authentication'] so the template can render
  # it directly: nil when authentication is disabled, otherwise the configured
  # mechanism left untouched.  Raises if the value is not a recognised
  # mechanism and not a disabled/falsey value.
  def self.parse_smtp_authentication!(rails_config)
    value = rails_config['smtp_authentication']
    return if value.nil?

    normalized = value.to_s.downcase
    if normalized.empty? || DISABLED_AUTHENTICATION_VALUES.include?(normalized)
      rails_config['smtp_authentication'] = nil
    elsif !VALID_AUTHENTICATION_MECHANISMS.include?(normalized)
      raise "gitlab_rails['smtp_authentication'] is set to an unrecognized value: #{value.inspect}. " \
            "Valid mechanisms are: #{VALID_AUTHENTICATION_MECHANISMS.join(', ')}. " \
            "Set it to false or 'none' to disable SMTP authentication."
    end
  end

  def self.validate_smtp_settings!(rails_config)
    return unless rails_config['smtp_enable']
    return unless rails_config['smtp_tls'] && rails_config['smtp_enable_starttls_auto']

    raise "gitlab_rails['smtp_tls'] and gitlab_rails['smtp_enable_starttls_auto'] are mutually exclusive." \
          " Set one of them to false. SMTP providers usually use port 465 for TLS and port 587 for STARTTLS."
  end
end
