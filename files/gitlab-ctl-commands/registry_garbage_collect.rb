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

require 'shellwords'

require_relative 'lib/gitlab_ctl/registry/garbage_collect'

add_command_under_category 'registry-garbage-collect', 'container-registry', 'Run Container Registry garbage collection.', 2 do |cmd_name, path|
  result = GitlabCtl::Registry::GarbageCollect.new(self, path, ARGV).execute!
  Kernel.exit !!result
end
