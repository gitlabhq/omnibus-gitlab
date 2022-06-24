#
# Copyright:: Copyright (c) 2016 GitLab Inc.
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

require_relative 'nginx.rb'

module Registry
  class << self
    def parse_variables
      # first registry_external_url
      parse_registry_external_url
      # Enable the registry automatically if appropriate
      auto_enable
      # before this gitlab_rails[registry_path] needs to be parsed
      parse_registry
      # parsing the registry notifications
      parse_registry_notifications
    end

    ##
    # If registry_external_url is not set, we're using Let's Encrypt integration,
    # and the registry isn't explicitly disabled, we automatically enable the registry
    def auto_enable
      # If this is not nil, then it has been explicitly set and we should honor that
      return unless Gitlab['registry']['enable'].nil?

      # If registry_external_url is not nil, it has been explicitly set, and we should honor that
      return unless Gitlab['registry_external_url'].nil?

      # If Let's Encrypt is not enabled, we don't want to run
      return unless Gitlab['letsencrypt']['enable']

      uri = URI(Gitlab['external_url'].to_s)

      # Don't auto enable for relative urls
      return unless Gitlab['gitlab_rails']['gitlab_relative_url'].nil?

      Gitlab['registry']['enable'] = true
      Gitlab['registry_nginx']['listen_port'] ||= '5050'
      Gitlab['registry_nginx']['redirect_http_to_https'] = false
      Gitlab['registry_nginx']['fqdn'] = uri.host
      Gitlab['gitlab_rails']['registry_port'] ||= Gitlab['registry_nginx']['listen_port']
      set_ssl(uri.to_s)
      parse_defaults(uri)
    end

    def parse_secrets
      Gitlab['registry']['http_secret'] ||= SecretsHelper.generate_hex(64)
      gitlab_registry_crt, gitlab_registry_key = Registry.generate_registry_keypair
      Gitlab['registry']['internal_certificate'] ||= gitlab_registry_crt
      Gitlab['registry']['internal_key'] ||= gitlab_registry_key
    end

    def parse_registry_external_url
      return unless Gitlab['registry_external_url']

      uri = URI(Gitlab['registry_external_url'].to_s)

      raise "GitLab Container Registry external URL must include a schema and FQDN, e.g. https://registry.example.com/" unless uri.host

      Gitlab['registry']['enable'] = true if Gitlab['registry']['enable'].nil?
      parse_defaults(uri)

      set_ssl(uri.to_s)
      LetsEncryptHelper.add_service_alt_name("registry")
    end

    def parse_defaults(uri)
      Gitlab['gitlab_rails']['registry_enabled'] = true if Gitlab['registry']['enable']
      Gitlab['gitlab_rails']['registry_host'] = uri.host
      Gitlab['registry_nginx']['listen_port'] ||= uri.port
      Gitlab['registry']['registry_http_addr'] ||= "127.0.0.1:5000"
      Gitlab['registry']['registry_http_addr'].gsub(/^https?\:\/\/(www.)?/, '')
      Gitlab['registry']['token_realm'] ||= Gitlab['external_url']
      Gitlab['gitlab_rails']['registry_api_url'] ||= "http://#{Gitlab['registry']['registry_http_addr']}"
    end

    def set_ssl(url)
      uri = URI(url)

      case uri.scheme
      when "http"
        Gitlab['registry_nginx']['https'] ||= false
        Nginx.parse_proxy_headers('registry_nginx', false)
      when "https"
        Gitlab['registry_nginx']['https'] ||= true
        Gitlab['registry_nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{uri.host}.crt"
        Gitlab['registry_nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{uri.host}.key"

        Nginx.parse_proxy_headers('registry_nginx', true)
      else
        raise "Unsupported GitLab Registry external URL scheme: #{uri.scheme}"
      end

      raise "Unsupported GitLab Registry external URL path: #{uri.path}" unless ["", "/"].include?(uri.path)

      # Docker versions before 1.13 will fail to authenticate/push with the
      # registry if Registry URL contained :80 or :443. So, we don't set the
      # port in gitlab.yml.
      Gitlab['gitlab_rails']['registry_port'] = uri.port unless [80, 443].include?(uri.port)
    end

    def parse_registry
      return unless Gitlab['registry']['enable']

      Gitlab['gitlab_rails']['registry_path'] = "#{Gitlab['gitlab_rails']['shared_path']}/registry" if Gitlab['gitlab_rails']['registry_path'].nil?
      Gitlab['registry']['storage_delete_enabled'] = true if Gitlab['registry']['storage_delete_enabled'].nil?
      Gitlab['registry']['health_storagedriver_enabled'] = true if Gitlab['registry']['health_storagedriver_enabled'].nil?

      Gitlab['registry']['storage'] ||= {
        'filesystem' => { 'rootdirectory' => Gitlab['gitlab_rails']['registry_path'] }
      }

      Gitlab['registry']['storage']['cache'] ||= { 'blobdescriptor' => 'inmemory' }
      Gitlab['registry']['storage']['delete'] ||= { 'enabled' => Gitlab['registry']['storage_delete_enabled'] }
    end

    def parse_registry_notifications
      return unless Gitlab['registry']['notifications']

      user_configuration = Gitlab['registry']
      gitlab_configuration = Gitlab['node']['registry']

      # Use the registry defaults configured by the user but use the defaults from gitlab if they were not set
      user_configuration['default_notifications_timeout'] ||= gitlab_configuration['default_notifications_timeout']
      user_configuration['default_notifications_threshold'] ||= gitlab_configuration['default_notifications_threshold']
      user_configuration['default_notifications_backoff'] ||=  gitlab_configuration['default_notifications_backoff']
      user_configuration['default_notifications_headers'] ||=  gitlab_configuration['default_notifications_headers']

      Gitlab['registry']['notifications'].each do |endpoint|
        # Get the values from default if they are not set
        endpoint['timeout'] ||= user_configuration['default_notifications_timeout']
        endpoint['threshold'] ||= user_configuration['default_notifications_threshold']
        endpoint['backoff'] ||= user_configuration['default_notifications_backoff']

        # And merge the default headers with the ones specific to this endpoint
        endpoint['headers'] = user_configuration['default_notifications_headers'].merge(endpoint['headers'] || {})

        # As we set notification secret in gitlab.rb for registry we don't have to make user
        # fill it in separately for GitLab application
        Gitlab['gitlab_rails']['registry_notification_secret'] ||= endpoint['headers']['Authorization'].last if endpoint['name'] == 'geo_event'
      end
    end

    def generate_registry_keypair
      key, cert = SecretsHelper.generate_keypair(
        bits: 4096,
        subject: "/C=USA/O=GitLab/OU=Container/CN=Registry",
        validity: 365 * 10 # ten years from now
      )

      [cert.to_pem, key.to_pem]
    end
  end
end
