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

####
# omnibus options
####
default['gitlab']['bootstrap']['enable'] = true
# Create users and groups needed for the package
default['gitlab']['manage_accounts']['enable'] = true

# Create directories with correct permissions and ownership required by the pkg
default['gitlab']['manage_storage_directories']['enable'] = true
default['gitlab']['manage_storage_directories']['manage_etc'] = true

# A tmpfs mount point directory for runtime files, actual default is located in libraries/gitlab_rails.rb.
default['gitlab']['runtime_dir'] = nil

####
# The Git User that services run as
####
# The username for the chef services user
default['gitlab']['user']['username'] = "git"
default['gitlab']['user']['group'] = "git"
default['gitlab']['user']['uid'] = nil
default['gitlab']['user']['gid'] = nil
# The shell for the chef services user
default['gitlab']['user']['shell'] = "/bin/sh"
# The home directory for the chef services user
default['gitlab']['user']['home'] = "/var/opt/gitlab"
default['gitlab']['user']['git_user_name'] = "GitLab"
default['gitlab']['user']['git_user_email'] = "gitlab@#{node['fqdn']}"

####
# GitLab Rails app
####
default['gitlab']['gitlab_rails']['enable'] = true
default['gitlab']['gitlab_rails']['dir'] = "/var/opt/gitlab/gitlab-rails"
default['gitlab']['gitlab_rails']['log_directory'] = "/var/log/gitlab/gitlab-rails"
default['gitlab']['gitlab_rails']['environment'] = 'production'
default['gitlab']['gitlab_rails']['env'] = {
  'SIDEKIQ_MEMORY_KILLER_MAX_RSS' => '2000000',
  # PATH to set on the environment
  # defaults to /opt/gitlab/embedded/bin:/bin:/usr/bin. The install-dir path is set at build time
  'PATH' => "#{node['package']['install-dir']}/bin:#{node['package']['install-dir']}/embedded/bin:/bin:/usr/bin",
  # Charlock Holmes and libicu will report U_FILE_ACCESS_ERROR if this is not set to the right path
  # See https://gitlab.com/gitlab-org/gitlab-foss/issues/17415#note_13868167
  'ICU_DATA' => "#{node['package']['install-dir']}/embedded/share/icu/current",
  'PYTHONPATH' => "#{node['package']['install-dir']}/embedded/lib/python3.9/site-packages",
  # Prevent ExecJS from complaining that Node is not installed in production
  'EXECJS_RUNTIME' => 'Disabled',
  # Prevent excessive system calls: #3530,
  # Details: https://blog.packagecloud.io/eng/2017/02/21/set-environment-variable-save-thousands-of-system-calls/
  'TZ' => ':/etc/localtime',
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/",
  'SSL_CERT_FILE' => "#{node['package']['install-dir']}/embedded/ssl/cert.pem"
}

default['gitlab']['gitlab_rails']['internal_api_url'] = nil
default['gitlab']['gitlab_rails']['uploads_directory'] = "/var/opt/gitlab/gitlab-rails/uploads"
default['gitlab']['gitlab_rails']['auto_migrate'] = true
default['gitlab']['gitlab_rails']['rake_cache_clear'] = true
default['gitlab']['gitlab_rails']['gitlab_host'] = node['fqdn']
default['gitlab']['gitlab_rails']['gitlab_port'] = 80
default['gitlab']['gitlab_rails']['gitlab_https'] = false
default['gitlab']['gitlab_rails']['gitlab_ssh_user'] = nil
default['gitlab']['gitlab_rails']['gitlab_ssh_host'] = nil
default['gitlab']['gitlab_rails']['time_zone'] = nil
default['gitlab']['gitlab_rails']['cdn_host'] = nil
default['gitlab']['gitlab_rails']['gitlab_email_from'] = nil
default['gitlab']['gitlab_rails']['gitlab_email_display_name'] = nil
default['gitlab']['gitlab_rails']['gitlab_email_subject_suffix'] = nil
default['gitlab']['gitlab_rails']['gitlab_email_smime_enabled'] = false
default['gitlab']['gitlab_rails']['gitlab_email_smime_key_file'] = '/etc/gitlab/ssl/gitlab_smime.key'
default['gitlab']['gitlab_rails']['gitlab_email_smime_cert_file'] = '/etc/gitlab/ssl/gitlab_smime.crt'
default['gitlab']['gitlab_rails']['gitlab_email_smime_ca_certs_file'] = nil
default['gitlab']['gitlab_rails']['gitlab_username_changing_enabled'] = nil
default['gitlab']['gitlab_rails']['gitlab_default_theme'] = nil
default['gitlab']['gitlab_rails']['gitlab_default_projects_features_issues'] = nil
default['gitlab']['gitlab_rails']['gitlab_default_projects_features_merge_requests'] = nil
default['gitlab']['gitlab_rails']['gitlab_default_projects_features_wiki'] = nil
default['gitlab']['gitlab_rails']['gitlab_default_projects_features_wall'] = nil
default['gitlab']['gitlab_rails']['gitlab_default_projects_features_snippets'] = nil
default['gitlab']['gitlab_rails']['gitlab_default_projects_features_builds'] = nil
default['gitlab']['gitlab_rails']['gitlab_default_projects_features_container_registry'] = nil
default['gitlab']['gitlab_rails']['gitlab_issue_closing_pattern'] = nil
default['gitlab']['gitlab_rails']['gitlab_repository_downloads_path'] = nil
default['gitlab']['gitlab_rails']['gravatar_plain_url'] = nil
default['gitlab']['gitlab_rails']['gravatar_ssl_url'] = nil
default['gitlab']['gitlab_rails']['stuck_ci_jobs_worker_cron'] = nil
default['gitlab']['gitlab_rails']['expire_build_artifacts_worker_cron'] = nil
default['gitlab']['gitlab_rails']['environments_auto_stop_cron_worker_cron'] = nil
default['gitlab']['gitlab_rails']['pipeline_schedule_worker_cron'] = nil
default['gitlab']['gitlab_rails']['repository_check_worker_cron'] = nil
default['gitlab']['gitlab_rails']['admin_email_worker_cron'] = nil
default['gitlab']['gitlab_rails']['personal_access_tokens_expiring_worker_cron'] = nil
default['gitlab']['gitlab_rails']['personal_access_tokens_expired_notification_worker_cron'] = nil
default['gitlab']['gitlab_rails']['repository_archive_cache_worker_cron'] = nil
default['gitlab']['gitlab_rails']['ci_archive_traces_cron_worker'] = nil
default['gitlab']['gitlab_rails']['pages_domain_verification_cron_worker'] = nil
default['gitlab']['gitlab_rails']['pages_domain_ssl_renewal_cron_worker'] = nil
default['gitlab']['gitlab_rails']['pages_domain_removal_cron_worker'] = nil
default['gitlab']['gitlab_rails']['remove_unaccepted_member_invites_cron_worker'] = nil
default['gitlab']['gitlab_rails']['schedule_migrate_external_diffs_worker_cron'] = nil
default['gitlab']['gitlab_rails']['ci_platform_metrics_update_cron_worker'] = nil
default['gitlab']['gitlab_rails']['historical_data_worker_cron'] = nil
default['gitlab']['gitlab_rails']['analytics_devops_adoption_create_all_snapshots_worker_cron'] = nil
default['gitlab']['gitlab_rails']['ldap_sync_worker_cron'] = nil
default['gitlab']['gitlab_rails']['ldap_group_sync_worker_cron'] = nil
default['gitlab']['gitlab_rails']['geo_repository_sync_worker_cron'] = nil
default['gitlab']['gitlab_rails']['geo_secondary_registry_consistency_worker'] = nil
default['gitlab']['gitlab_rails']['geo_secondary_usage_data_cron_worker'] = nil
default['gitlab']['gitlab_rails']['geo_prune_event_log_worker_cron'] = nil
default['gitlab']['gitlab_rails']['geo_repository_verification_primary_batch_worker_cron'] = nil
default['gitlab']['gitlab_rails']['geo_repository_verification_secondary_scheduler_worker_cron'] = nil
default['gitlab']['gitlab_rails']['analytics_usage_trends_count_job_trigger_worker_cron'] = nil
default['gitlab']['gitlab_rails']['member_invitation_reminder_emails_worker_cron'] = nil
default['gitlab']['gitlab_rails']['user_status_cleanup_batch_worker_cron'] = nil
default['gitlab']['gitlab_rails']['loose_foreign_keys_cleanup_worker_cron'] = nil
default['gitlab']['gitlab_rails']['elastic_index_bulk_cron'] = nil
default['gitlab']['gitlab_rails']['incoming_email_enabled'] = false
default['gitlab']['gitlab_rails']['incoming_email_address'] = nil
default['gitlab']['gitlab_rails']['incoming_email_host'] = nil
default['gitlab']['gitlab_rails']['incoming_email_port'] = nil
default['gitlab']['gitlab_rails']['incoming_email_ssl'] = nil
default['gitlab']['gitlab_rails']['incoming_email_start_tls'] = nil
default['gitlab']['gitlab_rails']['incoming_email_email'] = nil
default['gitlab']['gitlab_rails']['incoming_email_password'] = nil
default['gitlab']['gitlab_rails']['incoming_email_mailbox_name'] = "inbox"
default['gitlab']['gitlab_rails']['incoming_email_idle_timeout'] = nil
default['gitlab']['gitlab_rails']['incoming_email_log_file'] = "/var/log/gitlab/mailroom/mail_room_json.log" # file path of internal `mail_room` JSON logs
default['gitlab']['gitlab_rails']['incoming_email_delete_after_delivery'] = true
default['gitlab']['gitlab_rails']['incoming_email_expunge_deleted'] = nil
default['gitlab']['gitlab_rails']['incoming_email_inbox_method'] = "imap"
default['gitlab']['gitlab_rails']['incoming_email_inbox_options'] = nil
default['gitlab']['gitlab_rails']['incoming_email_delivery_method'] = "webhook"
default['gitlab']['gitlab_rails']['incoming_email_auth_token'] = nil

