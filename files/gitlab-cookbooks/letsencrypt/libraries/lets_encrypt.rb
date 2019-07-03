# Copyright:: Copyright (c) 2018 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class LetsEncrypt
  class << self
    def parse_variables
      parse_enable
    end

    # Munge the enable parameter
    #
    # @return [void]
    def parse_enable
      # default for letsencrypt.enable is nil.  If a user has specified anything
      # else leave it alone.
      return unless Gitlab['letsencrypt']['enable'].nil?

      # We get to make a 'guess' as to if we should enable based on other parsed
      # values
      Gitlab['letsencrypt']['enable'] = should_auto_enable?

      # Remember if we auto-enabled, for later runs.  Persisted as a secret
      Gitlab['letsencrypt']['auto_enabled'] = Gitlab['letsencrypt']['enable'] == true
    end

    # Should we enable the recipe even if a user didn't specify it?
    #
    # @return [true, false]
    def should_auto_enable?
      (
        Gitlab['gitlab_rails']['gitlab_https'] &&
        [
          Gitlab['nginx']['enable'],
          Gitlab[:node]['gitlab']['nginx']['enable'],
          true
        ].find { |e| !e.nil? } && (
          Gitlab['nginx']['listen_https'].nil? ||
          Gitlab['nginx']['listen_https']
        ) && (
          Gitlab['letsencrypt']['auto_enabled'] || (
            !File.exist?(Gitlab['nginx']['ssl_certificate_key']) &&
            !File.exist?(Gitlab['nginx']['ssl_certificate'])
          ) || needs_renewal?
        )
      )
    end

    # Save secrets if they do not have letsencrypt.auto_enabled
    #
    # @return [void]
    def save_auto_enabled
      return unless Gitlab['letsencrypt']['auto_enabled']

      secrets = SecretsHelper.load_gitlab_secrets

      # Avoid writing if the attribute is there and true
      return if secrets.dig('letsencrypt', 'auto_enabled')
      SecretsHelper.write_to_gitlab_secrets
    end

    private

    LETSENCRYPT_ISSUER = %(/C=US/O=Let's Encrypt/CN=Let's Encrypt Authority X3).freeze

    # Checks wheather the existing Let's Encrypt certificate is expired and needs renewal.
    #
    # @return [true, false]
    def needs_renewal?
      file_name = Gitlab['nginx']['ssl_certificate']
      return false unless File.exist? file_name

      cert = OpenSSL::X509::Certificate.new File.read(file_name)
      cert.issuer.to_s == LETSENCRYPT_ISSUER && cert.not_after < Time.now
    end
  end
end
