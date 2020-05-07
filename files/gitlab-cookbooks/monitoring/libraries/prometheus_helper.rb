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

    node_service(service)['flags'].each do |flag_key, flag_value|
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

    node_service(service)['flags'].each do |flag_key, flag_value|
      next if flag_value.empty?

      config << "--#{flag_key}=#{flag_value}"
    end

    config.join(" ")
  end

  def is_running?
    OmnibusHelper.new(node).service_up?("prometheus")
  end

  private

  def node_service(service)
    node['monitoring'][service]
  end
end