default['gitlab']['gitlab_rails']['service_desk_email_enabled'] = false
default['gitlab']['gitlab_rails']['service_desk_email_address'] = nil
default['gitlab']['gitlab_rails']['service_desk_email_host'] = nil
default['gitlab']['gitlab_rails']['service_desk_email_port'] = nil
default['gitlab']['gitlab_rails']['service_desk_email_ssl'] = nil
default['gitlab']['gitlab_rails']['service_desk_email_start_tls'] = nil
default['gitlab']['gitlab_rails']['service_desk_email_email'] = nil
default['gitlab']['gitlab_rails']['service_desk_email_password'] = nil
default['gitlab']['gitlab_rails']['service_desk_email_mailbox_name'] = "inbox"
default['gitlab']['gitlab_rails']['service_desk_email_idle_timeout'] = nil
default['gitlab']['gitlab_rails']['service_desk_email_log_file'] = "/var/log/gitlab/mailroom/mail_room_json.log" # file path of internal `mail_room` JSON logs
default['gitlab']['gitlab_rails']['service_desk_email_inbox_method'] = "imap"
default['gitlab']['gitlab_rails']['service_desk_email_inbox_inbox_options'] = nil
default['gitlab']['gitlab_rails']['service_desk_email_delivery_method'] = "webhook"
default['gitlab']['gitlab_rails']['service_desk_email_auth_token'] = nil

default['gitlab']['gitlab_rails']['namespaces_in_product_marketing_emails_worker_cron'] = nil
default['gitlab']['gitlab_rails']['ssh_keys_expired_notification_worker_cron'] = nil
default['gitlab']['gitlab_rails']['ssh_keys_expiring_soon_notification_worker_cron'] = nil

default['gitlab']['gitlab_rails']['ci_runners_stale_group_runners_prune_worker_cron'] = nil
default['gitlab']['gitlab_rails']['ci_runner_versions_reconciliation_worker_cron'] = nil
default['gitlab']['gitlab_rails']['ci_runners_stale_machines_cleanup_worker_cron'] = nil

# Consolidated object storage config
default['gitlab']['gitlab_rails']['object_store']['enabled'] = false
default['gitlab']['gitlab_rails']['object_store']['connection'] = {}
default['gitlab']['gitlab_rails']['object_store']['storage_options'] = {}
default['gitlab']['gitlab_rails']['object_store']['proxy_download'] = false
default['gitlab']['gitlab_rails']['object_store']['objects'] = {}
default['gitlab']['gitlab_rails']['object_store']['objects']['artifacts'] = {}
default['gitlab']['gitlab_rails']['object_store']['objects']['artifacts']['bucket'] = nil
default['gitlab']['gitlab_rails']['object_store']['objects']['external_diffs'] = {}
default['gitlab']['gitlab_rails']['object_store']['objects']['external_diffs']['bucket'] = false
default['gitlab']['gitlab_rails']['object_store']['objects']['lfs'] = {}
default['gitlab']['gitlab_rails']['object_store']['objects']['lfs']['bucket'] = nil
default['gitlab']['gitlab_rails']['object_store']['objects']['uploads'] = {}
default['gitlab']['gitlab_rails']['object_store']['objects']['uploads']['bucket'] = nil
default['gitlab']['gitlab_rails']['object_store']['objects']['packages'] = {}
default['gitlab']['gitlab_rails']['object_store']['objects']['packages']['bucket'] = nil
default['gitlab']['gitlab_rails']['object_store']['objects']['dependency_proxy'] = {}
default['gitlab']['gitlab_rails']['object_store']['objects']['dependency_proxy']['bucket'] = nil
default['gitlab']['gitlab_rails']['object_store']['objects']['terraform_state'] = {}
default['gitlab']['gitlab_rails']['object_store']['objects']['terraform_state']['bucket'] = nil
default['gitlab']['gitlab_rails']['object_store']['objects']['ci_secure_files'] = {}
default['gitlab']['gitlab_rails']['object_store']['objects']['ci_secure_files']['bucket'] = nil
default['gitlab']['gitlab_rails']['object_store']['objects']['pages'] = {}
default['gitlab']['gitlab_rails']['object_store']['objects']['pages']['bucket'] = nil

