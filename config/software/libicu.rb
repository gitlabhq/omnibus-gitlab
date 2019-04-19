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

name 'libicu'

version = Gitlab::Version.new('libicu', 'release-57-1')

default_version version.print(false)

source git: version.remote

license 'MIT'
license_file 'icu/LICENSE'

skip_transitive_dependency_licensing true

build do
  env = with_standard_compiler_flags(with_embedded_path)
  env['LD_RPATH'] = "#{install_dir}/embedded/lib"
  cwd = "#{Omnibus::Config.source_dir}/libicu/icu4c/source"

  command ['./runConfigureICU',
           'Linux/gcc',
           "--prefix=#{install_dir}/embedded",
           '--with-data-packaging=files',
           '--enable-shared',
           '--without-samples'].join(' '), env: env, cwd: cwd

  make "-j #{workers}", env: env, cwd: cwd
  make 'install', env: env, cwd: cwd

  # The git repository uses the format release-MAJ-MIN for the release tags
  # We need to reference the actual version number to create this link, which
  # is required by Gitaly
  actual_version = default_version.split('-')[1..2].join('.')
  link "#{install_dir}/embedded/share/icu/#{actual_version}", "#{install_dir}/embedded/share/icu/current", force: true
end

project.exclude 'embedded/bin/icu-config'
