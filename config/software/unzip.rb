#
## Copyright:: Copyright (c) 2016 GitLab Inc
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

name 'unzip'

# Version tied to Debian's release, not downloaded source version.
default_version '6.0.27'

license 'Info-ZIP'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

# We download the pure 6.0 source code and then apply all of Debian's
# patches and track to their version for CVE and security validation.
source url: 'https://downloads.sourceforge.net/project/infozip/UnZip%206.x%20%28latest%29/UnZip%206.0/unzip60.tar.gz',
       sha256: '036d96991646d0449ed0aa952e4fbe21b476ce994abc276e49d30e686708bd37'

relative_path 'unzip60'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # This software follows Debian as an upstream to ensure CVEs are resolved
  # and automatic scanners can detect the updated versions with fixes.
  #
  # If new patches are applied, ensure that the `default_version` above is
  # updated to match the new upstream version number.
  #
  # Check for newer versions at https://sources.debian.org/src/unzip/
  #
  # Check in `debian/patches` and `debian/changelog` for patch files.
  patch source: '01-manpages-in-section-1-not-in-section-1l.patch'
  # Replaces Debian upstream's 02 patch which is branding for who maintains
  # the final package build from this source stream.
  patch source: '0-gitlab-source.patch'
  patch source: '03-include-unistd-for-kfreebsd.patch'
  patch source: '04-handle-pkware-verification-bit.patch'
  patch source: '05-fix-uid-gid-handling.patch'
  patch source: '06-initialize-the-symlink-flag.patch'
  # Resolves CVE-2018-18384
  # See https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=741384
  patch source: '07-increase-size-of-cfactorstr.patch'
  patch source: '08-allow-greater-hostver-values.patch'
  patch source: '09-cve-2014-8139-crc-overflow.patch'
  patch source: '10-cve-2014-8140-test-compr-eb.patch'
  patch source: '11-cve-2014-8141-getzip64data.patch'
  patch source: '12-cve-2014-9636-test-compr-eb.patch'
  patch source: '13-remove-build-date.patch'
  patch source: '14-cve-2015-7696.patch'
  patch source: '15-cve-2015-7697.patch'
  patch source: '16-fix-integer-underflow-csiz-decrypted.patch'
  patch source: '17-restore-unix-timestamps-accurately.patch'
  patch source: '18-cve-2014-9913-unzip-buffer-overflow.patch'
  patch source: '19-cve-2016-9844-zipinfo-buffer-overflow.patch'
  patch source: '20-cve-2018-1000035-unzip-buffer-overflow.patch'
  patch source: '21-fix-warning-messages-on-big-files.patch'
  patch source: '22-cve-2019-13232-fix-bug-in-undefer-input.patch'
  patch source: '23-cve-2019-13232-zip-bomb-with-overlapped-entries.patch'
  patch source: '24-cve-2019-13232-do-not-raise-alert-for-misplaced-central-directory.patch'
  patch source: '25-cve-2019-13232-fix-bug-in-uzbunzip2.patch'
  patch source: '26-cve-2019-13232-fix-bug-in-uzinflate.patch'
  patch source: '27-zipgrep-avoid-test-errors.patch'
  patch source: '28-cve-2022-0529-and-cve-2022-0530.patch'

  make '-f unix/Makefile clean', env: env
  make "-j #{workers} -f unix/Makefile generic", env: env
  make "-f unix/Makefile prefix=#{install_dir}/embedded install", env: env
end