default['gitlab']['gitlab_rails']['artifacts_enabled'] = true
default['gitlab']['gitlab_rails']['artifacts_path'] = nil
default['gitlab']['gitlab_rails']['artifacts_object_store_enabled'] = false
default['gitlab']['gitlab_rails']['artifacts_object_store_proxy_download'] = false
default['gitlab']['gitlab_rails']['artifacts_object_store_remote_directory'] = 'artifacts'
default['gitlab']['gitlab_rails']['artifacts_object_store_connection'] = {}
default['gitlab']['gitlab_rails']['external_diffs_enabled'] = nil
default['gitlab']['gitlab_rails']['external_diffs_when'] = nil
default['gitlab']['gitlab_rails']['external_diffs_storage_path'] = nil
default['gitlab']['gitlab_rails']['external_diffs_object_store_enabled'] = false
default['gitlab']['gitlab_rails']['external_diffs_object_store_proxy_download'] = false
default['gitlab']['gitlab_rails']['external_diffs_object_store_remote_directory'] = 'external-diffs'
default['gitlab']['gitlab_rails']['external_diffs_object_store_connection'] = {}
default['gitlab']['gitlab_rails']['lfs_enabled'] = nil
default['gitlab']['gitlab_rails']['lfs_storage_path'] = nil
default['gitlab']['gitlab_rails']['lfs_object_store_enabled'] = false
default['gitlab']['gitlab_rails']['lfs_object_store_proxy_download'] = false
default['gitlab']['gitlab_rails']['lfs_object_store_remote_directory'] = 'lfs-objects'
default['gitlab']['gitlab_rails']['lfs_object_store_connection'] = {}
default['gitlab']['gitlab_rails']['uploads_storage_path'] = nil
default['gitlab']['gitlab_rails']['uploads_base_dir'] = nil
default['gitlab']['gitlab_rails']['uploads_object_store_enabled'] = false
default['gitlab']['gitlab_rails']['uploads_object_store_proxy_download'] = false
default['gitlab']['gitlab_rails']['uploads_object_store_remote_directory'] = 'uploads'
default['gitlab']['gitlab_rails']['uploads_object_store_connection'] = {}
default['gitlab']['gitlab_rails']['packages_enabled'] = nil
default['gitlab']['gitlab_rails']['packages_storage_path'] = nil
default['gitlab']['gitlab_rails']['packages_object_store_enabled'] = false
default['gitlab']['gitlab_rails']['packages_object_store_proxy_download'] = false
default['gitlab']['gitlab_rails']['packages_object_store_remote_directory'] = 'packages'
default['gitlab']['gitlab_rails']['packages_object_store_connection'] = {}
default['gitlab']['gitlab_rails']['dependency_proxy_enabled'] = nil
default['gitlab']['gitlab_rails']['dependency_proxy_storage_path'] = nil
default['gitlab']['gitlab_rails']['dependency_proxy_object_store_enabled'] = false
default['gitlab']['gitlab_rails']['dependency_proxy_object_store_proxy_download'] = false
default['gitlab']['gitlab_rails']['dependency_proxy_object_store_remote_directory'] = 'dependency_proxy'
default['gitlab']['gitlab_rails']['dependency_proxy_object_store_connection'] = {}
default['gitlab']['gitlab_rails']['terraform_state_enabled'] = nil
default['gitlab']['gitlab_rails']['terraform_state_storage_path'] = nil
default['gitlab']['gitlab_rails']['terraform_state_object_store_enabled'] = false
default['gitlab']['gitlab_rails']['terraform_state_object_store_remote_directory'] = 'terraform'
default['gitlab']['gitlab_rails']['terraform_state_object_store_connection'] = {}
default['gitlab']['gitlab_rails']['ci_secure_files_enabled'] = nil
default['gitlab']['gitlab_rails']['ci_secure_files_storage_path'] = nil
default['gitlab']['gitlab_rails']['ci_secure_files_object_store_enabled'] = false
default['gitlab']['gitlab_rails']['ci_secure_files_object_store_remote_directory'] = 'ci-secure-files'
default['gitlab']['gitlab_rails']['ci_secure_files_object_store_connection'] = {}
default['gitlab']['gitlab_rails']['ldap_enabled'] = false
default['gitlab']['gitlab_rails']['prevent_ldap_sign_in'] = false
default['gitlab']['gitlab_rails']['ldap_servers'] = []
default['gitlab']['gitlab_rails']['pages_enabled'] = false
default['gitlab']['gitlab_rails']['pages_host'] = nil
default['gitlab']['gitlab_rails']['pages_port'] = nil
default['gitlab']['gitlab_rails']['pages_https'] = false
default['gitlab']['gitlab_rails']['pages_path'] = nil
default['gitlab']['gitlab_rails']['pages_object_store_enabled'] = false
default['gitlab']['gitlab_rails']['pages_object_store_remote_directory'] = 'pages'
default['gitlab']['gitlab_rails']['pages_object_store_connection'] = {}
default['gitlab']['gitlab_rails']['pages_local_store_enabled'] = true
default['gitlab']['gitlab_rails']['pages_local_store_path'] = nil
default['gitlab']['gitlab_rails']['registry_enabled'] = false
default['gitlab']['gitlab_rails']['registry_host'] = nil
default['gitlab']['gitlab_rails']['registry_port'] = nil
default['gitlab']['gitlab_rails']['registry_api_url'] = nil
default['gitlab']['gitlab_rails']['registry_key_path'] = nil
default['gitlab']['gitlab_rails']['registry_path'] = nil
default['gitlab']['gitlab_rails']['registry_issuer'] = "omnibus-gitlab-issuer"
default['gitlab']['gitlab_rails']['registry_notification_secret'] = nil
default['gitlab']['gitlab_rails']['impersonation_enabled'] = nil
default['gitlab']['gitlab_rails']['disable_animations'] = false
default['gitlab']['gitlab_rails']['application_settings_cache_seconds'] = nil
default['gitlab']['gitlab_rails']['sentry_enabled'] = false
default['gitlab']['gitlab_rails']['sentry_dsn'] = nil
default['gitlab']['gitlab_rails']['sentry_clientside_dsn'] = nil
default['gitlab']['gitlab_rails']['sentry_environment'] = nil
default['gitlab']['gitlab_rails']['usage_ping_enabled'] = nil
# Defaults set in libraries/gitlab_rails.rb
default['gitlab']['gitlab_rails']['repositories_storages'] = {}

####
# These LDAP settings are deprecated in favor of the new syntax. They are kept here for backwards compatibility.
# Check
# https://gitlab.com/gitlab-org/omnibus-gitlab/blob/935ab9e1700bfe8db6ba084e3687658d8921716f/README.md#setting-up-ldap-sign-in
# for the new syntax.
default['gitlab']['gitlab_rails']['ldap_host'] = nil
default['gitlab']['gitlab_rails']['ldap_base'] = nil
default['gitlab']['gitlab_rails']['ldap_port'] = nil
default['gitlab']['gitlab_rails']['ldap_uid'] = nil
default['gitlab']['gitlab_rails']['ldap_method'] = nil
default['gitlab']['gitlab_rails']['ldap_bind_dn'] = nil
default['gitlab']['gitlab_rails']['ldap_password'] = nil
default['gitlab']['gitlab_rails']['ldap_allow_username_or_email_login'] = nil
default['gitlab']['gitlab_rails']['ldap_lowercase_usernames'] = nil
default['gitlab']['gitlab_rails']['ldap_user_filter'] = nil
default['gitlab']['gitlab_rails']['ldap_group_base'] = nil
default['gitlab']['gitlab_rails']['ldap_admin_group'] = nil
default['gitlab']['gitlab_rails']['ldap_sync_ssh_keys'] = nil
default['gitlab']['gitlab_rails']['ldap_sync_time'] = nil
default['gitlab']['gitlab_rails']['ldap_active_directory'] = nil
####

default['gitlab']['gitlab_rails']['smartcard_enabled'] = false
default['gitlab']['gitlab_rails']['smartcard_ca_file'] = "/etc/gitlab/ssl/CA.pem"
default['gitlab']['gitlab_rails']['smartcard_client_certificate_required_host'] = nil
default['gitlab']['gitlab_rails']['smartcard_client_certificate_required_port'] = 3444
default['gitlab']['gitlab_rails']['smartcard_required_for_git_access'] = false
default['gitlab']['gitlab_rails']['smartcard_san_extensions'] = false

default['gitlab']['gitlab_rails']['microsoft_graph_mailer_enabled'] = false
default['gitlab']['gitlab_rails']['microsoft_graph_mailer_user_id'] = nil
default['gitlab']['gitlab_rails']['microsoft_graph_mailer_tenant'] = nil
default['gitlab']['gitlab_rails']['microsoft_graph_mailer_client_id'] = nil
default['gitlab']['gitlab_rails']['microsoft_graph_mailer_client_secret'] = nil
default['gitlab']['gitlab_rails']['microsoft_graph_mailer_azure_ad_endpoint'] = nil
default['gitlab']['gitlab_rails']['microsoft_graph_mailer_graph_endpoint'] = nil

default['gitlab']['gitlab_rails']['kerberos_enabled'] = nil
default['gitlab']['gitlab_rails']['kerberos_keytab'] = nil
default['gitlab']['gitlab_rails']['kerberos_service_principal_name'] = nil
default['gitlab']['gitlab_rails']['kerberos_simple_ldap_linking_allowed_realms'] = nil
default['gitlab']['gitlab_rails']['kerberos_use_dedicated_port'] = nil
default['gitlab']['gitlab_rails']['kerberos_port'] = nil
default['gitlab']['gitlab_rails']['kerberos_https'] = nil

default['gitlab']['gitlab_rails']['omniauth_enabled'] = nil
default['gitlab']['gitlab_rails']['omniauth_allow_single_sign_on'] = ['saml']
default['gitlab']['gitlab_rails']['omniauth_sync_email_from_provider'] = nil
default['gitlab']['gitlab_rails']['omniauth_sync_profile_from_provider'] = nil
default['gitlab']['gitlab_rails']['omniauth_sync_profile_attributes'] = nil
default['gitlab']['gitlab_rails']['omniauth_auto_sign_in_with_provider'] = nil
default['gitlab']['gitlab_rails']['omniauth_block_auto_created_users'] = nil
default['gitlab']['gitlab_rails']['omniauth_auto_link_ldap_user'] = nil
default['gitlab']['gitlab_rails']['omniauth_auto_link_saml_user'] = nil
default['gitlab']['gitlab_rails']['omniauth_auto_link_user'] = nil
default['gitlab']['gitlab_rails']['omniauth_external_providers'] = nil
default['gitlab']['gitlab_rails']['omniauth_providers'] = []
default['gitlab']['gitlab_rails']['omniauth_cas3_session_duration'] = nil
default['gitlab']['gitlab_rails']['omniauth_allow_bypass_two_factor'] = nil
default['gitlab']['gitlab_rails']['omniauth_saml_message_max_byte_size'] = nil

default['gitlab']['gitlab_rails']['forti_authenticator_enabled'] = false
default['gitlab']['gitlab_rails']['forti_authenticator_host'] = nil
default['gitlab']['gitlab_rails']['forti_authenticator_port'] = 443
default['gitlab']['gitlab_rails']['forti_authenticator_username'] = nil
default['gitlab']['gitlab_rails']['forti_authenticator_access_token'] = nil

