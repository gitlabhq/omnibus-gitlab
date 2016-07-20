#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab.com
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

# The Gitlab module in this file is used to parse /etc/gitlab/gitlab.rb.
#
# Warning to the reader:
# Because the Ruby DSL in /etc/gitlab/gitlab.rb does not accept hyphens in
# section names, this module translates names like 'gitlab_rails' to the
# correct 'gitlab-rails' in the `generate_hash` method. This module is the only
# place in the cookbook where we write 'gitlab_rails'.

require 'mixlib/config'
require 'chef/mash'
require 'chef/json_compat'
require 'chef/mixin/deep_merge'
require 'securerandom'
require 'uri'

module Gitlab
  extend(Mixlib::Config)

  bootstrap Mash.new
  omnibus_gitconfig Mash.new
  manage_accounts Mash.new
  manage_storage_directories Mash.new
  user Mash.new
  postgresql Mash.new
  redis Mash.new
  ci_redis Mash.new
  gitlab_rails Mash.new
  gitlab_ci Mash.new
  gitlab_shell Mash.new
  unicorn Mash.new
  ci_unicorn Mash.new
  sidekiq Mash.new
  ci_sidekiq Mash.new
  gitlab_workhorse Mash.new
  gitlab_git_http_server Mash.new # legacy from GitLab 7.14, 8.0, 8.1
  pages_nginx Mash.new
  registry_nginx Mash.new
  mailroom Mash.new
  nginx Mash.new
  ci_nginx Mash.new
  mattermost_nginx Mash.new
  logging Mash.new
  remote_syslog Mash.new
  logrotate Mash.new
  high_availability Mash.new
  web_server Mash.new
  mattermost Mash.new
  gitlab_pages Mash.new
  registry Mash.new
  node nil
  external_url nil
  pages_external_url nil
  ci_external_url nil
  mattermost_external_url nil
  registry_external_url nil
  git_data_dir nil

  class << self

    # guards against creating secrets on non-bootstrap node
    def generate_hex(chars)
      SecureRandom.hex(chars)
    end

    def generate_secrets(node_name)
      SecretsHelper.read_gitlab_secrets

      # Note: If you add another secret to generate here make sure it gets written to disk in SecretsHelper.write_to_gitlab_secrets
      Gitlab['gitlab_shell']['secret_token'] ||= generate_hex(64)
      Gitlab['gitlab_rails']['secret_token'] ||= generate_hex(64)

      Gitlab['gitlab_ci']['secret_key_base'] ||= if Gitlab['gitlab_ci']['secret_token']
                                                   Gitlab['gitlab_ci']['secret_token']
                                                 else
                                                   generate_hex(64)
                                                 end
      Gitlab['gitlab_ci']['db_key_base'] ||= generate_hex(64)

      Gitlab['registry']['http_secret'] ||= generate_hex(64)
      gitlab_registry_crt, gitlab_registry_key = generate_registry_keypair
      Gitlab['registry']['internal_certificate'] ||= gitlab_registry_crt
      Gitlab['registry']['internal_key'] ||= gitlab_registry_key

      Gitlab['mattermost']['email_invite_salt'] ||= generate_hex(16)
      Gitlab['mattermost']['file_public_link_salt'] ||= generate_hex(16)
      Gitlab['mattermost']['email_password_reset_salt'] ||= generate_hex(16)
      Gitlab['mattermost']['sql_at_rest_encrypt_key'] ||= generate_hex(16)

      # Note: Besides the section below, gitlab-secrets.json will also change
      # in CiHelper in libraries/helper.rb
      SecretsHelper.write_to_gitlab_secrets
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

    def parse_gitlab_git_http_server
      Gitlab['gitlab_git_http_server'].each do |k, v|
        Chef::Log.warn "gitlab_git_http_server is deprecated. Please use gitlab_workhorse in gitlab.rb"
        if Gitlab['gitlab_workhorse'][k].nil?
          Chef::Log.warn "applying legacy setting gitlab_git_http_server[#{k.inspect}]"
          Gitlab['gitlab_workhorse'][k] = v
        else
          Chef::Log.warn "ignoring legacy setting gitlab_git_http_server[#{k.inspect}]"
        end
      end
    end

    def parse_external_url
      return unless external_url

      uri = URI(external_url.to_s)

      unless uri.host
        raise "GitLab external URL must include a schema and FQDN, e.g. http://gitlab.example.com/"
      end
      Gitlab['user']['git_user_email'] ||= "gitlab@#{uri.host}"
      Gitlab['gitlab_rails']['gitlab_host'] = uri.host
      Gitlab['gitlab_rails']['gitlab_email_from'] ||= "gitlab@#{uri.host}"

      case uri.scheme
      when "http"
        Gitlab['gitlab_rails']['gitlab_https'] = false
        parse_proxy_headers('nginx', false)
      when "https"
        Gitlab['gitlab_rails']['gitlab_https'] = true
        Gitlab['nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{uri.host}.crt"
        Gitlab['nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{uri.host}.key"
        parse_proxy_headers('nginx', true)
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

    def parse_git_data_dir
      return unless git_data_dir

      Gitlab['gitlab_shell']['git_data_directory'] ||= git_data_dir
      Gitlab['gitlab_rails']['gitlab_shell_repos_path'] ||= File.join(git_data_dir, "repositories")

      # Important: keep the satellites.path setting until GitLab 9.0 at
      # least. This setting is fed to 'rm -rf' in
      # db/migrate/20151023144219_remove_satellites.rb
      Gitlab['gitlab_rails']['satellites_path'] ||= File.join(git_data_dir, "gitlab-satellites")
    end

    def parse_shared_dir
      Gitlab['gitlab_rails']['shared_path'] ||= node['gitlab']['gitlab-rails']['shared_path']
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

    def parse_udp_log_shipping
      return unless logging['udp_log_shipping_host']

      Gitlab['remote_syslog']['enable'] ||= true
      Gitlab['remote_syslog']['destination_host'] ||= logging['udp_log_shipping_host']

      if logging['udp_log_shipping_port']
        Gitlab['remote_syslog']['destination_port'] ||= logging['udp_log_shipping_port']
        Gitlab['logging']['svlogd_udp'] ||= "#{logging['udp_log_shipping_host']}:#{logging['udp_log_shipping_port']}"
      else
        Gitlab['logging']['svlogd_udp'] ||= logging['udp_log_shipping_host']
      end

      %w{
        redis
        ci-redis
        nginx
        sidekiq
        ci-sidekiq
        unicorn
        ci-unicorn
        postgresql
        remote-syslog
        gitlab-workhorse
        mailroom
        mattermost
        gitlab-pages
        registry
      }.each do |runit_sv|
        Gitlab[runit_sv.gsub('-', '_')]['svlogd_prefix'] ||= "#{node['hostname']} #{runit_sv}: "
      end
    end

    def parse_redis_settings
      if gitlab_rails['redis_host']
        # The user wants to connect to a non-bundled Redis instance via TCP.
        # Override the gitlab-rails default redis_port value (nil) to signal
        # that gitlab-rails should connect to Redis via TCP instead of a Unix
        # domain socket.
        Gitlab['gitlab_rails']['redis_port'] ||= 6379
      end

      if gitlab_ci['redis_host']
        Gitlab['gitlab_ci']['redis_port'] ||= 6379
      end

      if gitlab_rails['redis_host'] &&
        gitlab_rails.values_at('redis_host', 'redis_port') == gitlab_ci.values_at('redis_host', 'redis_port')
        Chef::Log.warn "gitlab-rails and gitlab-ci are configured to connect to "\
                       "the same Redis instance. This is not recommended."
      end
    end

    def parse_postgresql_settings
      # If the user wants to run the internal Postgres service using an alternative
      # DB username, host or port, then those settings should also be applied to
      # gitlab-rails and gitlab-ci.
      [
        # %w{gitlab_rails db_username} corresponds to
        # Gitlab['gitlab_rails']['db_username'], etc.
        [%w{gitlab_rails db_username}, %w{postgresql sql_user}],
        [%w{gitlab_rails db_host}, %w{postgresql listen_address}],
        [%w{gitlab_rails db_port}, %w{postgresql port}],
        [%w{gitlab_ci db_username}, %w{postgresql sql_ci_user}],
        [%w{gitlab_ci db_host}, %w{postgresql listen_address}],
        [%w{gitlab_ci db_port}, %w{postgresql port}],
      ].each do |left, right|
        if ! Gitlab[left.first][left.last].nil?
          # If the user explicitly sets a value for e.g.
          # gitlab_rails['db_port'] in gitlab.rb then we should never override
          # that.
          next
        end

        better_value_from_gitlab_rb = Gitlab[right.first][right.last]
        default_from_attributes = node['gitlab'][right.first.gsub('_', '-')][right.last]
        Gitlab[left.first][left.last] = better_value_from_gitlab_rb || default_from_attributes
      end
    end

    def parse_mattermost_postgresql_settings
      value_from_gitlab_rb = Gitlab['mattermost']['sql_data_source']

      attributes_values = []
      [
        %w{postgresql sql_mattermost_user},
        %w{postgresql unix_socket_directory},
        %w{postgresql port},
        %w{mattermost database_name}
      ].each do |value|
        attributes_values << (Gitlab[value.first][value.last] || node['gitlab'][value.first][value.last])
      end

      value_from_attributes = "user=#{attributes_values[0]} host=#{attributes_values[1]} port=#{attributes_values[2]} dbname=#{attributes_values[3]}"
      Gitlab['mattermost']['sql_data_source'] = value_from_gitlab_rb || value_from_attributes

      if Gitlab['mattermost']['sql_data_source_replicas'].nil? && node['gitlab']['mattermost']['sql_data_source_replicas'].empty?
        Gitlab['mattermost']['sql_data_source_replicas'] = [Gitlab['mattermost']['sql_data_source']]
      end
    end

    def parse_unicorn_listen_address
      unicorn_socket = unicorn['socket'] || node['gitlab']['unicorn']['socket']
      if gitlab_workhorse['auth_backend'].nil?
        # The user has no custom settings for connecting workhorse to unicorn. Let's
        # do what we think is best.
        gitlab_workhorse['auth_socket'] = unicorn_socket
      end
    end

    def parse_nginx_listen_address
      return unless nginx['listen_address']

      # The user specified a custom NGINX listen address with the legacy
      # listen_address option. We have to convert it to the new
      # listen_addresses setting.
      nginx['listen_addresses'] = [nginx['listen_address']]
    end

    def parse_nginx_listen_ports
      [
        [%w{nginx listen_port}, %w{gitlab_rails gitlab_port}],
        [%w{ci_nginx listen_port}, %w{gitlab_ci gitlab_ci_port}],
        [%w{mattermost_nginx listen_port}, %w{mattermost port}],
        [%w{pages_nginx listen_port}, %w{gitlab_rails pages_port}],

      ].each do |left, right|
        if !Gitlab[left.first][left.last].nil?
          next
        end

        default_set_gitlab_port = node['gitlab'][right.first.gsub('_', '-')][right.last]
        user_set_gitlab_port = Gitlab[right.first][right.last]

        Gitlab[left.first][left.last] = user_set_gitlab_port || default_set_gitlab_port
      end
    end

    def parse_proxy_headers(app, https)
      values_from_gitlab_rb = Gitlab[app]['proxy_set_headers']
      default_from_attributes = node['gitlab'][app]['proxy_set_headers'].to_hash

      default_from_attributes = if https
                                  default_from_attributes.merge({
                                                                 'X-Forwarded-Proto' => "https",
                                                                 'X-Forwarded-Ssl' => "on"
                                                               })
                                else
                                  default_from_attributes.merge({
                                                                 "X-Forwarded-Proto" => "http"
                                                               })
                                end

      if values_from_gitlab_rb
        values_from_gitlab_rb.each do |key, value|
          default_from_attributes.delete(key) if value.nil?
        end

        default_from_attributes = default_from_attributes.merge(values_from_gitlab_rb.to_hash)
      end

      Gitlab[app]['proxy_set_headers'] = default_from_attributes
    end

    def parse_gitlab_trusted_proxies
      Gitlab['nginx']['real_ip_trusted_addresses'] ||= node['gitlab']['nginx']['real_ip_trusted_addresses']
      Gitlab['gitlab_rails']['trusted_proxies'] ||= Gitlab['nginx']['real_ip_trusted_addresses']
    end

    def parse_ci_external_url
      return unless ci_external_url
      # Disable gitlab_ci. This setting will be picked up by parse_gitlab_ci
      # The code below will be removed in the next major release.
      gitlab_ci['enable'] = false

      uri = URI(ci_external_url.to_s)

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
      return unless gitlab_ci['enable']

      ci_unicorn['enable'] = true if ci_unicorn['enable'].nil?
      ci_sidekiq['enable'] = true if ci_sidekiq['enable'].nil?
      ci_redis['enable'] = true if ci_redis['enable'].nil?
      ci_nginx['enable'] = true if ci_nginx['enable'].nil?
    end

    def parse_pages_external_url
      return unless pages_external_url

      gitlab_rails['pages_enabled'] = true if gitlab_rails['pages_enabled'].nil?
      gitlab_pages['enable'] = true if gitlab_pages['enable'].nil?

      uri = URI(pages_external_url.to_s)

      unless uri.host
        raise "GitLab Pages external URL must include a schema and FQDN, e.g. http://pages.example.com/"
      end

      Gitlab['gitlab_rails']['pages_host'] = uri.host
      Gitlab['gitlab_rails']['pages_port'] = uri.port

      case uri.scheme
      when "http"
        Gitlab['gitlab_rails']['pages_https'] = false
      when "https"
        Gitlab['gitlab_rails']['pages_https'] = true
        Gitlab['pages_nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{uri.host}.crt"
        Gitlab['pages_nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{uri.host}.key"
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
      return unless gitlab_pages['enable']

      gitlab_pages['domain'] = Gitlab['gitlab_rails']['pages_host']

      if gitlab_pages['external_https']
        Gitlab['gitlab_pages']['cert'] ||= "/etc/gitlab/ssl/#{Gitlab['gitlab_pages']['domain']}.crt"
        Gitlab['gitlab_pages']['cert_key'] ||= "/etc/gitlab/ssl/#{Gitlab['gitlab_pages']['domain']}.key"
      end

      Gitlab['gitlab_pages']['pages_root'] ||= (gitlab_rails['pages_path'] || File.join(Gitlab['gitlab_rails']['shared_path'], 'pages'))
    end

    def parse_mattermost_external_url
      return unless mattermost_external_url

      mattermost['enable'] = true if mattermost['enable'].nil?

      uri = URI(mattermost_external_url.to_s)

      unless uri.host
        raise "GitLab Mattermost external URL must include a schema and FQDN, e.g. http://mattermost.example.com/"
      end

      Gitlab['mattermost']['host'] = uri.host

      case uri.scheme
      when "http"
        Gitlab['mattermost']['service_use_ssl'] = false
      when "https"
        Gitlab['mattermost']['service_use_ssl'] = true
        Gitlab['mattermost_nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{uri.host}.crt"
        Gitlab['mattermost_nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{uri.host}.key"
      else
        raise "Unsupported external URL scheme: #{uri.scheme}"
      end

      unless ["", "/"].include?(uri.path)
        raise "Unsupported CI external URL path: #{uri.path}"
      end

      Gitlab['mattermost']['port'] = uri.port
    end

    def parse_gitlab_mattermost
      return unless mattermost['enable']

      mattermost_nginx['enable'] = true if mattermost_nginx['enable'].nil?
    end

    def parse_incoming_email
      return unless gitlab_rails['incoming_email_enabled']

      mailroom['enable'] = true if mailroom['enable'].nil?
    end

    def parse_registry_external_url
      return unless registry_external_url

      uri = URI(registry_external_url.to_s)

      unless uri.host
        raise "GitLab Container Registry external URL must include a schema and FQDN, e.g. https://registry.example.com/"
      end

      registry['enable'] = true if registry['enable'].nil?
      Gitlab['gitlab_rails']['registry_enabled'] = true if registry['enable']

      Gitlab['registry']['registry_http_addr'] ||= "localhost:5000"
      Gitlab['registry']['registry_http_addr'].gsub(/^https?\:\/\/(www.)?/,'')
      Gitlab['gitlab_rails']['registry_api_url'] ||= "http://#{Gitlab['registry']['registry_http_addr']}"
      Gitlab['registry']['token_realm'] ||= external_url
      Gitlab['gitlab_rails']['registry_host'] = uri.host
      Gitlab['registry_nginx']['listen_port'] ||= uri.port

      case uri.scheme
      when "http"
        Gitlab['registry_nginx']['https'] ||= false
        parse_proxy_headers('registry_nginx', false)
      when "https"
        Gitlab['registry_nginx']['https'] ||= true
        Gitlab['registry_nginx']['ssl_certificate'] ||= "/etc/gitlab/ssl/#{uri.host}.crt"
        Gitlab['registry_nginx']['ssl_certificate_key'] ||= "/etc/gitlab/ssl/#{uri.host}.key"
        parse_proxy_headers('registry_nginx', true)
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
      return unless registry['enable']

      gitlab_rails['registry_path'] = "#{gitlab_rails['shared_path']}/registry" if gitlab_rails['registry_path'].nil?
      Gitlab['registry']['storage_delete_enabled'] ||= node['gitlab']['registry']['storage_delete_enabled']

      Gitlab['registry']['storage'] ||= {
        'filesystem' => { 'rootdirectory' => gitlab_rails['registry_path'] }
      }

      Gitlab['registry']['storage']['cache'] ||= {'blobdescriptor'=>'inmemory'}
      Gitlab['registry']['storage']['delete'] ||= {'enabled' => Gitlab['registry']['storage_delete_enabled']}
    end

    def disable_gitlab_rails_services
      if gitlab_rails["enable"] == false
        redis["enable"] = false
        unicorn["enable"] = false
        sidekiq["enable"] = false
        gitlab_workhorse["enable"] = false
      end
    end

    def generate_hash
      # NOTE: If you are adding a new service
      # and that service has logging, make sure you add the service to
      # the array in parse_udp_log_shipping.
      results = { "gitlab" => {} }
      [
        "bootstrap",
        "omnibus_gitconfig",
        "manage_accounts",
        "manage_storage_directories",
        "user",
        "redis",
        "ci_redis",
        "gitlab_rails",
        "gitlab_ci",
        "gitlab_shell",
        "unicorn",
        "ci_unicorn",
        "sidekiq",
        "ci_sidekiq",
        "gitlab_workhorse",
        "mailroom",
        "nginx",
        "ci_nginx",
        "mattermost_nginx",
        "pages_nginx",
        "registry_nginx",
        "logging",
        "remote_syslog",
        "logrotate",
        "high_availability",
        "postgresql",
        "web_server",
        "mattermost",
        "external_url",
        "ci_external_url",
        "mattermost_external_url",
        "pages_external_url",
        "gitlab_pages",
        "registry"
      ].each do |key|
        rkey = key.gsub('_', '-')
        results['gitlab'][rkey] = Gitlab[key]
      end

      results
    end

    def generate_config(node_name)
      generate_secrets(node_name)
      parse_gitlab_git_http_server
      parse_external_url
      parse_git_data_dir
      parse_shared_dir
      parse_artifacts_dir
      parse_lfs_objects_dir
      parse_pages_dir
      parse_udp_log_shipping
      parse_redis_settings
      parse_postgresql_settings
      parse_mattermost_postgresql_settings
      # Parse ci_external_url _before_ gitlab_ci settings so that the user
      # can turn on gitlab_ci by only specifying ci_external_url
      parse_ci_external_url
      parse_pages_external_url
      parse_mattermost_external_url
      parse_registry_external_url
      parse_unicorn_listen_address
      parse_nginx_listen_address
      parse_nginx_listen_ports
      parse_gitlab_trusted_proxies
      parse_gitlab_ci
      parse_gitlab_mattermost
      parse_incoming_email
      parse_gitlab_pages_daemon
      parse_registry
      disable_gitlab_rails_services
      # The last step is to convert underscores to hyphens in top-level keys
      generate_hash
    end
  end
end
