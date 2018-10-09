#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

name 'gpgme'

# Note: gpgme versions greater than 1.11.0 were causing some issues when tried
# to use. Check the comments in https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/2747
# if you are upgrading to 1.11.0 or higher.
default_version '1.10.0'

dependency 'libassuan'
dependency 'gnupg'

license 'LGPL-2.1'
license_file 'COPYING.LESSER'

skip_transitive_dependency_licensing true

source url: "https://www.gnupg.org/ftp/gcrypt/gpgme/gpgme-#{version}.tar.bz2",
       sha256: '1a8fed1197c3b99c35f403066bb344a26224d292afc048cfdfc4ccd5690a0693'

relative_path "gpgme-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  command './configure ' \
    "--prefix=#{install_dir}/embedded --disable-doc --disable-languages", env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end

project.exclude 'embedded/bin/gpgme-config'
