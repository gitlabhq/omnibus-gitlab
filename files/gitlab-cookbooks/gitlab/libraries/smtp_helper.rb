# frozen_string_literal: true

class SmtpHelper
  def self.validate_smtp_settings!(rails_config)
    return unless rails_config['smtp_enable']
    return unless rails_config['smtp_tls'] && rails_config['smtp_enable_starttls_auto']

    raise "gitlab_rails['smtp_tls'] and gitlab_rails['smtp_enable_starttls_auto'] are mutually exclusive." \
          " Set one of them to false. SMTP providers usually use port 465 for TLS and port 587 for STARTTLS."
  end
end
