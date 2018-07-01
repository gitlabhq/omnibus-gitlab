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

module GitlabPages
  class << self
    def parse_variables
      parse_pages_external_url
      parse_gitlab_pages_daemon
      parse_secrets
      parse_admin_socket
      parse_admin_certificate
    end

    def parse_pages_external_url
      return unless Gitlab['pages_external_url']

      Gitlab['gitlab_rails']['pages_enabled'] = true if Gitlab['gitlab_rails']['pages_enabled'].nil?
      Gitlab['gitlab_pages']['enable'] = true if Gitlab['gitlab_pages']['enable'].nil?

      uri = URI(Gitlab['pages_external_url'].to_s)

      unless uri.host
        raise "GitLab Pages external URL must include a schema and FQDN, e.g. http://pages.example.com/"
      end

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

      unless ["", "/"].include?(uri.path)
        raise "Unsupported GitLab Pages external URL path: #{uri.path}"
      end

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
    end

    def parse_secrets
      Gitlab['gitlab_pages']['admin_secret_token'] ||= SecretsHelper.generate_hex(64)
    end

    def parse_admin_socket
      pages_dir = Gitlab['gitlab_pages']['dir'] || Gitlab['node']['gitlab']['gitlab-pages']['dir']
      Gitlab['gitlab_rails']['pages_admin_address'] ||= 'unix:' + File.join(pages_dir, 'admin.socket')
    end

    def parse_admin_certificate
      Gitlab['gitlab_rails']['pages_admin_certificate'] ||= Gitlab['gitlab_pages']['admin_https_cert']
    end
  end
end
