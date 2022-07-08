#
# Copyright:: Copyright (c) 2018 GitLab Inc.
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
require_relative 'redis_uri.rb'
require_relative 'redis_helper.rb'

module GitlabExporter
  class << self
    def parse_variables
      parse_gitlab_exporter_settings
      validate_tls_config
    end

    def parse_gitlab_exporter_settings
      # By default, disable sidekiq probe of gitlab-exporter if Redis sentinels
      # are found. If user has explicitly specified something in gitlab.rb, use
      # that.
      return if Gitlab['gitlab_exporter'].key?('probe_sidekiq') && !Gitlab['gitlab_exporter']['probe_sidekiq'].nil?

      Gitlab['gitlab_exporter']['probe_sidekiq'] = !RedisHelper::Checks.has_sentinels?
    end

    def validate_tls_config
      return unless Gitlab['gitlab_exporter']['tls_enabled']

      %i[tls_cert_path tls_key_path].each do |key|
        raise "TLS enabled for GitLab Exporter, but #{key} not specified in config" unless Gitlab['gitlab_exporter'].key?(key)

        raise "File specified via gitlab_exporter['#{key}'] not found: #{Gitlab['gitlab_exporter'][key]}" unless File.exist?(Gitlab['gitlab_exporter'][key])
      end
    end
  end
end
