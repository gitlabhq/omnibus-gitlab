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

name "gitlab-workhorse"
default_version "13933d2a0d5d8abf3fe2d969aeef192991ad5b2d" # 0.5.0

source :git => "https://gitlab.com/gitlab-org/gitlab-workhorse.git"

build do
  make "install PREFIX=#{install_dir}/embedded"
end
