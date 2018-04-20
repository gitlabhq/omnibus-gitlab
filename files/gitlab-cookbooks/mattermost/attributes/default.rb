#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

default['mattermost']['enable'] = false
default['mattermost']['username'] = 'mattermost'
default['mattermost']['group'] = 'mattermost'
default['mattermost']['uid'] = nil
default['mattermost']['gid'] = nil
default['mattermost']['home'] = '/var/opt/gitlab/mattermost'
default['mattermost']['database_name'] = 'mattermost_production'
default['mattermost']['env'] = {}

default['mattermost']['log_file_directory'] = '/var/log/gitlab/mattermost/'
default['mattermost']['log_console_enable'] = true
default['mattermost']['log_enable_webhook_debugging'] = true
default['mattermost']['log_console_level'] = 'INFO'
default['mattermost']['log_enable_file'] = true
default['mattermost']['log_file_level'] = 'ERROR'
default['mattermost']['log_file_format'] = nil
default['mattermost']['log_enable_diagnostics'] = true

default['mattermost']['service_use_ssl'] = false
default['mattermost']['service_address'] = "127.0.0.1"
default['mattermost']['service_port'] = "8065"

default['mattermost']['service_site_url'] = nil
default['mattermost']['service_websocket_url'] = nil
default['mattermost']['service_maximum_login_attempts'] = 10
default['mattermost']['service_google_developer_key'] = nil
default['mattermost']['service_enable_incoming_webhooks'] = false
default['mattermost']['service_enable_post_username_override'] = true
default['mattermost']['service_enable_post_icon_override'] = true
default['mattermost']['service_enable_testing'] = false
default['mattermost']['service_enable_security_fix_alert'] = true
default['mattermost']['service_enable_insecure_outgoing_connections'] = false
default['mattermost']['service_allowed_untrusted_internal_connections'] = nil
default['mattermost']['service_allow_cors_from'] = nil
default['mattermost']['service_allow_cookies_from_subdomains'] = false
default['mattermost']['service_enable_outgoing_webhooks'] = false
default['mattermost']['service_enable_commands'] = true
default['mattermost']['service_enable_custom_emoji'] = false
default['mattermost']['service_enable_oauth_service_provider'] = false
default['mattermost']['service_enable_developer'] = false
default['mattermost']['service_session_length_web_in_days'] = 30
default['mattermost']['service_session_length_mobile_in_days'] = 30
default['mattermost']['service_session_length_sso_in_days'] = 30
default['mattermost']['service_session_cache_in_minutes'] = 10
default['mattermost']['service_connection_security'] = nil
default['mattermost']['service_tls_cert_file'] = nil
default['mattermost']['service_tls_key_file'] = nil
default['mattermost']['service_use_lets_encrypt'] = false
default['mattermost']['service_lets_encrypt_cert_cache_file'] = "./config/letsencrypt.cache"
default['mattermost']['service_forward_80_to_443'] = false
default['mattermost']['service_read_timeout'] = 300
default['mattermost']['service_write_timeout'] = 300
default['mattermost']['service_time_between_user_typing_updates_milliseconds'] = 5000
default['mattermost']['service_enable_link_previews'] = false
default['mattermost']['service_enable_user_typing_messages'] = true
default['mattermost']['service_enable_post_search'] = true
default['mattermost']['service_enable_user_statuses'] = true
default['mattermost']['service_enable_emoji_picker'] = true
default['mattermost']['service_enable_channel_viewed_messages'] = true
default['mattermost']['service_enable_apiv3'] = true
default['mattermost']['service_goroutine_health_threshold'] = -1
default['mattermost']['service_user_access_tokens'] = false
default['mattermost']['service_enable_preview_features'] = true
default['mattermost']['service_close_unused_direct_messages'] = false
default['mattermost']['service_image_proxy_type'] = ''
default['mattermost']['service_image_proxy_type'] = ''
default['mattermost']['service_image_proxy_url'] = ''

default['mattermost']['sql_driver_name'] = 'postgres'
default['mattermost']['sql_data_source'] = nil
default['mattermost']['sql_data_source_replicas'] = []
default['mattermost']['sql_max_idle_conns'] = 10
default['mattermost']['sql_max_open_conns'] = 10
default['mattermost']['sql_trace'] = false
default['mattermost']['sql_data_source_search_replicas'] = []
default['mattermost']['sql_query_timeout'] = 30

default['mattermost']['gitlab'] = {}

default['mattermost']['file_max_file_size'] = 52428800
default['mattermost']['file_driver_name'] = "local"
default['mattermost']['file_directory'] = "/var/opt/gitlab/mattermost/data"
default['mattermost']['file_enable_public_link'] = true
default['mattermost']['file_initial_font'] = 'luximbi.ttf'
default['mattermost']['file_amazon_s3_access_key_id'] = nil
default['mattermost']['file_amazon_s3_bucket'] = nil
default['mattermost']['file_amazon_s3_secret_access_key'] = nil
default['mattermost']['file_amazon_s3_bucket'] = nil
default['mattermost']["file_amazon_s3_endpoint"] = nil
default['mattermost']["file_amazon_s3_bucket_endpoint"] = nil
default['mattermost']["file_amazon_s3_location_constraint"] = false
default['mattermost']["file_amazon_s3_lowercase_bucket"] = false
default['mattermost']["file_amazon_s3_ssl"] = true
default['mattermost']["file_amazon_s3_sign_v2"] = false
default['mattermost']['file_enable_file_attachments'] = true
default['mattermost']['file_amazon_s3_trace'] = false

