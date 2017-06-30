#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

add_command 'diff-config', 'Compare the user configuration with package available configuration', 1 do |cmd_name|
  user_config_file = "/etc/gitlab/gitlab.rb"
  config_template_file = "/opt/gitlab/etc/gitlab.rb.template"

  unless File.exist?(user_config_file)
    puts "Could not find '/etc/gitlab/gitlab.rb' configuration file. Did you run 'sudo gitlab-ctl reconfigure'?"
    Kernel.exit 1
  end

  unless File.exist?(config_template_file)
    puts "Could not find '/opt/gitlab/etc/gitlab.rb.template' template file. Is your package installed correctly?"
    Kernel.exit 1
  end

  command = %W( #{base_path}/embedded/bin/git
                diff
                #{user_config_file}
                #{config_template_file})

  status = run_command(command.join(" "))
  status.success?
end
