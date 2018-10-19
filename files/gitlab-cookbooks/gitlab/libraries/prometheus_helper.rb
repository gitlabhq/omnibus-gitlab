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

class PrometheusHelper
  attr_reader :node

  def initialize(node)
    @node = node
  end

  def kingpin_flags(service)
    config = []

    node['gitlab'][service]['flags'].each do |flag_key, flag_value|
      if flag_value == true
        config << "--#{flag_key}"
      elsif flag_value == false
        config << "--no-#{flag_key}"
      else
        next if flag_value.empty?
        config << "--#{flag_key}=#{flag_value}"
      end
    end

    config.join(" ")
  end

  def flags(service)
    config = []

    node['gitlab'][service]['flags'].each do |flag_key, flag_value|
      next if flag_value.empty?
      config << if PrometheusHelper.is_version_1?(node['gitlab']['prometheus']['home'])
                  "-#{flag_key}=#{flag_value}"
                else
                  "--#{flag_key}=#{flag_value}"
                end
    end

    config.join(" ")
  end

  # This is a class method because we need to access it from
  # `Prometheus::parse_prometheus_flags`. If it was an instance method,
  # object initialization would've been required, which needs passing `node`
  # object. Converting `GitLab['node']` to `node` is not fun.
  def self.is_version_1?(home_dir)
    # These files are present only if version 1 is/was running
    version_file = File.join(home_dir, "data", "VERSION")
    head_db = File.join(home_dir, "data", "heads.db")

    File.exist?(version_file) && File.exist?(head_db)
  end

  def is_running?
    OmnibusHelper.new(node).service_up?("prometheus")
  end

  def binary_and_rules
    if PrometheusHelper.is_version_1?(node['gitlab']['prometheus']['home'])
      %w(prometheus1 rules.v1)
    else
      %w(prometheus2 rules.v2)
    end
  end
end
