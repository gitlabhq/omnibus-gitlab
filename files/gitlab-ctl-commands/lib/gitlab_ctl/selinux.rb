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

# For testing purposes, if the first path cannot be found load the second
begin
  require_relative '../../../../cookbooks/package/libraries/helpers/selinux_helper.rb'
rescue LoadError
  require_relative '../../../gitlab-cookbooks/package/libraries/helpers/selinux_helper.rb'
end

module GitlabCtl
  class SELinuxManager
    class << self
      def parse_options(args, banner)
        options = { verbose: false, dry_run: false }

        begin
          OptionParser.new do |opts|
            opts.banner = banner
            opts.on('-v', '--verbose', 'Show all output.') do |v|
              options[:verbose] = v
            end
            opts.on('-d', '--dry-run', 'Show what would change.') do |d|
              options[:dry_run] = d
              options[:verbose] = true
            end
          end.parse!(args)
        rescue OptionParser::InvalidOption
          args << '-h'
          options = parse_options(args, banner)
        end

        options
      end
    end
  end
end