default['gitlab']['gitlab_rails']['duo_auth_enabled'] = false
default['gitlab']['gitlab_rails']['duo_auth_integration_key'] = nil
default['gitlab']['gitlab_rails']['duo_auth_secret_key'] = nil
default['gitlab']['gitlab_rails']['duo_auth_hostname'] = nil

default['gitlab']['gitlab_rails']['forti_token_cloud_enabled'] = false
default['gitlab']['gitlab_rails']['forti_token_cloud_client_id'] = nil
default['gitlab']['gitlab_rails']['forti_token_cloud_client_secret'] = nil

default['gitlab']['gitlab_rails']['shared_path'] = "/var/opt/gitlab/gitlab-rails/shared"
default['gitlab']['gitlab_rails']['encrypted_settings_path'] = nil

default['gitlab']['gitlab_rails']['backup_path'] = "/var/opt/gitlab/backups"
default['gitlab']['gitlab_rails']['backup_gitaly_backup_path'] = "/opt/gitlab/embedded/bin/gitaly-backup"
default['gitlab']['gitlab_rails']['manage_backup_path'] = true
default['gitlab']['gitlab_rails']['backup_archive_permissions'] = nil
default['gitlab']['gitlab_rails']['backup_pg_schema'] = nil
default['gitlab']['gitlab_rails']['backup_keep_time'] = nil
default['gitlab']['gitlab_rails']['backup_upload_connection'] = nil
default['gitlab']['gitlab_rails']['backup_upload_remote_directory'] = nil
default['gitlab']['gitlab_rails']['backup_upload_storage_options'] = {}
default['gitlab']['gitlab_rails']['backup_multipart_chunk_size'] = nil
default['gitlab']['gitlab_rails']['backup_encryption'] = nil
default['gitlab']['gitlab_rails']['backup_encryption_key'] = nil
default['gitlab']['gitlab_rails']['backup_storage_class'] = nil

# Path to the GitLab Shell installation
# defaults to /opt/gitlab/embedded/service/gitlab-shell/. The install-dir path is set at build time
default['gitlab']['gitlab_rails']['gitlab_shell_path'] = "#{node['package']['install-dir']}/embedded/service/gitlab-shell/"
# Path to the git hooks used by GitLab Shell
# defaults to /opt/gitlab/embedded/service/gitlab-shell/hooks/. The install-dir path is set at build time
default['gitlab']['gitlab_rails']['gitlab_shell_hooks_path'] = "#{node['package']['install-dir']}/embedded/service/gitlab-shell/hooks/"
default['gitlab']['gitlab_rails']['gitlab_shell_upload_pack'] = nil
default['gitlab']['gitlab_rails']['gitlab_shell_receive_pack'] = nil
default['gitlab']['gitlab_rails']['gitlab_shell_ssh_port'] = nil
default['gitlab']['gitlab_rails']['gitlab_shell_git_timeout'] = 10800
# Path to the Git Executable
# defaults to /opt/gitlab/embedded/bin/git. The install-dir path is set at build time
default['gitlab']['gitlab_rails']['git_bin_path'] = "#{node['package']['install-dir']}/embedded/bin/git"
default['gitlab']['gitlab_rails']['extra_google_analytics_id'] = nil
default['gitlab']['gitlab_rails']['extra_google_tag_manager_id'] = nil
default['gitlab']['gitlab_rails']['extra_one_trust_id'] = nil
default['gitlab']['gitlab_rails']['extra_google_tag_manager_nonce_id'] = nil
default['gitlab']['gitlab_rails']['extra_bizible'] = false
default['gitlab']['gitlab_rails']['extra_matomo_url'] = nil
default['gitlab']['gitlab_rails']['extra_matomo_site_id'] = nil
default['gitlab']['gitlab_rails']['extra_matomo_disable_cookies'] = nil
default['gitlab']['gitlab_rails']['extra_maximum_text_highlight_size_kilobytes'] = nil
default['gitlab']['gitlab_rails']['rack_attack_git_basic_auth'] = nil

default['gitlab']['gitlab_rails']['db_adapter'] = "postgresql"
default['gitlab']['gitlab_rails']['db_encoding'] = "unicode"
default['gitlab']['gitlab_rails']['db_collation'] = nil
default['gitlab']['gitlab_rails']['db_database'] = "gitlabhq_production"
default['gitlab']['gitlab_rails']['db_username'] = "gitlab"
default['gitlab']['gitlab_rails']['db_password'] = nil
default['gitlab']['gitlab_rails']['db_load_balancing'] = { 'hosts' => [] }
# Path to postgresql socket directory
default['gitlab']['gitlab_rails']['db_host'] = nil
default['gitlab']['gitlab_rails']['db_port'] = 5432
default['gitlab']['gitlab_rails']['db_socket'] = nil
default['gitlab']['gitlab_rails']['db_sslmode'] = nil
default['gitlab']['gitlab_rails']['db_sslcompression'] = 0
default['gitlab']['gitlab_rails']['db_sslrootcert'] = nil
default['gitlab']['gitlab_rails']['db_sslcert'] = nil
default['gitlab']['gitlab_rails']['db_sslkey'] = nil
default['gitlab']['gitlab_rails']['db_sslca'] = nil
default['gitlab']['gitlab_rails']['db_prepared_statements'] = false
default['gitlab']['gitlab_rails']['db_database_tasks'] = true
default['gitlab']['gitlab_rails']['db_statements_limit'] = 1000
default['gitlab']['gitlab_rails']['db_statement_timeout'] = nil
default['gitlab']['gitlab_rails']['db_connect_timeout'] = nil
default['gitlab']['gitlab_rails']['db_keepalives'] = nil
default['gitlab']['gitlab_rails']['db_keepalives_idle'] = nil
default['gitlab']['gitlab_rails']['db_keepalives_interval'] = nil
default['gitlab']['gitlab_rails']['db_keepalives_count'] = nil
default['gitlab']['gitlab_rails']['db_tcp_user_timeout'] = nil
default['gitlab']['gitlab_rails']['db_application_name'] = nil

default['gitlab']['gitlab_rails']['databases'] = {}

# Automatic Database Reindexing
# See https://docs.gitlab.com/omnibus/settings/database.html#automatic-database-reindexing
default['gitlab']['gitlab_rails']['database_reindexing']['enable'] = false
default['gitlab']['gitlab_rails']['database_reindexing']['hour'] = '*'
default['gitlab']['gitlab_rails']['database_reindexing']['minute'] = 0
default['gitlab']['gitlab_rails']['database_reindexing']['month'] = '*'
default['gitlab']['gitlab_rails']['database_reindexing']['day_of_month'] = '*'
default['gitlab']['gitlab_rails']['database_reindexing']['day_of_week'] = '0,6'

