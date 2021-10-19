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

require 'chef/handler'
require 'rainbow'

module GitLabHandler
  class Exception < Chef::Handler
    def report
      return unless run_status.failed?

      $stderr.puts Rainbow('There was an error running gitlab-ctl reconfigure:').red
      $stderr.puts
      $stderr.puts Rainbow(run_status.exception.message).red
      $stderr.puts

      OmnibusHelper.on_exit
    end
  end

  class Attributes < Chef::Handler
    # Generate a JSON file of attributes which non-root users need access to
    def report
      return unless node['package']['public_attributes']

      data = {}
      BaseHelper.descendants.each do |klass|
        k = klass.send(:new, node)
        Chef::Mixin::DeepMerge.deep_merge!(k.public_attributes, data) if k.respond_to?(:public_attributes)
      end
      File.open('/var/opt/gitlab/public_attributes.json', 'w', 0644) { |file| file.puts data.to_json }
    end
  end
end
