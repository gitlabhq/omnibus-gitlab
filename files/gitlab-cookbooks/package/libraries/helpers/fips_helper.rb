require 'openssl'

class FipsHelper
  def self.fips_ubuntu_22_or_newer?
    return false unless OpenSSL.fips_mode

    @ohai ||= Ohai::System.new.tap do |oh|
      oh.all_plugins(['platform'])
    end.data

    return false unless @ohai['platform'].casecmp('ubuntu').zero?

    @ohai['platform_version']&.split('.')&.first.to_i >= 22
  end
end
