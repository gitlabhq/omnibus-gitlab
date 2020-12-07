#
# Copyright:: Copyright (c) 2018-2020 GitLab Inc.
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
default_version '1.3.35'

license 'MIT'
license_file 'Copyright.txt'

skip_transitive_dependency_licensing true

dependency 'libpng'
dependency 'libjpeg-turbo'
dependency 'libtiff'
dependency 'zlib'

source url: "https://ftp.icm.edu.pl/pub/unix/graphics/GraphicsMagick/1.3/GraphicsMagick-#{version}.tar.gz",
       sha256: 'd96d5ce2ef7e0e90166551e38742713728bfd33d6f18495a9ddda938700fc055'

relative_path "GraphicsMagick-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  patch source: "png-vulnerability-fix.patch"

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
    '--without-jp2',
    '--without-lcms2',
    '--without-trio',
    '--without-ttf',
    '--without-umem',
    '--without-wmf',
    '--without-xml',
    '--without-x',
    '--with-tiff=yes',
    '--with-lzma=yes',
    '--with-jpeg=yes',
    '--with-zlib=yes',
    '--with-png=yes',
    "--with-sysroot=#{install_dir}/embedded"
  ]

  command configure_command.join(' '), env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end
