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
require 'optparse'

require "#{base_path}/embedded/service/omnibus-ctl/lib/gitlab_ctl"
require "#{base_path}/embedded/service/omnibus-ctl/lib/registry/registry_database"

add_command_under_category('registry-database', 'container-registry', 'Manage Container Registry database.', 2) do
  begin
    options = RegistryDatabase.parse_options!(self, ARGV)
  rescue OptionParser::ParseError => e
    warn "#{e}\n\n#{RegistryDatabase::USAGE}"
    exit 128
  end

  puts "Running #{options[:command]} #{options[:subcommand]}"
  RegistryDatabase.execute(options)
  exit 0
end
