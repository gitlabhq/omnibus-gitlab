#
# Copyright:: Chef Software Inc.
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

name 'libxml2'
default_version '2.15.1'

license 'MIT'
license_file 'COPYING'
skip_transitive_dependency_licensing true

dependency 'zlib-ng'
dependency 'libiconv'
dependency 'config_guess'

if Build::Check.use_ubt?
  # NOTE: We cannot use UBT binaries in FIPS builds
  source Build::UBT.source_args(name, "2.14.5-2ubt", "8e531c2555e9437156ebbd57ced4e09081d0955fce25cca79a670cd6a67f7d6f", OhaiHelper.arch)
  build(&Build::UBT.install)
else
  # version_list: url=https://download.gnome.org/sources/libxml2/2.12/ filter=*.tar.xz
  version('2.15.1') { source sha256: 'c008bac08fd5c7b4a87f7b8a71f283fa581d80d80ff8d2efd3b26224c39bc54c' }

  minor_version = version.sub(/.\d*$/, "")

  source url: "https://download.gnome.org/sources/libxml2/#{minor_version}/libxml2-#{version}.tar.xz"

  relative_path "libxml2-#{version}"

  build do
    env = with_standard_compiler_flags(with_embedded_path)

    configure_command = [
      "--with-zlib=#{install_dir}/embedded",
      "--with-iconv=#{install_dir}/embedded",
      '--with-sax1', # required for nokogiri to compile
      '--without-python',
      '--without-icu'
    ]

    update_config_guess

    configure(*configure_command, env: env)

    make "-j #{workers}", env: env
    make 'install', env: env
  end
end

project.exclude 'embedded/lib/xml2Conf.sh'
project.exclude 'embedded/bin/xml2-config'
project.exclude 'embedded/lib/cmake/libxml2/libxml2-config.cmake'
