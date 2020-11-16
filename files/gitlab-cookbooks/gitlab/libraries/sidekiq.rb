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

module Sidekiq
  class << self
    MIGRATION_DOCS_URL = 'https://docs.gitlab.com/ee/administration/operations/extra_sidekiq_processes.html#migrating-to-sidekiq-cluster'.freeze
    MIGRATION_ISSUE_URL = 'https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/340'.freeze
    # Remove experimental_queue_selector with https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/646
    CLUSTER_ATTRIBUTE_NAMES = %w(ha log_directory queue_selector experimental_queue_selector
                                 interval max_concurrency min_concurrency negate
                                 queue_groups shutdown_timeout).freeze

    def parse_variables
      # Sidekiq cluster was manually enabled, print a warning and fall back to
      # the old behaviour
      if Gitlab['sidekiq_cluster']['enable']
        Gitlab['sidekiq']['cluster'] = false

        LoggingHelper.deprecation <<~MSG
          Using Sidekiq Cluster is now default, please move your settings over
          to the `sidekiq[*]` config. Configuring `sidekiq_cluster[*]` directly will
          removed in 14.0.
          #{MIGRATION_DOCS_URL}
          Migration issue: #{MIGRATION_ISSUE_URL}
        MSG
      end

      # If user had explicitly turned off sidekiq, let's stop processing here.
      return if user_settings['enable'] == false

      # When sidekiq is enabled by a role (DEFAULT_ROLE, for example),
      # Gitlab['node']['sidekiq']['enable'] gets set to `true`. If that didn't
      # happen, and user didn't explicitly turn on sidekiq, let's stop
      # processing here. If not, we will inadvertently enable sidekiq_cluster
      # few lines below, which will cause the `sidekiq-cluster` recipe to run
      # and the `sidekiq` runit_service resource to get created and hence
      # sidekiq service to run in places it is not expected to.
      return if defaults['enable'] == false && user_settings['enable'] != true

      # The cluster feature was explicitly disabled, fallback to the regular sidekiq
      if Gitlab['sidekiq']['cluster'] == false
        LoggingHelper.deprecation <<~MSG
          Running Sidekiq directly is deprecated and will be removed in Gitlab 14.0.
          Please consider running sidekiq-cluster.
          #{MIGRATION_DOCS_URL}
          Migration issue: #{MIGRATION_ISSUE_URL}
        MSG
        return
      end

      Gitlab['sidekiq']['enable'] = false
      Gitlab['sidekiq_cluster']['enable'] = true

      Gitlab['sidekiq_cluster'].merge!(sidekiq_cluster_settings)

      # Set the concurrency based on the single `concurrency` setting if it was
      # present
      configured_concurrency = user_settings['concurrency']
      return unless configured_concurrency

      if configured_concurrency && user_configured_cluster_concurrency?
        raise "Cannot specify `concurrency` in combination with `min_concurrency` "\
              "and `max_concurrency`"
      end

      Gitlab['sidekiq_cluster']['min_concurrency'] =
        Gitlab['sidekiq_cluster']['max_concurrency'] =
          configured_concurrency
    end

    private

    def user_settings
      Gitlab['sidekiq']
    end

    def defaults
      Gitlab['node']['gitlab']['sidekiq']
    end

    def cluster_package_defaults
      defaults.to_hash.slice(*CLUSTER_ATTRIBUTE_NAMES)
    end

    def cluster_user_settings
      user_settings.slice(*CLUSTER_ATTRIBUTE_NAMES)
    end

    def sidekiq_cluster_settings
      cluster_package_defaults.slice(*CLUSTER_ATTRIBUTE_NAMES)
        .merge(cluster_user_settings)
    end

    def user_configured_cluster_concurrency?
      cluster_user_settings.key?('min_concurrency') ||
        cluster_user_settings.key?('max_concurrency')
    end
  end
end
