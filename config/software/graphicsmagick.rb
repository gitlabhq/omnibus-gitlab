#
# Copyright:: Copyright (c) 2018 GitLab Inc.
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

name 'graphicsmagick'
default_version '1.3.26'

license 'MIT'
license_file 'Copyright.txt'

dependency 'libpng'
dependency 'zlib'

source url: "http://ftp.icm.edu.pl/pub/unix/graphics/GraphicsMagick/1.3/GraphicsMagick-#{version}.tar.gz",
       sha256: 'ab06d07cda5181f7829714c9f5641c0a93a0c3af2dacd747ed48d534e1ed0b3a'

relative_path "GraphicsMagick-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  configure_command = [
    './configure',
    "--prefix=#{install_dir}/embedded",
    '--disable-openmp',
    '--without-magick-plus-plus',
    '--with-perl=no',
    '--without-bzlib',
    '--without-dps',
    '--without-fpx',
    '--without-gslib',
    '--without-jbig',
    '--without-webp',
    '--without-jpeg',
    '--without-jp2',
    '--without-lcms2',
    '--without-lzma',
    '--with-png',
    "--with-sysroot=#{install_dir}/embedded",
    '--without-tiff',
    '--without-trio',
    '--without-ttf',
    '--without-umem',
    '--without-wmf',
    '--without-xml',
    '--with-zlib',
    '--without-x'
  ]

  command configure_command.join(' '), env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end
