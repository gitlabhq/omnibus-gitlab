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

require_relative '../../gitlab/libraries/helpers/authorizer_helper'
require_relative '../../package/libraries/helpers/shell_out_helper'

module GitlabPages
  class << self
    include ShellOutHelper
    include AuthorizeHelper

    def parse_variables
      parse_pages_external_url
      parse_gitlab_pages_daemon
      parse_secrets
    end

    def parse_pages_external_url
      return unless Gitlab['pages_external_url']

      Gitlab['gitlab_rails']['pages_enabled'] = true if Gitlab['gitlab_rails']['pages_enabled'].nil?
      Gitlab['gitlab_pages']['enable'] = true if Gitlab['gitlab_pages']['enable'].nil?

      uri = URI(Gitlab['pages_external_url'].to_s)

      raise "GitLab Pages external URL must include a schema and FQDN, e.g. http://pages.example.com/" unless uri.host

      Gitlab['gitlab_rails']['pages_host'] = uri.host
      Gitlab['gitlab_rails']['pages_port'] = uri.port

      case uri.scheme
      when "http"
        Gitlab['gitlab_rails']['pages_https'] = false
        Nginx.parse_proxy_headers('pages_nginx', false)
      when "https"
        Gitlab['gitlab_rails']['pages_https'] = true
        Gitlab['pages_nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{uri.host}.crt"
        Gitlab['pages_nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{uri.host}.key"
        Nginx.parse_proxy_headers('pages_nginx', true)
      else
        raise "Unsupported GitLab Pages external URL scheme: #{uri.scheme}"
      end

      raise "Unsupported GitLab Pages external URL path: #{uri.path}" unless ["", "/"].include?(uri.path)

      # FQDN are prepared to be used as regexp: the dot is escaped
      Gitlab['pages_nginx']['fqdn_regex'] = uri.host.gsub('.', '\.')
    end

    def parse_gitlab_pages_daemon
      return unless Gitlab['gitlab_pages']['enable']

      Gitlab['gitlab_pages']['domain'] = Gitlab['gitlab_rails']['pages_host']

      if Gitlab['gitlab_pages']['external_https']
        Gitlab['gitlab_pages']['cert'] ||= "/etc/gitlab/ssl/#{Gitlab['gitlab_pages']['domain']}.crt"
        Gitlab['gitlab_pages']['cert_key'] ||= "/etc/gitlab/ssl/#{Gitlab['gitlab_pages']['domain']}.key"
      end

      Gitlab['gitlab_pages']['pages_root'] ||= (Gitlab['gitlab_rails']['pages_path'] || File.join(Gitlab['gitlab_rails']['shared_path'], 'pages'))
      Gitlab['gitlab_pages']['artifacts_server_url'] ||= Gitlab['external_url'].chomp('/') + '/api/v4'

      pages_uri = URI(Gitlab['pages_external_url'].to_s)
      Gitlab['gitlab_pages']['auth_redirect_uri'] ||= pages_uri.scheme + '://projects.' + pages_uri.host + '/auth'
      Gitlab['gitlab_pages']['gitlab_server'] ||= Gitlab['external_url']
    end

    def authorize_with_gitlab
      redirect_uri = Gitlab['gitlab_pages']['auth_redirect_uri']
      app_name = 'GitLab Pages'

      o = query_gitlab_rails(redirect_uri, app_name)
      if o.exitstatus.zero?
        app_id, app_secret = o.stdout.lines.last.chomp.split(" ")

        Gitlab['gitlab_pages']['gitlab_secret'] = app_secret
        Gitlab['gitlab_pages']['gitlab_id'] = app_id

        SecretsHelper.write_to_gitlab_secrets
        info('Updated the gitlab-secrets.json file.')
      else
        warn('Something went wrong while executing gitlab-rails runner command to get or create the app ID and secret.')
      end
    end

    def parse_secrets
      Gitlab['gitlab_pages']['auth_secret'] ||= SecretsHelper.generate_hex(64)

      # Pages and GitLab expects exactly 32 bytes, encoded with base64
      if Gitlab['gitlab_pages']['api_secret_key']
        bytes = Base64.strict_decode64(Gitlab['gitlab_pages']['api_secret_key'])
        raise "gitlab_pages['api_secret_key'] should be exactly 32 bytes" if bytes.length != 32
      else
        bytes = SecureRandom.random_bytes(32)
        Gitlab['gitlab_pages']['api_secret_key'] = Base64.strict_encode64(bytes)
      end
    end
  end
end
