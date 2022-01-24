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

name 'spamcheck'
version = Gitlab::Version.new('spamcheck', '0.3.0')

default_version version.print

license 'MIT'
license_file 'LICENSE'

dependency 'libtensorflow_lite'

source git: version.remote

relative_path 'src/gitlab-org/spamcheck'

build do
  env = with_standard_compiler_flags(with_embedded_path)
  env['GOPATH'] = "#{Omnibus::Config.source_dir}/spamcheck"
  env['PATH'] = "#{env['PATH']}:#{env['GOPATH']}/bin"

  command "mkdir -p #{install_dir}/embedded/service #{install_dir}/embedded/bin"
  sync './', "#{install_dir}/embedded/service/spamcheck/", exclude: %w(
    _support
    build
    config
    docs
    examples
    tests
    tools
  )

  env['CGO_CFLAGS'] = env['CFLAGS'].dup
  env['CGO_CPPFLAGS'] = env['CPPFLAGS'].dup
  env['CGO_CXXFLAGS'] = env['CXXFLAGS'].dup
  env['CGO_LDFLAGS'] = env['LDFLAGS'].dup

  make 'build', env: env
  move 'spamcheck', "#{install_dir}/embedded/bin/spamcheck"
end
