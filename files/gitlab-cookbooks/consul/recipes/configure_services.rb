#
# Copyright:: Copyright (c) 2020 GitLab Inc.
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

consul_helper = ConsulHelper.new(node)

consul_helper.enabled_services.each do |service|
  include_recipe "consul::enable_service_#{service}"
end

consul_helper.disabled_services.each do |service|
  include_recipe "consul::disable_service_#{service}"
end
