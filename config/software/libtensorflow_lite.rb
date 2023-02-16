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
version = Gitlab::Version.new('libtensorflow_lite', '2.6.0')

default_version version.print
source git: version.remote

license 'Apache-2.0'
license_file 'LICENSE'
skip_transitive_dependency_licensing true

build do
  env = {}
  build_dir = "#{Omnibus::Config.source_dir}/libtensorflow_lite/tflite_build"

  mkdir "#{install_dir}/embedded/lib"
  mkdir build_dir.to_s

  block 'use a custom compiler for OSs with older gcc' do
    if ohai['platform'] == 'centos' && ohai['platform_version'].start_with?('7.')
      env['CC'] = "/opt/rh/devtoolset-8/root/usr/bin/gcc"
      env['CXX'] = "/opt/rh/devtoolset-8/root/usr/bin/g++"
    elsif ohai['platform'] == 'suse' && ohai['platform_version'].start_with?('12.')
      env['CC'] = "/usr/bin/gcc-5"
      env['CXX'] = "/usr/bin/g++-5"
    elsif ohai['platform'] == 'opensuseleap' && ohai['platform_version'].start_with?('15.')
      env['CC'] = "/usr/bin/gcc-8"
      env['CXX'] = "/usr/bin/g++-8"
    elsif ohai['platform'] == 'amazon' && ohai['platform_version'] == '2'
      env['CC'] = "/usr/bin/gcc10-gcc"
      env['CXX'] = "/usr/bin/gcc10-g++"
    end
  end

  command "cmake #{Omnibus::Config.source_dir}/libtensorflow_lite/tensorflow/lite/c", cwd: build_dir, env: env
  command "cmake --build . -j #{workers}", cwd: build_dir, env: env
  move "#{build_dir}/libtensorflowlite_c.*", "#{install_dir}/embedded/lib"
end
