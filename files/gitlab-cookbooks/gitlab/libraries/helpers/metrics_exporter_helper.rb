module MetricsExporterHelper
  def check_consistent_exporter_tls_settings(target)
    return unless metrics_enabled? && metrics_tls_enabled?

    %w(exporter_tls_cert_path exporter_tls_key_path).each do |required_setting|
      raise "#{target.capitalize} exporter_tls_enabled is true, but #{required_setting} is not set" unless user_config_or_default(required_setting)
    end
  end

  def metrics_tls_enabled?
    user_config_or_default('exporter_tls_enabled')
  end

  def user_config_or_default(key)
    # Note that we must not use an `a || b`` truthiness check here since that would mean a `false`
    # user setting would fail over to the default, which is not what we want.
    user_config[key].nil? ? default_config[key] : user_config[key]
  end
end
