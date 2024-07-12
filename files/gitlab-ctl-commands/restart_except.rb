#
# Copyright:: Copyright (c) 2014 GitLab B.V.
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

add_command_under_category('restart-except',
                           'service-management',
                           'Restart all services except: service_name ...', 2) do |cmd_name|
  args = ARGV.dup[3..]

  if args.empty?
    puts "Please provide services to exclude from restart"
    exit 1
  end

  # get_all_services
  services = get_all_services

  # if provided service is not in the list of services, print error message
  args.each do |service|
    unless services.include?(service)
      puts "Service '#{service}' not found"
      exit 1
    end
  end

  puts "Restarting all services except: #{args.join(', ')}."

  exit_status = 0
  # restart all services except the ones provided
  services.each do |service|
    exit_status += run_sv_command_for_service('restart', service) unless args.include?(service)
  end

  exit! exit_status
end