default['gitlab']['gitlab_rails']['redis_host'] = "127.0.0.1"
default['gitlab']['gitlab_rails']['redis_port'] = nil
default['gitlab']['gitlab_rails']['redis_ssl'] = false
default['gitlab']['gitlab_rails']['redis_password'] = nil
default['gitlab']['gitlab_rails']['redis_socket'] = "/var/opt/gitlab/redis/redis.socket"
default['gitlab']['gitlab_rails']['redis_enable_client'] = true
default['gitlab']['gitlab_rails']['redis_sentinels'] = []
default['gitlab']['gitlab_rails']['redis_cache_instance'] = nil
default['gitlab']['gitlab_rails']['redis_cache_sentinels'] = []
default['gitlab']['gitlab_rails']['redis_cache_username'] = nil
default['gitlab']['gitlab_rails']['redis_cache_password'] = nil
default['gitlab']['gitlab_rails']['redis_cache_cluster_nodes'] = []
default['gitlab']['gitlab_rails']['redis_queues_instance'] = nil
default['gitlab']['gitlab_rails']['redis_queues_username'] = nil
default['gitlab']['gitlab_rails']['redis_queues_password'] = nil
default['gitlab']['gitlab_rails']['redis_queues_sentinels'] = []
default['gitlab']['gitlab_rails']['redis_queues_cluster_nodes'] = []
default['gitlab']['gitlab_rails']['redis_shared_state_instance'] = nil
default['gitlab']['gitlab_rails']['redis_shared_state_sentinels'] = []
default['gitlab']['gitlab_rails']['redis_shared_state_username'] = nil
default['gitlab']['gitlab_rails']['redis_shared_state_password'] = nil
default['gitlab']['gitlab_rails']['redis_shared_state_cluster_nodes'] = []
default['gitlab']['gitlab_rails']['redis_trace_chunks_instance'] = nil
default['gitlab']['gitlab_rails']['redis_trace_chunks_sentinels'] = []
default['gitlab']['gitlab_rails']['redis_trace_chunks_username'] = nil
default['gitlab']['gitlab_rails']['redis_trace_chunks_password'] = nil
default['gitlab']['gitlab_rails']['redis_trace_chunks_cluster_nodes'] = []
default['gitlab']['gitlab_rails']['redis_actioncable_instance'] = nil
default['gitlab']['gitlab_rails']['redis_actioncable_sentinels'] = []
default['gitlab']['gitlab_rails']['redis_actioncable_username'] = nil
default['gitlab']['gitlab_rails']['redis_actioncable_password'] = nil
default['gitlab']['gitlab_rails']['redis_actioncable_cluster_nodes'] = []
default['gitlab']['gitlab_rails']['redis_rate_limiting_instance'] = nil
default['gitlab']['gitlab_rails']['redis_rate_limiting_sentinels'] = []
default['gitlab']['gitlab_rails']['redis_rate_limiting_username'] = nil
default['gitlab']['gitlab_rails']['redis_rate_limiting_password'] = nil
default['gitlab']['gitlab_rails']['redis_rate_limiting_cluster_nodes'] = []
default['gitlab']['gitlab_rails']['redis_sessions_instance'] = nil
default['gitlab']['gitlab_rails']['redis_sessions_sentinels'] = []
default['gitlab']['gitlab_rails']['redis_sessions_username'] = nil
default['gitlab']['gitlab_rails']['redis_sessions_password'] = nil
default['gitlab']['gitlab_rails']['redis_sessions_cluster_nodes'] = []
default['gitlab']['gitlab_rails']['redis_repository_cache_instance'] = nil
default['gitlab']['gitlab_rails']['redis_repository_cache_sentinels'] = []
default['gitlab']['gitlab_rails']['redis_repository_cache_username'] = nil
default['gitlab']['gitlab_rails']['redis_repository_cache_password'] = nil
default['gitlab']['gitlab_rails']['redis_repository_cache_cluster_nodes'] = []
default['gitlab']['gitlab_rails']['redis_cluster_rate_limiting_instance'] = nil
default['gitlab']['gitlab_rails']['redis_cluster_rate_limiting_sentinels'] = []
default['gitlab']['gitlab_rails']['redis_cluster_rate_limiting_username'] = nil
default['gitlab']['gitlab_rails']['redis_cluster_rate_limiting_password'] = nil
default['gitlab']['gitlab_rails']['redis_cluster_rate_limiting_cluster_nodes'] = []

default['gitlab']['gitlab_rails']['redis_yml_override'] = nil

default['gitlab']['gitlab_rails']['smtp_enable'] = false
default['gitlab']['gitlab_rails']['smtp_address'] = nil
default['gitlab']['gitlab_rails']['smtp_port'] = nil
default['gitlab']['gitlab_rails']['smtp_user_name'] = nil
default['gitlab']['gitlab_rails']['smtp_password'] = nil
default['gitlab']['gitlab_rails']['smtp_domain'] = nil
default['gitlab']['gitlab_rails']['smtp_authentication'] = nil
default['gitlab']['gitlab_rails']['smtp_enable_starttls_auto'] = nil
default['gitlab']['gitlab_rails']['smtp_tls'] = nil
default['gitlab']['gitlab_rails']['smtp_openssl_verify_mode'] = nil
default['gitlab']['gitlab_rails']['smtp_ca_path'] = nil
default['gitlab']['gitlab_rails']['smtp_pool'] = false
# Path to the public Certificate Authority file
# defaults to /opt/gitlab/embedded/ssl/certs/cacert.pem. The install-dir path is set at build time
default['gitlab']['gitlab_rails']['smtp_ca_file'] = "#{node['package']['install-dir']}/embedded/ssl/certs/cacert.pem"

# Path to directory that contains (ca) certificates that should also be trusted (e.g. on
# outgoing Webhooks connections). For these certificates symlinks will be created in
# /opt/gitlab/embedded/ssl/certs/.
default['gitlab']['gitlab_rails']['trusted_certs_dir'] = "/etc/gitlab/trusted-certs"

default['gitlab']['gitlab_rails']['webhook_timeout'] = nil

default['gitlab']['gitlab_rails']['graphql_timeout'] = nil

default['gitlab']['gitlab_rails']['initial_root_password'] = nil
default['gitlab']['gitlab_rails']['initial_license_file'] = nil
default['gitlab']['gitlab_rails']['initial_shared_runners_registration_token'] = nil
default['gitlab']['gitlab_rails']['display_initial_root_password'] = false
default['gitlab']['gitlab_rails']['store_initial_root_password'] = false
default['gitlab']['gitlab_rails']['trusted_proxies'] = []
default['gitlab']['gitlab_rails']['content_security_policy'] = nil
default['gitlab']['gitlab_rails']['allowed_hosts'] = []

# List of ips and subnets that are allowed to access Gitlab monitoring endpoints
default['gitlab']['gitlab_rails']['monitoring_whitelist'] = ['127.0.0.0/8', '::1/128']
default['gitlab']['gitlab_rails']['shutdown_blackout_seconds'] = 10
# Default dependent services to restart in the event that files-of-interest change
default['gitlab']['gitlab_rails']['dependent_services'] = %w{puma}

###
# Unleash
###
default['gitlab']['gitlab_rails']['feature_flags_unleash_enabled'] = false
default['gitlab']['gitlab_rails']['feature_flags_unleash_url'] = nil
default['gitlab']['gitlab_rails']['feature_flags_unleash_app_name'] = nil
default['gitlab']['gitlab_rails']['feature_flags_unleash_instance_id'] = nil

###
# Prometheus
###
default['gitlab']['gitlab_rails']['prometheus_address'] = nil

###
# GitLab KAS
###
default['gitlab']['gitlab_rails']['gitlab_kas_enabled'] = nil
default['gitlab']['gitlab_rails']['gitlab_kas_external_url'] = nil
default['gitlab']['gitlab_rails']['gitlab_kas_internal_url'] = nil
default['gitlab']['gitlab_rails']['gitlab_kas_external_k8s_proxy_url'] = nil

####
# Puma
####
default['gitlab']['puma']['enable'] = false
default['gitlab']['puma']['ha'] = false
default['gitlab']['puma']['log_directory'] = "/var/log/gitlab/puma"
default['gitlab']['puma']['listen'] = nil
default['gitlab']['puma']['port'] = 8080
default['gitlab']['puma']['socket'] = '/var/opt/gitlab/gitlab-rails/sockets/gitlab.socket'
default['gitlab']['puma']['ssl_listen'] = nil
default['gitlab']['puma']['ssl_port'] = nil
default['gitlab']['puma']['ssl_certificate'] = nil
default['gitlab']['puma']['ssl_certificate_key'] = nil
default['gitlab']['puma']['ssl_client_certificate'] = nil
default['gitlab']['puma']['ssl_cipher_filter'] = nil
default['gitlab']['puma']['ssl_verify_mode'] = 'none'
default['gitlab']['puma']['prometheus_scrape_scheme'] = 'http'
default['gitlab']['puma']['prometheus_scrape_tls_server_name'] = nil
default['gitlab']['puma']['prometheus_scrape_tls_skip_verification'] = false

default['gitlab']['puma']['somaxconn'] = 1024
# Path to the puma server Process ID file
# defaults to /opt/gitlab/var/puma/puma.pid. The install-dir path is set at build time
default['gitlab']['puma']['pidfile'] = "#{node['package']['install-dir']}/var/puma/puma.pid"
default['gitlab']['puma']['state_path'] = "#{node['package']['install-dir']}/var/puma/puma.state"
default['gitlab']['puma']['worker_timeout'] = 60
default['gitlab']['puma']['per_worker_max_memory_mb'] = nil
default['gitlab']['puma']['worker_processes'] = nil
default['gitlab']['puma']['min_threads'] = 4
default['gitlab']['puma']['max_threads'] = 4
default['gitlab']['puma']['exporter_enabled'] = false
default['gitlab']['puma']['exporter_address'] = "127.0.0.1"
default['gitlab']['puma']['exporter_port'] = 8083
default['gitlab']['puma']['exporter_tls_enabled'] = false
default['gitlab']['puma']['exporter_tls_cert_path'] = nil
default['gitlab']['puma']['exporter_tls_key_path'] = nil
default['gitlab']['puma']['consul_service_name'] = 'rails'
default['gitlab']['puma']['consul_service_meta'] = nil

