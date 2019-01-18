#
# Copyright:: Copyright (c) 2018 GitLab Inc.
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

class LetsEncryptHelper
  attr_accessor :node

  def initialize(node)
    @node = node
  end

  def contact
    node['letsencrypt']['contact_emails'].map { |x| "mailto:#{x}" }
  end

  def self.add_service_alt_name(service)
    # Adds a service's external URL to the certificate's alt_name list so the
    # generated certificate is applicable to that domain also.

    return unless Gitlab['letsencrypt']['enable']

    uri = URI(Gitlab["#{service}_external_url"].to_s)

    return if !Gitlab['external_url'] || File.exist?(Gitlab["#{service}_nginx"]["ssl_certificate"])

    # If the default certficate file is missing, configure as an alt_name
    # of the letsencrypt managed certificate
    Gitlab['letsencrypt']['alt_names'] ||= []
    Gitlab['letsencrypt']['alt_names'] << uri.host

    external_uri = URI(Gitlab['external_url'])
    Gitlab["#{service}_nginx"]["ssl_certificate"] = "/etc/gitlab/ssl/#{external_uri.host}.crt"
    Gitlab["#{service}_nginx"]["ssl_certificate_key"] = "/etc/gitlab/ssl/#{external_uri.host}.key"

    # Set HTTP to HTTPS redirection automatically, if not explicitly disabled
    # by user
    Gitlab["#{service}_nginx"]['redirect_http_to_https'] = true unless Gitlab["#{service}_nginx"].key?('redirect_http_to_https')
  end
end
