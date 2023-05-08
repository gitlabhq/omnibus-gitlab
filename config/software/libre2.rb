#
## Copyright:: Copyright (c) 2017 GitLab B.V.
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

name 'libre2'

version = Gitlab::Version.new('libre2', '2023-03-01')
default_version version.print(false)
display_version version.print(false).tr('-', '')

license 'BSD'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)

  block 'compile re2 with a custom compiler if necessary' do
    if ohai['platform'] == 'centos' && ohai['platform_version'].start_with?('7.')
      env['CC'] = "/opt/rh/devtoolset-8/root/usr/bin/gcc"
      env['CXX'] = "/opt/rh/devtoolset-8/root/usr/bin/g++"
    end

    # This is not enabled by default for the g++ on Ubuntu 16.04.
    # https://github.com/google/re2/wiki/Install says C++11 is required.
    env['CPPFLAGS'] << ' -std=c++11'

    make "-j #{workers}", env: env
    make "install prefix=#{install_dir}/embedded", env: env
  end
end
