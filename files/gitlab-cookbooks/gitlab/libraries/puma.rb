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

module Puma
  class << self
    include MetricsExporterHelper

    def parse_variables
      return unless Services.enabled?('puma')

      parse_listen_address

      check_consistent_exporter_tls_settings('puma')
    end

    def parse_listen_address
      https_url = puma_https_url

      # As described in https://gitlab.com/gitlab-org/gitlab/-/blob/master/workhorse/doc/operations/configuration.md#interaction-of-authbackend-and-authsocket,
      # Workhorse will give precedence to a UNIX socket. In order to ensure
      # traffic is sent over an encrypted channel, set auth_backend if SSL
      # has been enabled on Puma.
      if https_url
        Gitlab['gitlab_workhorse']['auth_backend'] = https_url if Gitlab['gitlab_workhorse']['auth_backend'].nil?
        Gitlab['puma']['prometheus_scrape_scheme'] ||= 'https'
      else
        Gitlab['puma']['listen'] ||= '127.0.0.1'
        Gitlab['gitlab_workhorse']['auth_socket'] = puma_socket if Gitlab['gitlab_workhorse']['auth_backend'].nil?
      end
    end

    def workers(total_memory = Gitlab['node']['memory']['total'].to_i)
      [
        2, # Two is the minimum or web editor will no longer work.
        [
          cpu_threads,
          worker_memory(total_memory).to_i,
        ].min # min because we want to exceed neither CPU nor RAM
      ].max # max because we need at least 2 workers
    end

    def cpu_threads
      # Ohai may not parse lscpu properly: https://github.com/chef/ohai/issues/1760
      return 1 if Gitlab['node']['cpu'].nil?

      # lscpu may return 0 for total number of CPUs: https://github.com/chef/ohai/issues/1755
      [Gitlab['node']['cpu']['total'].to_i, Gitlab['node']['cpu']['real'].to_i].max
    end

    # See how many worker processes fit in the system.
    # Reserve 1.5G of memory for other processes.
    # Currently, Puma workers can use 1GB per process.
    def worker_memory(total_memory, reserved_memory = 1572864, per_worker_ram = 1048576)
      (total_memory - reserved_memory) / per_worker_ram
    end

    private

    def puma_socket
      user_config_or_default('socket')
    end

    def puma_https_url
      url(host: user_config['ssl_listen'], port: user_config['ssl_port'], scheme: 'https') if user_config['ssl_listen'] && user_config['ssl_port']
    end

    def default_config
      Gitlab['node']['gitlab']['puma']
    end

    def user_config
      Gitlab['puma']
    end

    def metrics_enabled?
      user_config_or_default('exporter_enabled')
    end

    def url(host:, port:, scheme:)
      Addressable::URI.new(host: host, port: port, scheme: scheme).to_s
    end
  end
end
