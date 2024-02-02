#
# Copyright 2012-2015 Chef Software, Inc.
# Copyright 2017-2023 GitLab Inc.
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

name 'ruby-shadow'
# From https://github.com/chef/chef/blob/3c35bd0e1d17a5bfd779fab3cc7860ea1923dec6/Gemfile#L41-L44
version = Gitlab::Version.new('ruby-shadow', 'e408599fdba93340500dad8922e9ca75072879de')
default_version version.print(false)
display_version version.print(false)

license 'Apache-2.0'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'rubygems'

source git: version.remote

relative_path 'ruby-shadow'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # Remove existing built gems in case they exist in the current dir
  delete 'ruby-shadow-*.gem'

  gem 'build ruby-shadow.gemspec', env: env
  gem 'install ruby-shadow-*.gem --no-document', env: env
end
