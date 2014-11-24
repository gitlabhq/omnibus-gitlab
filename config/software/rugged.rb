#
## Copyright:: Copyright (c) 2014 GitLab B.V.
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

name "rugged"
default_version "0.21.2"

dependency "ruby"
dependency "rubygems"
dependency "libgit2"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  gem "install rugged --install-dir=#{install_dir}/embedded/service/gem/ruby/2.1.0 --no-rdoc --no-ri -v #{version} -- --use-system-libraries", env: env
end
