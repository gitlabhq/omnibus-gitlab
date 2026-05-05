# Copyright:: Copyright (c) 2026 GitLab Inc.
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

require 'uri'

module Oak
  module OpenBao
    class << self
      def parse_variables
        return unless Oak.enabled?
        return unless component_enabled?

        validate_external_url
        parse_external_url
        validate_internal_url
        parse_ssl if https?
        parse_rails_openbao_urls
      end

      def component_enabled?
        !!Gitlab['oak']['components']&.dig('openbao', 'enable')
      end

      private

      def https?
        !!Gitlab['oak']['components']['openbao']['https']
      end

      def parse_external_url
        uri = URI(Gitlab['oak']['components']['openbao']['external_url'].to_s)

        raise "OAK OpenBao external URL must include a scheme and FQDN, " \
          "such as http://openbao.example.com" unless uri.host

        Gitlab['oak']['components']['openbao']['fqdn'] ||= uri.host
        Gitlab['oak']['components']['openbao']['listen_port'] ||= uri.port
        Gitlab['oak']['components']['openbao']['https'] ||= (uri.scheme == 'https')
      end

      def parse_ssl
        fqdn = Gitlab['oak']['components']['openbao']['fqdn']

        Gitlab['oak']['components']['openbao']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{fqdn}.crt"
        Gitlab['oak']['components']['openbao']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{fqdn}.key"

        parse_letsencrypt(fqdn)
      end

      def parse_letsencrypt(fqdn)
        return unless Gitlab['letsencrypt']['enable']
        return unless Gitlab['external_url']
        return if ::File.exist?(Gitlab['oak']['components']['openbao']['ssl_certificate'].to_s)

        external_uri = URI(Gitlab['external_url'])

        Gitlab['letsencrypt']['alt_names'] ||= []
        Gitlab['letsencrypt']['alt_names'] |= [external_uri.host, fqdn]

        Gitlab['oak']['components']['openbao']['ssl_certificate'] = "/etc/gitlab/ssl/#{external_uri.host}.crt"
        Gitlab['oak']['components']['openbao']['ssl_certificate_key'] = "/etc/gitlab/ssl/#{external_uri.host}.key"

        return if Gitlab['oak']['components']['openbao'].key?('redirect_http_to_https')

        Gitlab['oak']['components']['openbao']['redirect_http_to_https'] = true
      end

      def parse_rails_openbao_urls
        Gitlab['gitlab_rails']['openbao'] ||= {}
        Gitlab['gitlab_rails']['openbao']['url'] ||=
          Gitlab['oak']['components']['openbao']['external_url']
        Gitlab['gitlab_rails']['openbao']['internal_url'] ||=
          Gitlab['oak']['components']['openbao']['internal_url']
      end

      def validate_external_url
        url = Gitlab['oak']['components']['openbao']['external_url']
        raise "OAK OpenBao component is enabled but " \
          "`oak['components']['openbao']['external_url']` is not set." \
          if url.nil? || url.empty?
      end

      def validate_internal_url
        internal_url = Gitlab['oak']['components']['openbao']['internal_url']
        raise "OAK OpenBao component is enabled but " \
          "`oak['components']['openbao']['internal_url']` is not set." \
          if internal_url.nil? || internal_url.empty?
      end
    end
  end
end
