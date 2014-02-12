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
version "v1.8.0"

dependency "ruby"
dependency "rsync"

source :git => "https://gitlab.com/gitlab-org/gitlab-shell.git"

build do
  block do
    `grep -r -l '#!/usr/bin/env ruby' #{project_dir}`.split("\n").each do |ruby_script|
      File.open(ruby_script, "r+") do |file|
        script = file.read
        file.rewind
        file.truncate(0)
        file.print <<-EOH
#!/opt/gitlab/embedded/bin/ruby
# Fix the PATH so that gitlab-shell can find git-upload-pack and friends.
ENV['PATH'] = '/opt/gitlab/bin:/opt/gitlab/embedded/bin:' + ENV['PATH']

        EOH
        file.print script
      end
    end
  end
  command "mkdir -p #{install_dir}/embedded/service/gitlab-shell"
  command "#{install_dir}/embedded/bin/rsync -a --delete --exclude=.git/*** --exclude=.gitignore ./ #{install_dir}/embedded/service/gitlab-shell/"
end
