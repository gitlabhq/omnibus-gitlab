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

require_relative '../../package/libraries/settings_dsl.rb'

module Nginx
  class << self
    def parse_variables
      parse_nginx_listen_addresses
    end

    def parse_nginx_listen_addresses
      return unless Gitlab['oak']['enable']

      listen_addresses = Gitlab['nginx']['listen_addresses'] ||
        Gitlab['node']['nginx']['listen_addresses']
      return if listen_addresses.include?(Gitlab['oak']['network_address'])

      Gitlab['nginx']['listen_addresses'] = listen_addresses + [Gitlab['oak']['network_address']]
    end

    def generate_host_header(fqdn, port, is_https)
      header = fqdn.dup

      if is_https
        header << ":#{port}" unless port == 443
      else
        header << ":#{port}" unless port == 80
      end

      header
    end

    def parse_proxy_headers(gitlab_rb, normal_values, default_values, ssl, allow_other_schemes = false)
      values_from_gitlab_rb = gitlab_rb['proxy_set_headers']
      default_from_attributes = normal_values['proxy_set_headers']

      applicable_values = default_from_attributes.dup.to_hash

      applicable_values['X-Forwarded-Ssl'] = 'on' if ssl

      unless allow_other_schemes
        scheme = ssl ? 'https' : 'http'
        applicable_values['X-Forwarded-Proto'] = scheme
      end

      if gitlab_rb['proxy_protocol']
        applicable_values = applicable_values.merge({
                                                      'X-Real-IP' => '$proxy_protocol_addr',
                                                      'X-Forwarded-For' => '$proxy_protocol_addr'
                                                    })
      end

      # If user has unset any header, we respect that and delete it from the
      # default value list
      if values_from_gitlab_rb
        values_from_gitlab_rb.each do |key, value|
          if value.nil?
            item = default_values['proxy_set_headers']
            item.delete(key)
          end
        end

        applicable_values = applicable_values.merge(values_from_gitlab_rb.to_hash)
      end

      applicable_values
    end

    def parse_error_pages
      # At the least, provide error pages for 404, 402, 500, 502 errors
      errors = Hash[%w(404 500 502).map { |x| [x, "#{x}.html"] }]

      custom_error_pages = Gitlab['gitlab_rails'].dig('nginx', 'custom_error_pages')

      custom_error_pages&.each_key do |err|
        errors[err] = "#{err}-custom.html"
      end

      errors
    end

    def translate_service_nginx_settings(service, node_key: nil)
      # Return if user hasn't specified anything for the service nginx
      return if Gitlab["#{service}_nginx"].nil? || Gitlab["#{service}_nginx"].empty?

      node_key ||= service

      Gitlab[node_key] ||= {}
      Gitlab[node_key]['nginx'] ||= {}

      LoggingHelper.deprecation("#{service}_nginx has been deprecated. Please use #{node_key}['nginx'] instead.")

      Gitlab["#{service}_nginx"].each do |setting, value|
        Gitlab[node_key]['nginx'][setting] = value if Gitlab[node_key]['nginx'][setting].nil?
      end
    end
  end
end
