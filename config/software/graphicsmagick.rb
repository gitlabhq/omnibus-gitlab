#
# Copyright:: Copyright (c) 2018-2021 GitLab Inc.
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
default_version '1.3.36'

license 'MIT'
license_file 'Copyright.txt'

skip_transitive_dependency_licensing true

dependency 'libpng'
dependency 'libjpeg-turbo'
dependency 'libtiff'
dependency 'zlib'

source url: "https://sourceforge.net/projects/graphicsmagick/files/graphicsmagick/#{version}/GraphicsMagick-#{version}.tar.gz",
       sha256: '1e6723c48c4abbb31197fadf8396b2d579d97e197123edc70a4f057f0533d563'

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
    "--with-sysroot=#{install_dir}/embedded",
    "--without-zstd"
  ]

  command configure_command.join(' '), env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end