####
# ActionCable
####
default['gitlab']['actioncable']['worker_pool_size'] = 4

####
# Sidekiq
####
default['gitlab']['sidekiq']['enable'] = false
default['gitlab']['sidekiq']['ha'] = false
default['gitlab']['sidekiq']['log_directory'] = "/var/log/gitlab/sidekiq"
default['gitlab']['sidekiq']['log_format'] = "json"
default['gitlab']['sidekiq']['shutdown_timeout'] = 25
default['gitlab']['sidekiq']['concurrency'] = 25
default['gitlab']['sidekiq']['routing_rules'] = []

# Sidekiq metrics server defaults
default['gitlab']['sidekiq']['metrics_enabled'] = true
default['gitlab']['sidekiq']['exporter_log_enabled'] = false
default['gitlab']['sidekiq']['exporter_tls_enabled'] = false
default['gitlab']['sidekiq']['exporter_tls_cert_path'] = nil
default['gitlab']['sidekiq']['exporter_tls_key_path'] = nil
default['gitlab']['sidekiq']['listen_address'] = "127.0.0.1"
default['gitlab']['sidekiq']['listen_port'] = 8082

# Sidekiq health-check server defaults
default['gitlab']['sidekiq']['health_checks_enabled'] = true
default['gitlab']['sidekiq']['health_checks_listen_address'] = "127.0.0.1"
default['gitlab']['sidekiq']['health_checks_listen_port'] = 8092

# Cluster specific settings
default['gitlab']['sidekiq']['queue_selector'] = false
default['gitlab']['sidekiq']['interval'] = nil
default['gitlab']['sidekiq']['max_concurrency'] = 20
default['gitlab']['sidekiq']['min_concurrency'] = nil
default['gitlab']['sidekiq']['negate'] = false
default['gitlab']['sidekiq']['queue_groups'] = ['*']
default['gitlab']['sidekiq']['consul_service_name'] = 'sidekiq'
default['gitlab']['sidekiq']['consul_service_meta'] = nil

###
# gitlab-shell
###
default['gitlab']['gitlab_shell']['dir'] = "/var/opt/gitlab/gitlab-shell"
default['gitlab']['gitlab_shell']['log_directory'] = "/var/log/gitlab/gitlab-shell"
default['gitlab']['gitlab_shell']['log_level'] = nil
default['gitlab']['gitlab_shell']['log_format'] = "json"
default['gitlab']['gitlab_shell']['audit_usernames'] = nil
default['gitlab']['gitlab_shell']['http_settings'] = nil
default['gitlab']['gitlab_shell']['auth_file'] = nil
default['gitlab']['gitlab_shell']['git_trace_log_file'] = nil
default['gitlab']['gitlab_shell']['migration'] = { enabled: true, features: [] }
default['gitlab']['gitlab_shell']['ssl_cert_dir'] = "#{node['package']['install-dir']}/embedded/ssl/certs/"
# DEPRECATED! Not used by gitlab-shell
default['gitlab']['gitlab_shell']['git_data_directories'] = {
  "default" => { "path" => "/var/opt/gitlab/git-data" }
}

###
# gitlab-sshd
###
default['gitlab']['gitlab_sshd']['enable'] = false
default['gitlab']['gitlab_sshd']['generate_host_keys'] = true
default['gitlab']['gitlab_sshd']['dir'] = "/var/opt/gitlab/gitlab-sshd"
# gitlab-sshd outputs most logs to /var/log/gitlab/gitlab-shell/gitlab-shell.log.
# This directory only stores any stdout/stderr output from the daemon.
default['gitlab']['gitlab_sshd']['log_directory'] = "/var/log/gitlab/gitlab-sshd"
default['gitlab']['gitlab_sshd']['env_directory'] = '/opt/gitlab/etc/gitlab-sshd/env'
default['gitlab']['gitlab_sshd']['listen_address'] = 'localhost:2222'
default['gitlab']['gitlab_sshd']['metrics_address'] = 'localhost:9122'
default['gitlab']['gitlab_sshd']['concurrent_sessions_limit'] = 100
default['gitlab']['gitlab_sshd']['proxy_protocol'] = false
default['gitlab']['gitlab_sshd']['proxy_policy'] = 'use'
default['gitlab']['gitlab_sshd']['proxy_header_timeout'] = '500ms'
default['gitlab']['gitlab_sshd']['grace_period'] = 55
default['gitlab']['gitlab_sshd']['client_alive_interval'] = nil
default['gitlab']['gitlab_sshd']['ciphers'] = nil
default['gitlab']['gitlab_sshd']['kex_algorithms'] = nil
default['gitlab']['gitlab_sshd']['macs'] = nil
default['gitlab']['gitlab_sshd']['login_grace_time'] = 60
default['gitlab']['gitlab_sshd']['host_keys_dir'] = '/var/opt/gitlab/gitlab-sshd'
default['gitlab']['gitlab_sshd']['host_keys_glob'] = 'ssh_host_*_key'
default['gitlab']['gitlab_sshd']['host_certs_dir'] = '/var/opt/gitlab/gitlab-sshd'
default['gitlab']['gitlab_sshd']['host_certs_glob'] = 'ssh_host_*-cert.pub'

####
# Web server
####
# Username for the webserver user
default['gitlab']['web_server']['username'] = 'gitlab-www'
default['gitlab']['web_server']['group'] = 'gitlab-www'
default['gitlab']['web_server']['uid'] = nil
default['gitlab']['web_server']['gid'] = nil
default['gitlab']['web_server']['shell'] = '/bin/false'
default['gitlab']['web_server']['home'] = '/var/opt/gitlab/nginx'
# When bundled nginx is disabled we need to add the external webserver user to the GitLab webserver group
default['gitlab']['web_server']['external_users'] = []

####
# gitlab-workhorse
####

default['gitlab']['gitlab_workhorse']['enable'] = false
default['gitlab']['gitlab_workhorse']['ha'] = false
default['gitlab']['gitlab_workhorse']['alt_document_root'] = nil
default['gitlab']['gitlab_workhorse']['shutdown_timeout'] = nil
default['gitlab']['gitlab_workhorse']['workhorse_keywatcher'] = true
default['gitlab']['gitlab_workhorse']['listen_network'] = "unix"
default['gitlab']['gitlab_workhorse']['listen_umask'] = 000
default['gitlab']['gitlab_workhorse']['sockets_directory'] = nil
default['gitlab']['gitlab_workhorse']['listen_addr'] = nil
default['gitlab']['gitlab_workhorse']['auth_backend'] = "http://localhost:8080"
default['gitlab']['gitlab_workhorse']['auth_socket'] = nil
default['gitlab']['gitlab_workhorse']['pprof_listen_addr'] = "''" # put an empty string on the command line
default['gitlab']['gitlab_workhorse']['prometheus_listen_addr'] = "localhost:9229"
default['gitlab']['gitlab_workhorse']['dir'] = "/var/opt/gitlab/gitlab-workhorse"
default['gitlab']['gitlab_workhorse']['log_directory'] = "/var/log/gitlab/gitlab-workhorse"
default['gitlab']['gitlab_workhorse']['proxy_headers_timeout'] = nil
default['gitlab']['gitlab_workhorse']['api_limit'] = nil
default['gitlab']['gitlab_workhorse']['api_queue_duration'] = nil
default['gitlab']['gitlab_workhorse']['api_queue_limit'] = nil
default['gitlab']['gitlab_workhorse']['api_ci_long_polling_duration'] = nil
default['gitlab']['gitlab_workhorse']['propagate_correlation_id'] = false
default['gitlab']['gitlab_workhorse']['trusted_cidrs_for_x_forwarded_for'] = nil
default['gitlab']['gitlab_workhorse']['trusted_cidrs_for_propagation'] = nil
default['gitlab']['gitlab_workhorse']['log_format'] = "json"
default['gitlab']['gitlab_workhorse']['env_directory'] = '/opt/gitlab/etc/gitlab-workhorse/env'
default['gitlab']['gitlab_workhorse']['env'] = {
  'PATH' => "#{node['package']['install-dir']}/bin:#{node['package']['install-dir']}/embedded/bin:/bin:/usr/bin",
  'HOME' => node['gitlab']['user']['home'],
  'SSL_CERT_DIR' => "#{node['package']['install-dir']}/embedded/ssl/certs/"
}
default['gitlab']['gitlab_workhorse']['image_scaler_max_procs'] = [2, node.dig('cpu', 'total').to_i / 2, node.dig('cpu', 'real').to_i / 2].max
default['gitlab']['gitlab_workhorse']['image_scaler_max_filesize'] = 250_000
default['gitlab']['gitlab_workhorse']['consul_service_name'] = 'workhorse'
default['gitlab']['gitlab_workhorse']['consul_service_meta'] = nil

