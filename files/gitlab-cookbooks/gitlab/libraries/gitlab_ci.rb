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

module GitlabCi
  class << self
    # Standalone GitLab CI is deprected.
    # The code below will be removed in the next major release.
    def parse_variables
      parse_ci_external_url
      parse_gitlab_ci
    end

    def parse_ci_external_url
      return unless Gitlab['ci_external_url']
      # Disable gitlab_ci. This setting will be picked up by parse_gitlab_ci
      Gitlab['gitlab_ci']['enable'] = false

      uri = URI(Gitlab['ci_external_url'].to_s)

      unless uri.host
        raise "GitLab CI external URL must include a schema and FQDN, e.g. http://ci.example.com/"
      end
      Gitlab['gitlab_ci']['gitlab_ci_host'] = uri.host
      Gitlab['gitlab_ci']['gitlab_ci_email_from'] ||= "gitlab-ci@#{uri.host}"

      case uri.scheme
      when "http"
        Gitlab['gitlab_ci']['gitlab_ci_https'] = false
      when "https"
        Gitlab['gitlab_ci']['gitlab_ci_https'] = true
        Gitlab['ci_nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{uri.host}.crt"
        Gitlab['ci_nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{uri.host}.key"
      else
        raise "Unsupported external URL scheme: #{uri.scheme}"
      end

      unless ["", "/"].include?(uri.path)
        raise "Unsupported CI external URL path: #{uri.path}"
      end

      Gitlab['gitlab_ci']['gitlab_ci_port'] = uri.port
    end

    def parse_gitlab_ci
      return unless Gitlab['gitlab_ci']['enable']

      Gitlab['ci_unicorn']['enable'] = true if Gitlab['ci_unicorn']['enable'].nil?
      Gitlab['ci_sidekiq']['enable'] = true if Gitlab['ci_sidekiq']['enable'].nil?
      Gitlab['ci_redis']['enable'] = true if Gitlab['ci_redis']['enable'].nil?
      Gitlab['ci_nginx']['enable'] = true if Gitlab['ci_nginx']['enable'].nil?
    end
  end
end
