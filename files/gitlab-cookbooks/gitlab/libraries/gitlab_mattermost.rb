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
require_relative '../../package/libraries/deprecations'
require_relative '../../letsencrypt/libraries/helper'

module GitlabMattermost
  class << self
    def parse_variables
      parse_mattermost_external_url
      parse_gitlab_mattermost
    end

    def parse_secrets
      Gitlab['mattermost']['email_invite_salt'] ||= SecretsHelper.generate_hex(16)
      Gitlab['mattermost']['file_public_link_salt'] ||= SecretsHelper.generate_hex(16)
      Gitlab['mattermost']['sql_at_rest_encrypt_key'] ||= SecretsHelper.generate_hex(16)
    end

    def parse_mattermost_external_url
      return unless Gitlab['mattermost_external_url']

      Gitlab['mattermost']['enable'] = true if Gitlab['mattermost']['enable'].nil?

      uri = URI(Gitlab['mattermost_external_url'].to_s)

      raise "GitLab Mattermost external URL must include a schema and FQDN, e.g. http://mattermost.example.com/" unless uri.host

      Gitlab['mattermost']['host'] = uri.host
      Gitlab['mattermost']['service_site_url'] ||= Gitlab['mattermost_external_url']

      # setup gitlab auth endpoints if GitLab's external url has been provided
      if Gitlab['external_url']
        gitlab_url = Gitlab['external_url'].chomp("/")
        Gitlab['mattermost']['gitlab_auth_endpoint'] ||= "#{gitlab_url}/oauth/authorize"
        Gitlab['mattermost']['gitlab_token_endpoint'] ||= "#{gitlab_url}/oauth/token"
        Gitlab['mattermost']['gitlab_user_api_endpoint'] ||= "#{gitlab_url}/api/v4/user"

        # If mattermost is running on the same box as unicorn, allow it to communicate locally
        if Services.enabled?('unicorn') || Services.enabled?('puma')
          Gitlab['mattermost']['service_allowed_untrusted_internal_connections'] ||= ''
          Gitlab['mattermost']['service_allowed_untrusted_internal_connections'] << " #{URI(gitlab_url.to_s).host}"
        end
      end

      set_ssl
    end

    def set_ssl
      uri = URI(Gitlab['mattermost_external_url'].to_s)

      case uri.scheme
      when "http"
        Gitlab['mattermost']['service_use_ssl'] = false
        Nginx.parse_proxy_headers('mattermost_nginx', false)
      when "https"
        Gitlab['mattermost']['service_use_ssl'] = true
        Gitlab['mattermost_nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{uri.host}.crt"
        Gitlab['mattermost_nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{uri.host}.key"

        LetsEncryptHelper.add_service_alt_name("mattermost")

        Nginx.parse_proxy_headers('mattermost_nginx', true)
      else
        raise "Unsupported external URL scheme: #{uri.scheme}"
      end

      raise "Unsupported CI external URL path: #{uri.path}" unless ["", "/"].include?(uri.path)

      Gitlab['mattermost']['port'] = uri.port
    end

    def parse_gitlab_mattermost
      return unless Gitlab['mattermost']['enable']

      Gitlab['mattermost_nginx']['enable'] = true if Gitlab['mattermost_nginx']['enable'].nil?
    end
  end
end
