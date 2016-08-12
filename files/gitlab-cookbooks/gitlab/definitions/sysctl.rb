#
# Copyright:: Copyright (c) 2015 GitLab B.V.
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

define :sysctl, value: nil do
  name = params[:name]
  value = params[:value]

  directory "create /etc/sysctl.d for #{name}" do
    path "/etc/sysctl.d"
    mode "0755"
    recursive true
  end

  conf_name = "90-omnibus-gitlab-#{name}.conf"

  file "create /opt/gitlab/embedded/etc/#{conf_name} #{name}" do
    path "/opt/gitlab/embedded/etc/#{conf_name}"
    content "#{name} = #{value}\n"
    notifies :run, "execute[load sysctl conf #{name}]", :immediately
  end

  link "/etc/sysctl.d/#{conf_name}" do
    to "/opt/gitlab/embedded/etc/#{conf_name}"
  end

  # Remove old (not-used) configs
  [
    "/etc/sysctl.d/90-postgresql.conf",
    "/etc/sysctl.d/90-unicorn.conf",
    "/opt/gitlab/embedded/etc/90-omnibus-gitlab.conf",
    "/etc/sysctl.d/90-omnibus-gitlab.conf"
  ].each do |conf|
    file "delete #{conf} #{name}" do
      path conf
      action :delete
      only_if { File.exists?(conf) }
    end
  end

  # Load the settings right away
  execute "load sysctl conf #{name}" do
    command "cat /etc/sysctl.conf /etc/sysctl.d/*.conf  | sysctl -e -p -"
    action :nothing
  end
end
