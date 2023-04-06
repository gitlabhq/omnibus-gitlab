#
# Copyright:: Copyright (c) 2020 GitLab Inc.
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

require_relative '../../package/libraries/helpers/secrets_helper'

module GitlabKas
  class << self
    def parse_variables
      parse_address
      parse_gitlab_external_url
      parse_gitlab_kas_enabled
      parse_gitlab_kas_external_url
      parse_gitlab_kas_internal_url
    end

    def parse_address
      Gitlab['gitlab_kas']['gitlab_address'] ||= Gitlab['external_url']
    end

    def parse_gitlab_kas_enabled
      # explicitly enabled or disabled, possibly external to this Omnibus instance
      key = 'gitlab_kas_enabled'
      return unless Gitlab['gitlab_rails'][key].nil?

      # implicitly enable if installed and gitlab integration not explicitly disabled
      Gitlab['gitlab_rails'][key] = gitlab_kas_attr('enable')
    end

    def parse_gitlab_kas_internal_url
      key = 'gitlab_kas_internal_url'
      return unless Gitlab['gitlab_rails'][key].nil?

      return unless gitlab_kas_attr('enable')

      network = gitlab_kas_attr('internal_api_listen_network')
      case network
      when 'unix'
        scheme = 'unix'
      when 'tcp', 'tcp4', 'tcp6'
        scheme = 'grpc'
      else
        raise "gitlab_kas['internal_api_listen_network'] should be 'tcp', 'tcp4', 'tcp6' or 'unix' got '#{network}'"
      end

      address = gitlab_kas_attr('internal_api_listen_address')
      Gitlab['gitlab_rails'][key] = "#{scheme}://#{address}"
    end

    def parse_gitlab_kas_external_url
      return unless gitlab_kas_attr('enable')

      # we need to return if `external_url` is not set because this is needed
      # - to set the kas_url if `gitlab_kas_external_url` is not set
      # - to check the domain of `gitlab_kas_external_url` against the GitLab url
      return unless Gitlab['external_url']

      Gitlab['gitlab_kas_external_url'] ||= build_default_gitlab_kas_external_url

      if kas_domain_matches_gitlab_domain?
        parse_gitlab_kas_external_url_with_gitlab_domain
        parse_gitlab_kas_external_k8s_proxy_url_with_gitlab_domain
      else
        parse_gitlab_kas_external_url_using_own_subdomain
        parse_gitlab_kas_external_k8s_proxy_url_using_own_subdomain
      end
    end

    def parse_gitlab_external_url
      return if Gitlab['external_url'].nil?

      gitlab_uri = URI(Gitlab['external_url'])

      Gitlab['gitlab_kas']['gitlab_external_url'] ||= "#{gitlab_uri.scheme}://#{gitlab_uri.host}"
    end

    def parse_secrets
      # KAS and GitLab expects exactly 32 bytes, encoded with base64

      Gitlab['gitlab_kas']['api_secret_key'] ||= Base64.strict_encode64(SecretsHelper.generate_hex(16))
      api_secret_key = Base64.strict_decode64(Gitlab['gitlab_kas']['api_secret_key'])
      raise "gitlab_kas['api_secret_key'] should be exactly 32 bytes" if api_secret_key.length != 32

      Gitlab['gitlab_kas']['private_api_secret_key'] ||= Base64.strict_encode64(SecretsHelper.generate_hex(16))
      private_api_secret_key = Base64.strict_decode64(Gitlab['gitlab_kas']['private_api_secret_key'])
      raise "gitlab_kas['private_api_secret_key'] should be exactly 32 bytes" if private_api_secret_key.length != 32
    end

    private

    def parse_gitlab_kas_external_url_with_gitlab_domain
      key = 'gitlab_kas_external_url'
      return unless Gitlab['gitlab_rails'][key].nil?

      Gitlab['gitlab_rails'][key] = Gitlab[key]
    end

    def parse_gitlab_kas_external_k8s_proxy_url_with_gitlab_domain
      key = 'gitlab_kas_external_k8s_proxy_url'
      return unless Gitlab['gitlab_rails'][key].nil?

      gitlab_external_url = Gitlab['external_url']
      return unless gitlab_external_url

      # For now, the default external proxy URL is on the subpath /-/kubernetes-agent/k8s-proxy/
      # See https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5784
      Gitlab['gitlab_rails'][key] = "#{gitlab_external_url}/-/kubernetes-agent/k8s-proxy/"
    end

    def parse_gitlab_kas_external_url_using_own_subdomain
      key = 'gitlab_kas_external_url'
      return unless Gitlab['gitlab_rails'][key].nil?

      kas_uri = URI(Gitlab[key].to_s)

      raise "gitlab_kas_external_url must include a scheme and FQDN, e.g. wss://kas.gitlab.example.com/" unless kas_uri.host

      # We are temporarily not supporting grpc/grpcs as this requires a bigger change in the NGINX configuration
      raise "gitlab_kas_external_url scheme must be 'ws' or 'wss'" unless ws_scheme?(kas_uri.scheme)
      raise "gitlab_kas['listen_websocket'] must be set to `true`" unless gitlab_kas_attr('listen_websocket')

      use_ssl = kas_uri.scheme == 'wss'

      Gitlab['gitlab_kas_nginx']['host'] ||= kas_uri.host
      Gitlab['gitlab_kas_nginx']['port'] ||= use_ssl ? '443' : '80'

      # set gitlab_kas_nginx configs
      parse_gitlab_kas_nginx(kas_uri, use_ssl)

      Gitlab['gitlab_rails'][key] = kas_uri.to_s
    end

    def parse_gitlab_kas_nginx(kas_uri, use_ssl)
      Gitlab['gitlab_kas_nginx']['enable'] = true

      Gitlab['gitlab_kas_nginx']['https'] ||= use_ssl

      if use_ssl
        Gitlab['gitlab_kas_nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{kas_uri.host}.crt"
        Gitlab['gitlab_kas_nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{kas_uri.host}.key"

        LetsEncryptHelper.add_service_alt_name('gitlab_kas')
      end

      Nginx.parse_proxy_headers('gitlab_kas_nginx', use_ssl, true)
    end

    def parse_gitlab_kas_external_k8s_proxy_url_using_own_subdomain
      key = 'gitlab_kas_external_k8s_proxy_url'
      return unless Gitlab['gitlab_rails'][key].nil?

      kas_uri = URI(Gitlab['gitlab_kas_external_url'].to_s)
      scheme = kas_uri.scheme == 'wss' ? 'https' : 'http'

      Gitlab['gitlab_rails'][key] = "#{scheme}://#{kas_uri.host}/k8s-proxy/"
    end

    def build_default_gitlab_kas_external_url
      # For now, the default external URL is on the subpath /-/kubernetes-agent/
      # so whether to use TLS is determined from the primary external_url.
      # See https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5784
      gitlab_uri = URI(Gitlab['external_url'])

      case gitlab_uri.scheme
      when 'https'
        scheme = gitlab_kas_attr('listen_websocket') ? 'wss' : 'grpcs'
        port = gitlab_uri.port == 443 ? '' : ":#{port}"
      when 'http'
        scheme = gitlab_kas_attr('listen_websocket') ? 'ws' : 'grpc'
        port = gitlab_uri.port == 80 ? '' : ":#{port}"
      else
        raise "external_url scheme should be 'http' or 'https', got '#{gitlab_uri.scheme}"
      end

      "#{scheme}://#{gitlab_uri.host}#{port}#{gitlab_uri.path}/-/kubernetes-agent/"
    end

    def kas_domain_matches_gitlab_domain?
      gitlab_uri = URI(Gitlab['external_url'])
      gitlab_kas_uri = URI(Gitlab['gitlab_kas_external_url'])

      gitlab_uri.host == gitlab_kas_uri.host
    end

    def gitlab_kas_attr(key)
      configured = Gitlab['gitlab_kas'][key]
      return configured unless configured.nil?

      Gitlab['node']['gitlab_kas'][key]
    end

    def ws_scheme?(scheme)
      %w[ws wss].include?(scheme)
    end
  end
end
