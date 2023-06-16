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
      parse_nginx_listen_ports
      parse_nginx_proxy_protocol
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

    def parse_nginx_listen_ports
      [
        [%w(nginx listen_port), %w(gitlab_rails gitlab_port)],
        [%w(mattermost_nginx listen_port), %w(mattermost port)],
        [%w(pages_nginx listen_port), %w(gitlab_rails pages_port)],

      ].each do |left, right|
        next unless Gitlab[left.first][left.last].nil?

        # This conditional is required until all services are extracted to
        # their own cookbook. Mattermost exists directly on node while
        # others exists on node['gitlab']
        node_attribute_key = SettingsDSL::Utils.node_attribute_key(right.first)
        service_attribute_key = right.last
        default_set_gitlab_port = if Gitlab['node']['gitlab'].key?(node_attribute_key)
                                    Gitlab['node']['gitlab'][node_attribute_key][service_attribute_key]
                                  else
                                    Gitlab['node'][node_attribute_key][service_attribute_key]
                                  end
        user_set_gitlab_port = Gitlab[right.first][right.last]

        Gitlab[left.first][left.last] = user_set_gitlab_port || default_set_gitlab_port
      end
    end

    def parse_nginx_proxy_protocol
      [
        'nginx',
        'mattermost_nginx',
        'pages_nginx',
        'registry_nginx',
        'gitlab_kas_nginx'
      ].each do |app|
        Gitlab[app]['real_ip_header'] ||= 'proxy_protocol' if Gitlab[app]['proxy_protocol']
      end
    end

    def parse_proxy_headers(app, ssl, allow_other_schemes = false)
      values_from_gitlab_rb = Gitlab[app]['proxy_set_headers']
      dashed_app = SettingsDSL::Utils.node_attribute_key(app)
      default_from_attributes = Gitlab['node']['gitlab'][dashed_app]['proxy_set_headers'].to_hash

      default_from_attributes['X-Forwarded-Ssl'] = 'on' if ssl

      unless allow_other_schemes
        scheme = ssl ? 'https' : 'http'
        default_from_attributes['X-Forwarded-Proto'] = scheme
      end

      if Gitlab[app]['proxy_protocol']
        default_from_attributes = default_from_attributes.merge({
                                                                  'X-Real-IP' => '$proxy_protocol_addr',
                                                                  'X-Forwarded-For' => '$proxy_protocol_addr'
                                                                })
      end

      if values_from_gitlab_rb
        values_from_gitlab_rb.each do |key, value|
          if value.nil?
            default_attrs = Gitlab['node'].default['gitlab'][dashed_app]['proxy_set_headers']
            default_attrs.delete(key)
          end
        end

        default_from_attributes = default_from_attributes.merge(values_from_gitlab_rb.to_hash)
      end

      Gitlab[app]['proxy_set_headers'] = default_from_attributes
    end

    def parse_error_pages
      # At the least, provide error pages for 404, 402, 500, 502 errors
      errors = Hash[%w(404 500 502).map { |x| [x, "#{x}.html"] }]
      if Gitlab['nginx'].key?('custom_error_pages')
        Gitlab['nginx']['custom_error_pages'].each_key do |err|
          errors[err] = "#{err}-custom.html"
        end
      end
      errors
    end
  end
end
