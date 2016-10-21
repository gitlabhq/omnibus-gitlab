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
      # before this gitlab_rails[registry_path] needs to be parsed
      parse_registry
    end

    def parse_registry_external_url
      return unless Gitlab['registry_external_url']

      uri = URI(Gitlab['registry_external_url'].to_s)

      unless uri.host
        raise "GitLab Container Registry external URL must include a schema and FQDN, e.g. https://registry.example.com/"
      end

      Gitlab['registry']['enable'] = true if Gitlab['registry']['enable'].nil?
      Gitlab['gitlab_rails']['registry_enabled'] = true if Gitlab['registry']['enable']

      Gitlab['registry']['registry_http_addr'] ||= "localhost:5000"
      Gitlab['registry']['registry_http_addr'].gsub(/^https?\:\/\/(www.)?/,'')
      Gitlab['gitlab_rails']['registry_api_url'] ||= "http://#{Gitlab['registry']['registry_http_addr']}"
      Gitlab['registry']['token_realm'] ||= Gitlab['external_url']
      Gitlab['gitlab_rails']['registry_host'] = uri.host
      Gitlab['registry_nginx']['listen_port'] ||= uri.port

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

      unless ["", "/"].include?(uri.path)
        raise "Unsupported GitLab Registry external URL path: #{uri.path}"
      end

      unless [80, 443].include?(uri.port)
        Gitlab['gitlab_rails']['registry_port'] = uri.port
      end
    end

    def parse_registry
      return unless Gitlab['registry']['enable']

      Gitlab['gitlab_rails']['registry_path'] = "#{Gitlab['gitlab_rails']['shared_path']}/registry" if Gitlab['gitlab_rails']['registry_path'].nil?
      Gitlab['registry']['storage_delete_enabled'] = true if Gitlab['registry']['storage_delete_enabled'].nil?

      Gitlab['registry']['storage'] ||= {
        'filesystem' => { 'rootdirectory' => Gitlab['gitlab_rails']['registry_path'] }
      }

      Gitlab['registry']['storage']['cache'] ||= {'blobdescriptor'=>'inmemory'}
      Gitlab['registry']['storage']['delete'] ||= {'enabled' => Gitlab['registry']['storage_delete_enabled']}
    end

    def generate_registry_keypair
      key = OpenSSL::PKey::RSA.new(4096)
      subject = "/C=USA/O=GitLab/OU=Container/CN=Registry"

      cert = OpenSSL::X509::Certificate.new
      cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
      cert.not_before = Time.now
      cert.not_after = (DateTime.now + 365 * 10).to_time
      cert.public_key = key.public_key
      cert.serial = 0x0
      cert.version = 2
      cert.sign key, OpenSSL::Digest::SHA256.new

      [cert.to_pem, key.to_pem]
    end
  end
end
