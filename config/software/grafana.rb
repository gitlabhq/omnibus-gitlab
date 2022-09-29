#
# Copyright:: Copyright (c) 2019 GitLab Inc.
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

name 'grafana'
version = Gitlab::Version.new('grafana', 'v7.5.16')
default_version version.print(false)

license 'APACHE-2.0'
license_file 'LICENSE'
license_file 'NOTICE.md'

skip_transitive_dependency_licensing true

arch = if OhaiHelper.raspberry_pi?
         'armv7'
       elsif /aarch64/.match?(ohai['kernel']['machine'])
         'arm64'
       else
         'amd64'
       end

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # cypress e2e tests not needed for production build, and doesn't work on armv7
  # see https://github.com/cypress-io/cypress/issues/6110
  env['CYPRESS_INSTALL_BINARY'] = '0'

  patch source: '1-cve-2022-31107-oauth-vulnerability.patch'

  # Build backend
  make 'build-go', env: env

  # Build frontend
  if OhaiHelper.raspberry_pi?
    # CAUTION:
    #
    # This is a temporary workaround to reduce the build time for 32-bit
    # environment.
    #
    # We do does not build the frontend from source, instead we download it
    # from the official release of Grafana.
    #
    # The caveat is that, for RPi, we can not patch the frontend and security
    # fixes are limited to backend.

    # drop `v` from the version
    release_version = default_version[1..]
    release_archive = "grafana-#{release_version}.linux-#{arch}.tar.gz"
    release_url = "https://dl.grafana.com/oss/release/#{release_archive}"

    # download and extract the release archive from the official source
    command("curl -fL --retry 3 -o #{release_archive} #{release_url}")
    command("tar -xvf #{release_archive}")

    # replace public directory from the official release
    delete("public/")
    move("grafana-#{release_version}/public/", "public/")
  else
    # build frontend from source
    make 'node_modules', env: env

    assets_compile_env = {
      'NODE_ENV' => 'production'
    }

    make 'build-js', env: assets_compile_env
  end

  # Copy binaries
  command "mkdir -p #{install_dir}/embedded/bin"
  copy 'bin/linux-*/grafana-server', "#{install_dir}/embedded/bin/grafana-server"
  copy 'bin/linux-*/grafana-cli', "#{install_dir}/embedded/bin/grafana-cli"

  # Copy static assets
  command "mkdir -p #{install_dir}/embedded/service/grafana/public"
  sync 'public/', "#{install_dir}/embedded/service/grafana/public/"

  # Copy default configuration
  command "mkdir -p #{install_dir}/embedded/service/grafana/conf"
  copy 'conf/defaults.ini', "#{install_dir}/embedded/service/grafana/conf/defaults.ini"
end
