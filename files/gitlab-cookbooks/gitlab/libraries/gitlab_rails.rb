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

module GitlabRails
  class << self
    def parse_variables
      parse_external_url
      parse_directories
      parse_gitlab_trusted_proxies
      parse_rack_attack_protected_paths
    end

    def parse_directories
      parse_shared_dir
      parse_artifacts_dir
      parse_lfs_objects_dir
      parse_pages_dir
    end

    def parse_external_url
      return unless Gitlab['external_url']

      uri = URI(Gitlab['external_url'].to_s)

      unless uri.host
        raise "GitLab external URL must include a schema and FQDN, e.g. http://gitlab.example.com/"
      end
      Gitlab['user']['git_user_email'] ||= "gitlab@#{uri.host}"
      Gitlab['gitlab_rails']['gitlab_host'] = uri.host
      Gitlab['gitlab_rails']['gitlab_email_from'] ||= "gitlab@#{uri.host}"

      case uri.scheme
      when "http"
        Gitlab['gitlab_rails']['gitlab_https'] = false
        Nginx.parse_proxy_headers('nginx', false)
      when "https"
        Gitlab['gitlab_rails']['gitlab_https'] = true
        Gitlab['nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{uri.host}.crt"
        Gitlab['nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{uri.host}.key"
        Nginx.parse_proxy_headers('nginx', true)
      else
        raise "Unsupported external URL scheme: #{uri.scheme}"
      end

      unless ["", "/"].include?(uri.path)
        relative_url = uri.path.chomp("/")
        Gitlab['gitlab_rails']['gitlab_relative_url'] ||= relative_url
        Gitlab['unicorn']['relative_url'] ||= relative_url
        Gitlab['gitlab_workhorse']['relative_url'] ||= relative_url
      end

      Gitlab['gitlab_rails']['gitlab_port'] = uri.port
    end

    def parse_shared_dir
      Gitlab['gitlab_rails']['shared_path'] ||= Gitlab['node']['gitlab']['gitlab-rails']['shared_path']
    end

    def parse_artifacts_dir
      # This requires the parse_shared_dir to be executed before
      Gitlab['gitlab_rails']['artifacts_path'] ||= File.join(Gitlab['gitlab_rails']['shared_path'], 'artifacts')
    end

    def parse_lfs_objects_dir
      # This requires the parse_shared_dir to be executed before
      Gitlab['gitlab_rails']['lfs_storage_path'] ||= File.join(Gitlab['gitlab_rails']['shared_path'], 'lfs-objects')
    end

    def parse_pages_dir
      # This requires the parse_shared_dir to be executed before
      Gitlab['gitlab_rails']['pages_path'] ||= File.join(Gitlab['gitlab_rails']['shared_path'], 'pages')
    end

    def parse_gitlab_trusted_proxies
      Gitlab['nginx']['real_ip_trusted_addresses'] ||= Gitlab['node']['gitlab']['nginx']['real_ip_trusted_addresses']
      Gitlab['gitlab_rails']['trusted_proxies'] ||= Gitlab['nginx']['real_ip_trusted_addresses']
    end

    def parse_rack_attack_protected_paths
      # Fixing common user's input mistakes for rake attack protected paths
      return unless Gitlab['gitlab_rails']['rack_attack_protected_paths']

      # append leading slash if missing
      Gitlab['gitlab_rails']['rack_attack_protected_paths'].map! do |path|
        path.start_with?('/') ? path : '/' + path
      end

      # append urls to the list but without relative_url
      if Gitlab['gitlab_rails']['gitlab_relative_url']
        paths_without_relative_url = []
        Gitlab['gitlab_rails']['rack_attack_protected_paths'].each do |path|
          if path.start_with?(Gitlab['gitlab_rails']['gitlab_relative_url'] + '/')
            stripped_path = path.sub(Gitlab['gitlab_rails']['gitlab_relative_url'], '')
            paths_without_relative_url.push(stripped_path)
          end
        end
        Gitlab['gitlab_rails']['rack_attack_protected_paths'].concat(paths_without_relative_url)
      end

    end

    def disable_services
      disable_services_roles if any_role_defined?

      disable_gitlab_rails_services
    end

    def public_path
      "#{Gitlab['node']['package']['install-dir']}/embedded/service/gitlab-rails/public"
    end

    private

    def any_role_defined?
      Gitlab::ROLES.any? { |role| Gitlab["#{role}_role"]['enable'] }
    end

    def disable_services_roles
      if Gitlab['redis_sentinel_role']['enable']
        disable_non_redis_services
        Gitlab['sentinel']['enable'] = true
      else
        Gitlab['sentinel']['enable'] = false
      end

      if Gitlab['redis_master_role']['enable']
        disable_non_redis_services
        Gitlab['redis']['enable'] = true
      end

      if Gitlab['redis_slave_role']['enable']
        disable_non_redis_services
        Gitlab['redis']['enable'] = true
      end

      if Gitlab['redis_master_role']['enable'] && Gitlab['redis_slave_role']['enable']
        fail 'Cannot define both redis_master_role and redis_slave_role in the same machine.'
      elsif Gitlab['redis_master_role']['enable'] || Gitlab['redis_slave_role']['enable']
        disable_non_redis_services
      else
        Gitlab['redis']['enable'] = false
      end
    end

    def disable_gitlab_rails_services
      if Gitlab['gitlab_rails']['enable'] == false
        Gitlab['unicorn']['enable'] = false
        Gitlab['sidekiq']['enable'] = false
        Gitlab['gitlab_workhorse']['enable'] = false
      end
    end

    def disable_non_redis_services
      Gitlab['gitlab_rails']['enable'] = false
      Gitlab['bootstrap']['enable'] = false
      Gitlab['nginx']['enable'] = false
      Gitlab['postgresql']['enable'] = false
      Gitlab['mailroom']['enable'] = false
    end
  end
end