####
# mailroom
####
default['gitlab']['mailroom']['enable'] = false
default['gitlab']['mailroom']['ha'] = false
default['gitlab']['mailroom']['log_directory'] = "/var/log/gitlab/mailroom"
default['gitlab']['mailroom']['exit_log_format'] = "plain" # If mail_room crashes, the structure of the final exception message
default['gitlab']['mailroom']['incoming_email_auth_token'] = nil
default['gitlab']['mailroom']['service_desk_email_auth_token'] = nil

####
# Nginx
####
default['gitlab']['nginx']['enable'] = false
default['gitlab']['nginx']['ha'] = false
default['gitlab']['nginx']['dir'] = "/var/opt/gitlab/nginx"
default['gitlab']['nginx']['log_directory'] = "/var/log/gitlab/nginx"
default['gitlab']['nginx']['error_log_level'] = "error"
default['gitlab']['nginx']['worker_processes'] = [1, node.dig('cpu', 'total').to_i, node.dig('cpu', 'real').to_i].max
default['gitlab']['nginx']['worker_connections'] = 10240
default['gitlab']['nginx']['log_format'] = '$remote_addr - $remote_user [$time_local] "$request_method $filtered_request_uri $server_protocol" $status $body_bytes_sent "$filtered_http_referer" "$http_user_agent" $gzip_ratio' #  NGINX 'combined' format without query strings
default['gitlab']['nginx']['sendfile'] = 'on'
default['gitlab']['nginx']['tcp_nopush'] = 'on'
default['gitlab']['nginx']['tcp_nodelay'] = 'on'
default['gitlab']['nginx']['hide_server_tokens'] = 'off'
default['gitlab']['nginx']['gzip_http_version'] = "1.1"
default['gitlab']['nginx']['gzip_comp_level'] = "2"
default['gitlab']['nginx']['gzip_proxied'] = "no-cache no-store private expired auth"
default['gitlab']['nginx']['gzip_types'] = ["text/plain", "text/css", "application/x-javascript", "text/xml", "application/xml", "application/xml+rss", "text/javascript", "application/json"]
default['gitlab']['nginx']['keepalive_timeout'] = 65
default['gitlab']['nginx']['keepalive_time'] = '1h'
default['gitlab']['nginx']['client_max_body_size'] = 0
default['gitlab']['nginx']['cache_max_size'] = '5000m'
default['gitlab']['nginx']['redirect_http_to_https'] = false
default['gitlab']['nginx']['redirect_http_to_https_port'] = 80
# The following matched paths will set proxy_request_buffering to off
default['gitlab']['nginx']['request_buffering_off_path_regex'] = "/api/v\\d/jobs/\\d+/artifacts$|/import/gitlab_project$|\\.git/git-receive-pack$|\\.git/gitlab-lfs/objects|\\.git/info/lfs/objects/batch$"
default['gitlab']['nginx']['ssl_client_certificate'] = nil # Most root CA's will be included by default
default['gitlab']['nginx']['ssl_verify_client'] = nil # do not enable 2-way SSL client authentication
default['gitlab']['nginx']['ssl_verify_depth'] = "1" # n/a if ssl_verify_client off
default['gitlab']['nginx']['ssl_certificate'] = "/etc/gitlab/ssl/#{node['fqdn']}.crt"
default['gitlab']['nginx']['ssl_certificate_key'] = "/etc/gitlab/ssl/#{node['fqdn']}.key"
default['gitlab']['nginx']['ssl_ciphers'] = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384" # settings from by https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1d&ocsp=false&guideline=5.6
default['gitlab']['nginx']['ssl_prefer_server_ciphers'] = "off" # settings from by https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1d&ocsp=false&guideline=5.6
default['gitlab']['nginx']['ssl_protocols'] = "TLSv1.2 TLSv1.3" # recommended by https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html & https://cipherli.st/
default['gitlab']['nginx']['ssl_session_cache'] = "shared:SSL:10m"
default['gitlab']['nginx']['ssl_session_tickets'] = "off"
default['gitlab']['nginx']['ssl_session_timeout'] = "1d" # settings from by https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1d&ocsp=false&guideline=5.6
default['gitlab']['nginx']['ssl_dhparam'] = nil # Path to dhparam.pem
default['gitlab']['nginx']['ssl_password_file'] = nil
default['gitlab']['nginx']['listen_addresses'] = ['*']
default['gitlab']['nginx']['listen_port'] = nil # override only if you have a reverse proxy
default['gitlab']['nginx']['listen_https'] = nil # override only if your reverse proxy internally communicates over HTTP
default['gitlab']['nginx']['custom_gitlab_server_config'] = nil
default['gitlab']['nginx']['custom_nginx_config'] = nil
default['gitlab']['nginx']['proxy_read_timeout'] = 3600
default['gitlab']['nginx']['proxy_connect_timeout'] = 300
default['gitlab']['nginx']['proxy_set_headers'] = {
  "Host" => "$http_host_with_default",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$proxy_add_x_forwarded_for",
  "Upgrade" => "$http_upgrade",
  "Connection" => "$connection_upgrade"
}
default['gitlab']['nginx']['proxy_protocol'] = false
default['gitlab']['nginx']['proxy_custom_buffer_size'] = nil
default['gitlab']['nginx']['referrer_policy'] = 'strict-origin-when-cross-origin'
default['gitlab']['nginx']['http2_enabled'] = true
# Cache up to 1GB of HTTP responses from GitLab on disk
default['gitlab']['nginx']['proxy_cache_path'] = 'proxy_cache keys_zone=gitlab:10m max_size=1g levels=1:2'
# Set to 'off' to disable proxy caching.
default['gitlab']['nginx']['proxy_cache'] = 'gitlab'
# Config for the http_realip_module http://nginx.org/en/docs/http/ngx_http_realip_module.html
default['gitlab']['nginx']['real_ip_trusted_addresses'] = [] # Each entry creates a set_real_ip_from directive
default['gitlab']['nginx']['real_ip_header'] = nil
default['gitlab']['nginx']['real_ip_recursive'] = nil
default['gitlab']['nginx']['server_names_hash_bucket_size'] = 64
# HSTS
default['gitlab']['nginx']['hsts_max_age'] = 63072000 # settings from by https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1d&ocsp=false&guideline=5.6
default['gitlab']['nginx']['hsts_include_subdomains'] = false
# Compression
default['gitlab']['nginx']['gzip_enabled'] = true

# Consul
default['gitlab']['nginx']['consul_service_name'] = 'nginx'
default['gitlab']['nginx']['consul_service_meta'] = nil

###
# Nginx status
###
default['gitlab']['nginx']['status']['enable'] = true
default['gitlab']['nginx']['status']['listen_addresses'] = ['*']
default['gitlab']['nginx']['status']['fqdn'] = "localhost"
default['gitlab']['nginx']['status']['port'] = 8060
default['gitlab']['nginx']['status']['vts_enable'] = true
default['gitlab']['nginx']['status']['options'] = {
  "server_tokens" => "off",
  "access_log" => "off",
  "allow" => "127.0.0.1",
  "deny" => "all",
}

