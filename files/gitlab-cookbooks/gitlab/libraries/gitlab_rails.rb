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
require_relative '../../package/libraries/settings_dsl.rb'

module GitlabRails
  ALLOWED_DATABASES = %w[main ci geo].freeze
  MAIN_DATABASES = %w[main geo].freeze
  SHARED_DATABASE_ATTRIBUTES = %w[db_host db_port db_database].freeze

  class << self
    def parse_variables
      parse_database_adapter
      parse_database_settings
      parse_databases
      parse_external_url
      parse_directories
      parse_gitlab_trusted_proxies
      parse_incoming_email_logfile
      parse_service_desk_email_logfile
      parse_maximum_request_duration
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
      parse_ci_secure_files_dir
      parse_encrypted_settings_path
      parse_pages_dir
      parse_repository_storage
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
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
      Gitlab['gitlab_rails']['encrypted_settings_key_base'] ||= SecretsHelper.generate_hex(64)
      Gitlab['gitlab_rails']['openid_connect_signing_key'] ||= SecretsHelper.generate_rsa(4096).to_pem

      Gitlab['gitlab_rails']['initial_root_password'] = ENV['GITLAB_ROOT_PASSWORD'] || Gitlab['gitlab_rails']['initial_root_password']
      if Gitlab['gitlab_rails']['initial_root_password'].nil?
        Gitlab['gitlab_rails']['initial_root_password'] = SecretsHelper.generate_base64(32)
        Gitlab['gitlab_rails']['store_initial_root_password'] = true if Gitlab['gitlab_rails']['store_initial_root_password'].nil?
      elsif Gitlab['gitlab_rails']['initial_root_password'].length < 8
        raise 'initial_root_password: Length is too short, minimum is 8 characters'
      end

      if Gitlab['gitlab_rails']['ci_jwt_signing_key']
        begin
          key = OpenSSL::PKey::RSA.new(Gitlab['gitlab_rails']['ci_jwt_signing_key'])
          raise 'ci_jwt_signing_key: The provided key is not private RSA key' unless key.private?
        rescue OpenSSL::PKey::RSAError
          raise 'ci_jwt_signing_key: The provided key is not valid RSA key'
        end
      else
        Gitlab['gitlab_rails']['ci_jwt_signing_key'] ||= SecretsHelper.generate_rsa(4096).to_pem
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def parse_external_url
      return unless Gitlab['external_url']

      uri = URI(Gitlab['external_url'].to_s)

      raise "GitLab external URL must include a schema and FQDN, e.g. http://gitlab.example.com/" unless uri.host

      Gitlab['gitlab_rails']['gitlab_url'] = uri.to_s.chomp("/")

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
        Gitlab[WebServerHelper.service_name]['relative_url'] ||= relative_url
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

    def parse_database_settings
      [
        [%w(gitlab_rails db_username), %w(postgresql sql_user)],
        [%w(gitlab_rails db_host), %w(postgresql listen_address)],
        [%w(gitlab_rails db_port), %w(postgresql port)],
      ].each do |left, right|
        next unless Gitlab[left.first][left.last].nil?

        better_value_from_gitlab_rb = Gitlab[right.first][right.last]
        default_from_attributes = Gitlab['node']['gitlab'][SettingsDSL::Utils.sanitized_key(left.first)][left.last]
        Gitlab[left.first][left.last] = better_value_from_gitlab_rb || default_from_attributes
      end

      # Postgres allow multiple listen addresses, comma-separated values
      # In case of multi listen_address, will use the first address from list
      db_host = Gitlab['gitlab_rails']['db_host']
      if db_host&.include?(',')
        Gitlab['gitlab_rails']['db_host'] = db_host.split(',')[0]
        warning = [
          "Received gitlab_rails['db_host'] value was: #{db_host.to_json}.",
          "First listen_address '#{Gitlab['gitlab_rails']['db_host']}' will be used."
        ].join("\n  ")
        warn(warning)
      end

      # In case no other setting was provided for db_host, we use the socket
      # directory
      Gitlab['gitlab_rails']['db_host'] ||= Gitlab['postgresql']['dir'] || Gitlab['node']['postgresql']['dir']
    end

    def database_attributes
      Gitlab['node']['gitlab']['gitlab-rails'].keys.select { |k| k.start_with?('db_') }
    end

    def generate_main_database
      # If user hasn't specified a main database, for now, we will use the top
      # level `db_*` keys to populate one. In the future, when we are confident
      # in decomposition, we can deprecate top level `gitlab_rails['db_*']`
      # keys and ask users to explicitly set
      # `gitlab_rails['databases']['main']['db_*']` settings instead.
      Gitlab['gitlab_rails']['databases'] ||= {}
      Gitlab['gitlab_rails']['databases']['main'] ||= { 'enable' => true }

      # Set default value for attributes of main database based on top level
      # `gitlab_rails['db_*']` settings.
      database_attributes.each do |attribute|
        next unless Gitlab['gitlab_rails']['databases']['main'][attribute].nil?

        Gitlab['gitlab_rails']['databases']['main'][attribute] =
          [Gitlab['gitlab_rails'][attribute], Gitlab['node']['gitlab']['gitlab-rails'][attribute]].compact.first
      end
    end

    def parse_databases
      # TODO: Remove when we want to deprecate top level `gitlab_rails['db_*']`
      # settings
      generate_main_database

      # Weed out the databases that are either not allowed or not enabled explicitly (except for main and geo)
      Gitlab['gitlab_rails']['databases'].to_h.each do |database, settings|
        if !MAIN_DATABASES.include?(database) && settings['enable'] != true
          Gitlab['gitlab_rails']['databases'].delete(database)
          next
        end

        unless ALLOWED_DATABASES.include?(database)
          Gitlab['gitlab_rails']['databases'].delete(database)
          LoggingHelper.warning("Additional database `#{database}` not supported in Rails application. It will be ignored.")
        end
      end

      # Set default value of settings for other databases based on values used in `main` database.
      Gitlab['gitlab_rails']['databases'].each_key do |database|
        next if MAIN_DATABASES.include?(database)

        database_attributes.each do |attribute|
          next unless Gitlab['gitlab_rails']['databases'][database][attribute].nil?

          Gitlab['gitlab_rails']['databases'][database][attribute] = Gitlab['gitlab_rails']['databases']['main'][attribute]
        end

        # If additional database shares attributes with main
        # it should be skipped from database_tasks (running migrations)
        database_same_as_main = SHARED_DATABASE_ATTRIBUTES.all? { |attribute| Gitlab['gitlab_rails']['databases'][database][attribute] == Gitlab['gitlab_rails']['databases']['main'][attribute] }
        Gitlab['gitlab_rails']['databases'][database]['db_database_tasks'] = false if database_same_as_main
      end
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

    def parse_ci_secure_files_dir
      # This requires the parse_shared_dir to be executed before
      Gitlab['gitlab_rails']['ci_secure_files_storage_path'] ||= File.join(Gitlab['gitlab_rails']['shared_path'], 'ci_secure_files')
    end

    def parse_encrypted_settings_path
      # This requires the parse_shared_dir to be executed before
      Gitlab['gitlab_rails']['encrypted_settings_path'] ||= File.join(Gitlab['gitlab_rails']['shared_path'], 'encrypted_settings')
    end

    def parse_pages_dir
      # This requires the parse_shared_dir to be executed before
      Gitlab['gitlab_rails']['pages_path'] ||= File.join(Gitlab['gitlab_rails']['shared_path'], 'pages')
      Gitlab['gitlab_rails']['pages_local_store_path'] ||= Gitlab['gitlab_rails']['pages_path']
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
      Gitlab['gitlab_rails']['trusted_proxies'] = Gitlab['nginx']['real_ip_trusted_addresses'] if Gitlab['gitlab_rails']['trusted_proxies'].nil?
    end

    def parse_incoming_email_logfile
      log_directory = Gitlab['mailroom']['log_directory'] || Gitlab[:node]['gitlab']['mailroom']['log_directory']
      return unless log_directory

      Gitlab['gitlab_rails']['incoming_email_log_file'] ||= File.join(log_directory, 'mail_room_json.log')
    end

    def parse_service_desk_email_logfile
      log_directory = Gitlab['mailroom']['log_directory'] || Gitlab[:node]['gitlab']['mailroom']['log_directory']
      return unless log_directory

      Gitlab['gitlab_rails']['service_desk_email_log_file'] ||= File.join(log_directory, 'mail_room_json.log')
    end

    def parse_maximum_request_duration
      Gitlab['gitlab_rails']['max_request_duration_seconds'] ||= (worker_timeout * 0.95).ceil

      return if Gitlab['gitlab_rails']['max_request_duration_seconds'] < worker_timeout

      raise "The maximum request duration needs to be smaller than the worker timeout (#{worker_timeout}s)"
    end

    def public_path
      "#{Gitlab['node']['package']['install-dir']}/embedded/service/gitlab-rails/public"
    end

    def worker_timeout
      service = WebServerHelper.service_name
      user_config = Gitlab[service]
      service_config = Gitlab['node']['gitlab'][service]
      (user_config['worker_timeout'] || service_config['worker_timeout']).to_i
    end
  end
end
