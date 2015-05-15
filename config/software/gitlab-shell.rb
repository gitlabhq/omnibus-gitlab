#
## Copyright:: Copyright (c) 2014 GitLab.com
## License:: Apache License, Version 2.0
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
## http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

name "gitlab-shell"
default_version "4d30c0c5d3d0f23a221ee507b6bd110a539b8570" # 2.6.3

dependency "ruby"
dependency "rsync"

source :git => "https://gitlab.com/gitlab-org/gitlab-shell.git"

build do
  command "mkdir -p #{install_dir}/embedded/service/gitlab-shell"
  command "#{install_dir}/embedded/bin/rsync -a --delete --exclude=.git/*** --exclude=.gitignore ./ #{install_dir}/embedded/service/gitlab-shell/"
  block do
    env_shebang = "#!/usr/bin/env ruby"
    `grep -r -l '^#{env_shebang}' #{project_dir}`.split("\n").each do |ruby_script|
      script = File.read(ruby_script)
      erb :dest => ruby_script.sub(project_dir, "#{install_dir}/embedded/service/gitlab-shell"),
        :source => "ruby_script_wrapper.erb",
        :mode => 0755,
        :vars => {:script => script, :install_dir => install_dir}
    end
  end
end
