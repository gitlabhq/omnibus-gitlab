require 'chef_helper'

RSpec.describe 'gitlab::gitlab-rails' do
  include_context 'gitlab-rails'

  describe 'cron settings' do
    context 'with default values' do
      it "renders gitlab.yml without any cron settings" do
        expect(gitlab_yml[:production][:cron_jobs]).to be nil
      end
    end

    context 'with user specified values' do
      using RSpec::Parameterized::TableSyntax

      where(:gitlab_yml_setting, :gitlab_rb_setting) do
        'admin_email_worker'                                     | 'admin_email_worker_cron'
        'analytics_devops_adoption_create_all_snapshots_worker'  | 'analytics_devops_adoption_create_all_snapshots_worker'
        'analytics_usage_trends_count_job_trigger_worker'        | 'analytics_usage_trends_count_job_trigger_worker_cron'
        'ci_archive_traces_cron_worker'                          | 'ci_archive_traces_cron_worker_cron'
        'ci_platform_metrics_update_cron_worker'                 | 'ci_platform_metrics_update_cron_worker'
        'elastic_index_bulk_cron_worker'                         | 'elastic_index_bulk_cron'
        'environments_auto_stop_cron_worker'                     | 'environments_auto_stop_cron_worker_cron'
        'expire_build_artifacts_worker'                          | 'expire_build_artifacts_worker_cron'
        'geo_migrated_local_files_clean_up_worker'               | 'geo_migrated_local_files_clean_up_worker_cron'
        'geo_prune_event_log_worker'                             | 'geo_prune_event_log_worker_cron'
        'geo_repository_sync_worker'                             | 'geo_repository_sync_worker_cron'
        'geo_repository_verification_primary_batch_worker'       | 'geo_repository_verification_primary_batch_worker_cron'
        'geo_repository_verification_secondary_scheduler_worker' | 'geo_repository_verification_secondary_scheduler_worker_cron'
        'geo_secondary_registry_consistency_worker'              | 'geo_secondary_registry_consistency_worker'
        'geo_secondary_usage_data_cron_worker'                   | 'geo_secondary_usage_data_cron_worker'
        'historical_data_worker'                                 | 'historical_data_worker_cron'
        'ldap_group_sync_worker'                                 | 'ldap_group_sync_worker_cron'
        'ldap_sync_worker'                                       | 'ldap_sync_worker_cron'
        'member_invitation_reminder_emails_worker'               | 'member_invitation_reminder_emails_worker_cron'
        'pages_domain_removal_cron_worker'                       | 'pages_domain_removal_cron_worker'
        'pages_domain_ssl_renewal_cron_worker'                   | 'pages_domain_ssl_renewal_cron_worker'
        'pages_domain_verification_cron_worker'                  | 'pages_domain_verification_cron_worker'
        'personal_access_tokens_expired_notification_worker'     | 'personal_access_tokens_expired_notification_worker_cron'
        'personal_access_tokens_expiring_worker'                 | 'personal_access_tokens_expiring_worker_cron'
        'pipeline_schedule_worker'                               | 'pipeline_schedule_worker_cron'
        'remove_unaccepted_member_invites_worker'                | 'remove_unaccepted_member_invites_cron_worker'
        'repository_archive_cache_worker'                        | 'repository_archive_cache_worker_cron'
        'repository_check_worker'                                | 'repository_check_worker_cron'
        'schedule_migrate_external_diffs_worker'                 | 'schedule_migrate_external_diffs_worker_cron'
        'stuck_ci_jobs_worker'                                   | 'stuck_ci_jobs_worker_cron'
        'user_status_cleanup_batch_worker'                       | 'user_status_cleanup_batch_worker_cron'
        'namespaces_in_product_marketing_emails_worker'          | 'namespaces_in_product_marketing_emails_worker_cron'
        'ssh_keys_expired_notification_worker'                   | 'ssh_keys_expired_notification_worker_cron'
        'ssh_keys_expiring_soon_notification_worker'             | 'ssh_keys_expiring_soon_notification_worker_cron'
        'loose_foreign_keys_cleanup_worker'                      | 'loose_foreign_keys_cleanup_worker_cron'
        'ci_runners_stale_group_runners_prune_worker_cron'       | 'ci_runners_stale_group_runners_prune_worker_cron'
        'ci_runner_versions_reconciliation_worker'               | 'ci_runner_versions_reconciliation_worker_cron'
      end

      with_them do
        before do
          stub_gitlab_rb(
            gitlab_rails: {
              gitlab_rb_setting => '1 2 3 4 5'
            }.transform_keys(&:to_sym)
          )
        end

        it "renders gitlab.yml with user specified cron settings" do
          config = gitlab_yml[:production][:cron_jobs][gitlab_yml_setting.to_sym][:cron]
          expect(config).to eq '1 2 3 4 5'
        end
      end
    end
  end
end
