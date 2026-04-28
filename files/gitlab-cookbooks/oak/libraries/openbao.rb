# Copyright:: Copyright (c) 2026 GitLab Inc.
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

require 'uri'

module Oak
  module OpenBao
    class << self
      def parse_variables
        return unless Oak.enabled?
        return unless component_enabled?

        validate_external_url
        parse_external_url
        validate_internal_url
        parse_rails_openbao_urls
      end

      def component_enabled?
        !!Gitlab['oak']['components']&.dig('openbao', 'enable')
      end

      private

      def parse_external_url
        uri = URI(Gitlab['oak']['components']['openbao']['external_url'].to_s)

        raise "OAK OpenBao external URL must include a scheme and FQDN, " \
          "e.g. http://openbao.example.com" unless uri.host

        Gitlab['oak']['components']['openbao']['fqdn'] ||= uri.host
        Gitlab['oak']['components']['openbao']['listen_port'] ||= uri.port
      end

      def parse_rails_openbao_urls
        Gitlab['gitlab_rails']['openbao'] ||= {}
        Gitlab['gitlab_rails']['openbao']['url'] ||=
          Gitlab['oak']['components']['openbao']['external_url']
        Gitlab['gitlab_rails']['openbao']['internal_url'] ||=
          Gitlab['oak']['components']['openbao']['internal_url']
      end

      def validate_external_url
        url = Gitlab['oak']['components']['openbao']['external_url']
        raise "OAK OpenBao component is enabled but " \
          "`oak['components']['openbao']['external_url']` is not set." \
          if url.nil? || url.empty?
      end

      def validate_internal_url
        internal_url = Gitlab['oak']['components']['openbao']['internal_url']
        raise "OAK OpenBao component is enabled but " \
          "`oak['components']['openbao']['internal_url']` is not set." \
          if internal_url.nil? || internal_url.empty?
      end
    end
  end
end
