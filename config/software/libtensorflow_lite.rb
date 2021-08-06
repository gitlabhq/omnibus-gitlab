#
## Copyright:: Copyright (c) 2021 GitLab Inc.
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

name 'libtensorflow_lite'
version = Gitlab::Version.new('libtensorflow_lite', '2.5.0')

default_version version.print
source git: version.remote

license 'Apache-2.0'
license_file 'LICENSE'
skip_transitive_dependency_licensing true

build do
  build_dir = "#{Omnibus::Config.source_dir}/libtensorflow_lite/tflite_build"
  command "mkdir -p #{install_dir}/embedded/lib #{build_dir}"
  command "cmake #{Omnibus::Config.source_dir}/libtensorflow_lite/tensorflow/lite/c", cwd: build_dir
  command "cmake --build . -j #{workers}", cwd: build_dir
  move "#{build_dir}/libtensorflowlite_c.*", "#{install_dir}/embedded/lib"
end
