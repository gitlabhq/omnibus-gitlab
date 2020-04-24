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
require_relative '../../gitaly/libraries/gitaly.rb'

module GitlabRails # rubocop:disable Style/MultilineIfModifier
  # The guard clause at the end of this module is used only to get the tests
  # running. It prevents reloading of the module during converging, so tests
  # pass. Hence, disabling the cop.

  class << self
    def parse_variables
      parse_database_adapter
      parse_external_url
      parse_directories
      parse_gitlab_trusted_proxies
      parse_rack_attack_protected_paths
      parse_incoming_email_logfile
      parse_service_desk_email_logfile
      parse_maximum_request_duration
      parse_db_statement_timeout
    end

    def parse_directories
      parse_runtime_dir
      parse_shared_dir
      parse_artifacts_dir
      parse_external_diffs_dir
      parse_lfs_objects_dir
      parse_uploads_dir
      parse_packages_dir
      parse_dependency_proxy_dir
      parse_terraform_state_dir
      parse_pages_dir
      parse_repository_storage
    end

    def parse_secrets
      # Blow up when the existing configuration is ambiguous, so we don't accidentally throw away important secrets
      ci_db_key_base = Gitlab['gitlab_ci']['db_key_base']
      rails_db_key_base = Gitlab['gitlab_rails']['db_key_base']

      if ci_db_key_base && rails_db_key_base && ci_db_key_base != rails_db_key_base
        message = [
          "The value of Gitlab['gitlab_ci']['db_key_base'] (#{ci_db_key_base}) does not match the value of Gitlab['gitlab_rails']['db_key_base'] (#{rails_db_key_base}).",
          "Please back up both secrets, set Gitlab['gitlab_rails']['db_key_base'] to the value of Gitlab['gitlab_ci']['db_key_base'], and try again.",
          "For more information, see <https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/update/README.md#migrating-legacy-secrets>"
        ]

        raise message.join("\n\n")
      end

      # Transform legacy key names to new key names
      Gitlab['gitlab_rails']['db_key_base'] ||= Gitlab['gitlab_ci']['db_key_base'] # Changed in 8.11
      Gitlab['gitlab_rails']['secret_key_base'] ||= Gitlab['gitlab_ci']['db_key_base'] # Changed in 8.11
      Gitlab['gitlab_rails']['otp_key_base'] ||= Gitlab['gitlab_rails']['secret_token']
      Gitlab['gitlab_rails']['openid_connect_signing_key'] ||= Gitlab['gitlab_rails']['jws_private_key'] # Changed in 10.1

      # Note: If you add another secret to generate here make sure it gets written to disk in SecretsHelper.write_to_gitlab_secrets
      Gitlab['gitlab_rails']['db_key_base'] ||= SecretsHelper.generate_hex(64)
      Gitlab['gitlab_rails']['secret_key_base'] ||= SecretsHelper.generate_hex(64)
      Gitlab['gitlab_rails']['otp_key_base'] ||= SecretsHelper.generate_hex(64)
      Gitlab['gitlab_rails']['openid_connect_signing_key'] ||= SecretsHelper.generate_rsa(4096).to_pem
    end

    def parse_external_url
      return unless Gitlab['external_url']

      uri = URI(Gitlab['external_url'].to_s)

      raise "GitLab external URL must include a schema and FQDN, e.g. http://gitlab.example.com/" unless uri.host

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

    def parse_database_adapter
      # TODO: Remove in GitLab 13

      adapter = Gitlab['gitlab_rails']['db_adapter']
      error_message = <<~MSG
          PostgreSQL is the only supported DBMS starting from GitLab 12.1 and you are using #{adapter}.
          Please refer https://docs.gitlab.com/omnibus/update/convert_to_omnibus.html#upgrading-from-non-omnibus-mysql-to-an-omnibus-installation-version-68
          to migrate to a PostgreSQL based installation.
      MSG
      raise error_message if adapter && adapter != 'postgresql'
    end

    def parse_runtime_dir
      if Gitlab['node']['filesystem'].nil?
        Chef::Log.warn 'No filesystem variables in Ohai, disabling runtime_dir'
        Gitlab['runtime_dir'] = nil
        return
      end

      return if Gitlab['runtime_dir']

      search_dirs = ['/run', '/dev/shm']

      search_dirs.each do |run_dir|
        fs = Gitlab['node']['filesystem']['by_mountpoint'][run_dir]

        if fs && fs['fs_type'] == 'tmpfs'
          Gitlab['runtime_dir'] = run_dir
          break
        end
      end

      Chef::Log.warn "Could not find a tmpfs in #{search_dirs}" if Gitlab['runtime_dir'].nil?

      Gitlab['runtime_dir']
    end

    def parse_shared_dir
      Gitlab['gitlab_rails']['shared_path'] ||= Gitlab['node']['gitlab']['gitlab-rails']['shared_path']
    end

    def parse_artifacts_dir
      # This requires the parse_shared_dir to be executed before
      Gitlab['gitlab_rails']['artifacts_path'] ||= File.join(Gitlab['gitlab_rails']['shared_path'], 'artifacts')
    end

    def parse_external_diffs_dir
      # This requires the parse_shared_dir to be executed before
      Gitlab['gitlab_rails']['external_diffs_storage_path'] ||= File.join(Gitlab['gitlab_rails']['shared_path'], 'external-diffs')
    end

    def parse_lfs_objects_dir
      # This requires the parse_shared_dir to be executed before
      Gitlab['gitlab_rails']['lfs_storage_path'] ||= File.join(Gitlab['gitlab_rails']['shared_path'], 'lfs-objects')
    end

    def parse_uploads_dir
      Gitlab['gitlab_rails']['uploads_storage_path'] ||= public_path
    end

    def parse_packages_dir
      # This requires the parse_shared_dir to be executed before
      Gitlab['gitlab_rails']['packages_storage_path'] ||= File.join(Gitlab['gitlab_rails']['shared_path'], 'packages')
    end

    def parse_dependency_proxy_dir
      # This requires the parse_shared_dir to be executed before
      Gitlab['gitlab_rails']['dependency_proxy_storage_path'] ||= File.join(Gitlab['gitlab_rails']['shared_path'], 'dependency_proxy')
    end

    def parse_terraform_state_dir
      # This requires the parse_shared_dir to be executed before
      Gitlab['gitlab_rails']['terraform_state_storage_path'] ||= File.join(Gitlab['gitlab_rails']['shared_path'], 'terraform_state')
    end

    def parse_pages_dir
      # This requires the parse_shared_dir to be executed before
      Gitlab['gitlab_rails']['pages_path'] ||= File.join(Gitlab['gitlab_rails']['shared_path'], 'pages')
    end

    def parse_repository_storage
      return if Gitlab['gitlab_rails']['repositories_storages']

      gitaly_address = Gitaly.gitaly_address

      Gitlab['gitlab_rails']['repositories_storages'] ||= {
        "default" => {
          "path" => "/var/opt/gitlab/git-data/repositories",
          "gitaly_address" => gitaly_address
        }
      }
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
      return unless Gitlab['gitlab_rails']['gitlab_relative_url']

      paths_without_relative_url = []
      Gitlab['gitlab_rails']['rack_attack_protected_paths'].each do |path|
        if path.start_with?(Gitlab['gitlab_rails']['gitlab_relative_url'] + '/')
          stripped_path = path.sub(Gitlab['gitlab_rails']['gitlab_relative_url'], '')
          paths_without_relative_url.push(stripped_path)
        end
      end
      Gitlab['gitlab_rails']['rack_attack_protected_paths'].concat(paths_without_relative_url)
    end

    def parse_incoming_email_logfile
      log_directory = Gitlab['mailroom']['log_directory']
      return unless log_directory

      Gitlab['gitlab_rails']['incoming_email_log_file'] ||= File.join(log_directory, 'mail_room_json.log')
    end

    def parse_service_desk_email_logfile
      log_directory = Gitlab['mailroom']['log_directory']
      return unless log_directory

      Gitlab['gitlab_rails']['service_desk_email_log_file'] ||= File.join(log_directory, 'mail_room_json.log')
    end

    def parse_maximum_request_duration
      Gitlab['gitlab_rails']['max_request_duration_seconds'] ||= (worker_timeout * 0.95).ceil

      return if Gitlab['gitlab_rails']['max_request_duration_seconds'] < worker_timeout

      raise "The maximum request duration needs to be smaller than the worker timeout (#{worker_timeout}s)"
    end

    def parse_db_statement_timeout
      # If not set explicitly by user, set client side timeout to either user
      # specified server side timeout or to default value of server side timeout
      Gitlab['gitlab_rails']['db_statement_timeout'] ||= Gitlab['postgresql']['statement_timeout'] || Gitlab['node']['postgresql']['statement_timeout']
    end

    def public_path
      "#{Gitlab['node']['package']['install-dir']}/embedded/service/gitlab-rails/public"
    end

    def worker_timeout
      service = Services.enabled?('puma') ? 'puma' : 'unicorn'
      user_config = Gitlab[service]
      service_config = Gitlab['node']['gitlab'][service]
      (user_config['worker_timeout'] || service_config['worker_timeout']).to_i
    end
  end
end unless defined?(GitlabRails) # Prevent reloading during converge, so we can test
