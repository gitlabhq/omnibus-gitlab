#
# Copyright 2016 GitLab Inc.
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

# We are pinning to 1.6 because 1.7 wasn't compatible with our version of chef,
# and our chef-gem dependency will pull anything in 1.x range for mixlib-log

name "mixlib-log"
default_version "1.6.0"

license "Apache-2.0"
license_file "https://raw.githubusercontent.com/chef/mixlib-log/master/LICENSE"

dependency "ruby"
dependency "rubygems"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  gem "install mixlib-log" \
      " --version '#{version}'" \
      " --bindir '#{install_dir}/embedded/bin'" \
      " --no-ri --no-rdoc", env: env
end
