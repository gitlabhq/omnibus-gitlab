#
# Copyright 2012-2014 Chef Software, Inc.
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

name "ruby"
default_version "1.9.3-p547"

dependency "zlib"
dependency "ncurses"
dependency "libedit"
dependency "openssl"
dependency "libyaml"
dependency "libiconv"
dependency "libffi"
dependency "gdbm"
dependency "libgcc" if Ohai['platform'] == "solaris2"

version("1.9.3-p484") { source md5: "8ac0dee72fe12d75c8b2d0ef5d0c2968" }
version("1.9.3-p547") { source md5: "7531f9b1b35b16f3eb3d7bea786babfd" }
version("2.1.1")      { source md5: "e57fdbb8ed56e70c43f39c79da1654b2" }
version("2.1.2")      { source md5: "a5b5c83565f8bd954ee522bd287d2ca1" }

source url: "http://cache.ruby-lang.org/pub/ruby/#{version.match(/^(\d+\.\d+)/)[0]}/ruby-#{version}.tar.gz"

relative_path "ruby-#{version}"

env = with_standard_compiler_flags(with_embedded_path)

case Ohai['platform']
when "mac_os_x"
  # -Qunused-arguments suppresses "argument unused during compilation"
  # warnings. These can be produced if you compile a program that doesn't
  # link to anything in a path given with -Lextra-libs. Normally these
  # would be harmless, except that autoconf treats any output to stderr as
  # a failure when it makes a test program to check your CFLAGS (regardless
  # of the actual exit code from the compiler).
  env['CFLAGS'] << " -I#{install_dir}/embedded/include/ncurses -arch x86_64 -m64 -O3 -g -pipe -Qunused-arguments"
  env['LDFLAGS'] << " -arch x86_64"
when "aix"
  # -O2/O3 optimized away some configure test which caused ext libs to fail, so aix only gets -O
  #
  # We also need prezl's M4 instead of picking up /usr/bin/m4 which
  # barfs on ruby.
  #
  # I believe -qhot was necessary to prevent segfaults in threaded libs
  #
  env['CFLAGS'] << " -q64 -qhot"
  env['M4'] = "/opt/freeware/bin/m4"
  env['warnflags'] = "-qinfo=por"
else  # including solaris, linux
  env['CFLAGS'] << " -O3 -g -pipe"
end

build do
  configure_command = ["./configure",
                       "--prefix=#{install_dir}/embedded",
                       "--with-out-ext=dbm",
                       "--enable-shared",
                       "--enable-libedit",
                       "--with-ext=psych",
                       "--disable-install-doc",
                       "--without-gmp"]

  case Ohai['platform']
  when "aix"
    patch source: "ruby-aix-configure.patch", plevel: 1
    patch source: "ruby_aix_1_9_3_448_ssl_EAGAIN.patch", plevel: 1
    # our openssl-1.0.1h links against zlib and mkmf tests will fail due to zlib symbols not being
    # found if we do not include -lz.  this later leads to openssl functions being detected as not
    # being available and then internally vendored versions that have signature mismatches are pulled in
    # and the compile explodes.  this problem may not be unique to AIX, but is severe on AIX.
    patch source: "ruby_aix_openssl.patch", plevel: 1
    # --with-opt-dir causes ruby to send bogus commands to the AIX linker
  when "freebsd"
    configure_command << "--without-execinfo"
    configure_command << "--with-opt-dir=#{install_dir}/embedded"
  when "smartos"
    # Opscode patch - someara@opscode.com
    # GCC 4.7.0 chokes on mismatched function types between OpenSSL 1.0.1c and Ruby 1.9.3-p286
    patch source: "ruby-openssl-1.0.1c.patch", plevel: 1

    # Patches taken from RVM.
    # http://bugs.ruby-lang.org/issues/5384
    # https://www.illumos.org/issues/1587
    # https://github.com/wayneeseguin/rvm/issues/719
    patch source: "rvm-cflags.patch", plevel: 1

    # From RVM forum
    # https://github.com/wayneeseguin/rvm/commit/86766534fcc26f4582f23842a4d3789707ce6b96
    configure_command << "ac_cv_func_dl_iterate_phdr=no"
    configure_command << "--with-opt-dir=#{install_dir}/embedded"
  else
    configure_command << "--with-opt-dir=#{install_dir}/embedded"
  end

  # @todo: move into omnibus
  has_gmake = env['PATH'].split(File::PATH_SEPARATOR).any? do |path|
    File.executable?(File.join(path, 'gmake'))
  end

  if has_gmake
    env.merge!('MAKE' => 'gmake')
    make_binary = 'gmake'
  else
    make_binary = 'make'
  end

  # FFS: works around a bug that infects AIX when it picks up our pkg-config
  # AFAIK, ruby does not need or use this pkg-config it just causes the build to fail.
  # The alternative would be to patch configure to remove all the pkg-config garbage entirely
  env.merge!("PKG_CONFIG" => "/bin/true") if Ohai['platform'] == "aix"

  command configure_command.join(" "), env: env
  command "#{make_binary} -j #{max_build_jobs}", env: env
  command "#{make_binary} -j #{max_build_jobs} install", env: env
end
