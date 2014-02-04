#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'mixlib/config'
require 'chef/mash'
require 'chef/json_compat'
require 'chef/mixin/deep_merge'
require 'securerandom'

module Gitlab
  extend(Mixlib::Config)

  bootstrap Mash.new
  postgresql Mash.new
  redis Mash.new
  node nil

  class << self

    # guards against creating secrets on non-bootstrap node
    def generate_hex(chars)
      SecureRandom.hex(chars)
    end

    def generate_secrets(node_name)
      existing_secrets ||= Hash.new
      if File.exists?("/etc/gitlab/gitlab-secrets.json")
        existing_secrets = Chef::JSONCompat.from_json(File.read("/etc/gitlab/gitlab-secrets.json"))
      end
      existing_secrets.each do |k, v|
        v.each do |pk, p|
          Gitlab[k][pk] = p
        end
      end

      Gitlab['postgresql']['sql_password'] ||= generate_hex(50)

      if File.directory?("/etc/gitlab")
        File.open("/etc/gitlab/gitlab-secrets.json", "w") do |f|
          f.puts(
            Chef::JSONCompat.to_json_pretty({
              'postgresql' => {
                'sql_password' => Gitlab['postgresql']['sql_password'],
              },
            })
          )
          system("chmod 0600 /etc/gitlab/gitlab-secrets.json")
        end
      end
    end

    def generate_hash
      results = { "gitlab" => {} }
      [
        "bootstrap",
        "redis",
        "postgresql"
      ].each do |key|
        rkey = key.gsub('_', '-')
        results['gitlab'][rkey] = Gitlab[key]
      end

      results
    end

    def generate_config(node_name)
      generate_secrets(node_name)
      generate_hash
    end
  end
end