###
# Logging
###
default['gitlab']['logging']['svlogd_size'] = 200 * 1024 * 1024 # rotate after 200 MB of log data
default['gitlab']['logging']['svlogd_num'] = 30 # keep 30 rotated log files
default['gitlab']['logging']['svlogd_timeout'] = 24 * 60 * 60 # rotate after 24 hours
default['gitlab']['logging']['svlogd_filter'] = "gzip" # compress logs with gzip
default['gitlab']['logging']['svlogd_udp'] = nil # transmit log messages via UDP
default['gitlab']['logging']['svlogd_prefix'] = nil # custom prefix for log messages
default['gitlab']['logging']['udp_log_shipping_host'] = nil # remote host to ship log messages to via UDP
default['gitlab']['logging']['udp_log_shipping_hostname'] = nil # set the hostname for log messages shipped via UDP
default['gitlab']['logging']['udp_log_shipping_port'] = 514 # remote port to ship log messages to via UDP
default['gitlab']['logging']['logrotate_frequency'] = "daily" # rotate logs daily
default['gitlab']['logging']['logrotate_maxsize'] = nil # rotate logs when they grow bigger than size bytes even before the specified time interval (daily, weekly, monthly, or yearly)
default['gitlab']['logging']['logrotate_size'] = nil # do not rotate by size by default
default['gitlab']['logging']['logrotate_rotate'] = 30 # keep 30 rotated logs
default['gitlab']['logging']['logrotate_compress'] = "compress" # see 'man logrotate'
default['gitlab']['logging']['logrotate_method'] = "copytruncate" # see 'man logrotate'
default['gitlab']['logging']['logrotate_postrotate'] = nil # no postrotate command by default
default['gitlab']['logging']['logrotate_dateformat'] = nil # use date extensions for rotated files rather than numbers e.g. a value of "-%Y-%m-%d" would give rotated files like production.log-2016-03-09.gz
default['gitlab']['logging']['log_group'] = nil # log group for logs (svlogd only at this time)

###
# Remote syslog
###
default['gitlab']['remote_syslog']['enable'] = false
default['gitlab']['remote_syslog']['ha'] = false
default['gitlab']['remote_syslog']['dir'] = "/var/opt/gitlab/remote-syslog"
default['gitlab']['remote_syslog']['log_directory'] = "/var/log/gitlab/remote-syslog"
default['gitlab']['remote_syslog']['destination_host'] = "localhost"
default['gitlab']['remote_syslog']['destination_port'] = 514
default['gitlab']['remote_syslog']['services'] = %w(redis nginx puma gitlab-rails gitlab-shell postgresql sidekiq gitlab-workhorse gitlab-pages praefect gitlab-kas)

###
# High Availability
###
default['gitlab']['high_availability']['mountpoint'] = nil

####
# GitLab CI Rails app
####
default['gitlab']['gitlab_ci']['dir'] = "/var/opt/gitlab/gitlab-ci"
default['gitlab']['gitlab_ci']['builds_directory'] = "/var/opt/gitlab/gitlab-ci/builds"

default['gitlab']['gitlab_ci']['schedule_builds_minute'] = "0"

default['gitlab']['gitlab_ci']['gitlab_ci_all_broken_builds'] = nil
default['gitlab']['gitlab_ci']['gitlab_ci_add_pusher'] = nil

####
# Mattermost NGINX
####
default['gitlab']['mattermost_nginx'] = default['gitlab']['nginx'].dup
default['gitlab']['mattermost_nginx']['enable'] = false
default['gitlab']['mattermost_nginx']['proxy_set_headers'] = {
  "Host" => "$http_host",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$proxy_add_x_forwarded_for",
  "X-Forwarded-Proto" => "$scheme",
  "X-Frame-Options" => "SAMEORIGIN",
  "Upgrade" => "$http_upgrade",
  "Connection" => "$connection_upgrade"
}
default['gitlab']['mattermost_nginx']['referrer_policy'] = 'strict-origin-when-cross-origin'

####
# GitLab Pages NGINX
####
default['gitlab']['pages_nginx'] = default['gitlab']['nginx'].dup
default['gitlab']['pages_nginx']['enable'] = true
default['gitlab']['pages_nginx']['proxy_set_headers'] = {
  "Host" => "$http_host",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$proxy_add_x_forwarded_for",
  "X-Forwarded-Proto" => "$scheme"
}

####
# GitLab Registry NGINX
####
default['gitlab']['registry_nginx'] = default['gitlab']['nginx'].dup
default['gitlab']['registry_nginx']['enable'] = true
default['gitlab']['registry_nginx']['https'] = false
default['gitlab']['registry_nginx']['http2_enabled'] = false
default['gitlab']['registry_nginx']['proxy_set_headers'] = {
  "Host" => "$http_host",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$proxy_add_x_forwarded_for",
  "X-Forwarded-Proto" => "$scheme"
}

####
# GitLab KAS NGINX
####
default['gitlab']['gitlab_kas_nginx'] = default['gitlab']['nginx'].dup
default['gitlab']['gitlab_kas_nginx']['enable'] = false
default['gitlab']['gitlab_kas_nginx']['https'] = false
default['gitlab']['gitlab_kas_nginx']['port'] = 80
default['gitlab']['gitlab_kas_nginx']['host'] = "kas.gitlab.example.com"
default['gitlab']['gitlab_kas_nginx']['proxy_set_headers'] = {
  "Host" => "$http_host",
  "Upgrade" => "$http_upgrade",
  "Connection" => "$connection_upgrade",
  "X-Real-IP" => "$remote_addr",
  "X-Forwarded-For" => "$remote_addr",
  "X-Forwarded-Proto" => "$scheme",
  "X-Forwarded-Scheme" => "$scheme",
  "X-Scheme" => "$scheme",
  "X-Original-Forwarded-For" => "$http_x_forwarded_for"
}

####
# Storage check
####
default['gitlab']['storage_check']['enable'] = false
default['gitlab']['storage_check']['target'] = nil
default['gitlab']['storage_check']['log_directory'] = '/var/log/gitlab/storage-check'

default['gitlab']['gitlab-shell'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['gitlab_shell'].to_h }, "node['gitlab']['gitlab-shell']", "node['gitlab']['gitlab_shell']")
default['gitlab']['remote-syslog'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['remote_syslog'].to_h }, "node['gitlab']['remote-syslog']", "node['gitlab']['remote_syslog']")
default['gitlab']['gitlab-workhorse'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['gitlab_workhorse'].to_h }, "node['gitlab']['gitlab-workhorse']", "node['gitlab']['gitlab_workhorse']")
default['gitlab']['mattermost-nginx'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['mattermost_nginx'].to_h }, "node['gitlab']['mattermost-nginx']", "node['gitlab']['mattermost_nginx']")
default['gitlab']['pages-nginx'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['pages_nginx'].to_h }, "node['gitlab']['pages-nginx']", "node['gitlab']['pages_nginx']")
default['gitlab']['registry-nginx'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['registry_nginx'].to_h }, "node['gitlab']['registry-nginx']", "node['gitlab']['registry_nginx']")
default['gitlab']['gitlab-kas-nginx'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['gitlab_kas_nginx'].to_h }, "node['gitlab']['gitlab-kas-nginx']", "node['gitlab']['gitlab_kas_nginx']")
default['gitlab']['gitlab-rails'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['gitlab_rails'].to_h }, "node['gitlab']['gitlab-rails']", "node['gitlab']['gitlab_rails']")
default['gitlab']['external-url'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['external_url'] }, "node['gitlab']['external-url']", "node['gitlab']['external_url']")
default['gitlab']['gitlab-kas-external-url'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['gitlab_kas_external_url'] }, "node['gitlab']['gitlab-kas-external-url']", "node['gitlab']['gitlab_kas_external_url']")
default['gitlab']['mattermost-external-url'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['mattermost_external_url'] }, "node['gitlab']['mattermost-external-url']", "node['gitlab']['mattermost_external_url']")
default['gitlab']['pages-external-url'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['pages_external_url'] }, "node['gitlab']['pages-external-url']", "node['gitlab']['pages_external_url']")
default['gitlab']['registry-external-url'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['registry_external_url'] }, "node['gitlab']['registry-external-url']", "node['gitlab']['registry_external_url']")
default['gitlab']['gitlab-ci'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['gitlab_ci'].to_h }, "node['gitlab']['gitlab-ci']", "node['gitlab']['gitlab_ci']")
default['gitlab']['high-availability'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['high_availability'].to_h }, "node['gitlab']['high-availability']", "node['gitlab']['high_availability']")
default['gitlab']['manage-accounts'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['manage_accounts'].to_h }, "node['gitlab']['manage-accounts']", "node['gitlab']['manage_accounts']")
default['gitlab']['manage-storage-directories'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['manage_storage_directories'].to_h }, "node['gitlab']['manage-storage-directories']", "node['gitlab']['manage_storage_directories']")
default['gitlab']['omnibus-gitconfig'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['omnibus_gitconfig'].to_h }, "node['gitlab']['omnibus-gitconfig']", "node['gitlab']['omnibus_gitconfig']")
default['gitlab']['runtime-dir'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['runtime_dir'] }, "node['gitlab']['runtime-dir']", "node['gitlab']['runtime_dir']")
default['gitlab']['storage-check'] = Gitlab::Deprecations::NodeAttribute.new(proc { node['gitlab']['storage_check'].to_h }, "node['gitlab']['storage-check']", "node['gitlab']['storage_check']")