default['mattermost']['email_enable_sign_up_with_email'] = false
default['mattermost']['email_enable_sign_in_with_email'] = true
default['mattermost']['email_enable_sign_in_with_username'] = false
default['mattermost']['email_send_email_notifications'] = false
default['mattermost']['email_use_channel_in_email_notifications'] = true
default['mattermost']['email_require_email_verification'] = false
default['mattermost']['email_feedback_name'] = nil
default['mattermost']['email_feedback_email'] = nil
default['mattermost']['email_feedback_organization'] = nil
default['mattermost']['email_smtp_username'] = nil
default['mattermost']['email_smtp_password'] = nil
default['mattermost']['email_smtp_server'] = nil
default['mattermost']['email_smtp_port'] = nil
default['mattermost']['email_connection_security'] = nil
default['mattermost']['email_send_push_notifications'] = false
default['mattermost']['email_push_notification_server'] = nil
default['mattermost']['email_push_notification_contents'] = "generic"
default['mattermost']['email_enable_batching'] = false
default['mattermost']['email_batching_buffer_size'] = 256
default['mattermost']['email_batching_interval'] = 30
default['mattermost']['email_skip_server_certificate_verification'] = false
default['mattermost']['email_smtp_auth'] = false
default['mattermost']['email_notification_content_type'] = "full"

default['mattermost']['ratelimit_enable_rate_limiter'] = false
default['mattermost']['ratelimit_per_sec'] = 10
default['mattermost']['ratelimit_max_burst'] = 100
default['mattermost']['ratelimit_memory_store_size'] = 10000
default['mattermost']['ratelimit_vary_by_remote_addr'] = true
default['mattermost']['ratelimit_vary_by_user'] = false
default['mattermost']['ratelimit_vary_by_header'] = nil

default['mattermost']['privacy_show_email_address'] = true
default['mattermost']['privacy_show_full_name'] = true

default['mattermost']['localization_server_locale'] = "en"
default['mattermost']['localization_client_locale'] = "en"
default['mattermost']['localization_available_locales'] = ""

default['mattermost']['team_site_name'] = "GitLab Mattermost"
default['mattermost']['team_enable_user_creation'] = true
default['mattermost']['team_enable_open_server'] = false
default['mattermost']['team_enable_x_to_leave_channels_from_lhs'] = false
default['mattermost']['team_max_users_per_team'] = 150
default['mattermost']['team_allow_public_link'] = true
default['mattermost']['team_allow_valet_default'] = false
default['mattermost']['team_restrict_creation_to_domains'] = nil
default['mattermost']['team_restrict_team_names'] = true
default['mattermost']['team_restrict_direct_message'] = "any"
default['mattermost']['team_max_channels_per_team'] = 2000
default['mattermost']['team_user_status_away_timeout'] = 300
default['mattermost']['team_enable_confirm_notifications_to_channel'] = true
default['mattermost']['team_teammate_name_display'] = "full_name"

default['mattermost']['support_terms_of_service_link'] = "https://about.mattermost.com/default-terms/"
default['mattermost']['support_privacy_policy_link'] = "https://about.mattermost.com/default-privacy-policy/"
default['mattermost']['support_about_link'] = "https://about.mattermost.com/default-about/"
default['mattermost']['support_help_link'] = "https://about.mattermost.com/default-help/"
default['mattermost']['support_report_a_problem_link'] = "https://about.mattermost.com/default-report-a-problem/"
default['mattermost']['support_email'] = "support@example.com"

default['mattermost']['gitlab_enable'] = false
default['mattermost']['gitlab_secret'] = nil
default['mattermost']['gitlab_id'] = nil
default['mattermost']['gitlab_scope'] = nil
default['mattermost']['gitlab_auth_endpoint'] = nil
default['mattermost']['gitlab_token_endpoint'] = nil
default['mattermost']['gitlab_user_api_endpoint'] = nil

default['mattermost']['webrtc_enable'] = false
default['mattermost']['webrtc_gateway_websocket_url'] = nil
default['mattermost']['webrtc_gateway_admin_url'] = nil
default['mattermost']['webrtc_gateway_admin_secret'] = nil
default['mattermost']['webrtc_gateway_stun_uri'] = nil
default['mattermost']['webrtc_gateway_turn_uri'] = nil
default['mattermost']['webrtc_gateway_turn_username'] = nil
default['mattermost']['webrtc_gateway_turn_shared_key'] = nil

default['mattermost']['job_run_jobs'] = true
default['mattermost']['job_run_scheduler'] = true

default['mattermost']['plugin_enable'] = true
default['mattermost']['plugin_enable_uploads'] = false
default['mattermost']['plugin_directory'] = "/var/opt/gitlab/mattermost/plugins"
default['mattermost']['plugin_client_directory'] = "/var/opt/gitlab/mattermost/client-plugins"
default['mattermost']['plugin_plugins'] = {}
default['mattermost']['plugin_plugin_states'] = {}
