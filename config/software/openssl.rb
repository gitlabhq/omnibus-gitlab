#
# Copyright 2012-2019, Chef Software Inc.
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

name 'openssl'

license 'OpenSSL'
license_file 'LICENSE'

skip_transitive_dependency_licensing true

dependency 'cacerts'

version = Gitlab::Version.new('openssl', 'OpenSSL_1_1_1g')

default_version version.print(false)
display_version version.print(false).delete_prefix('OpenSSL_').tr('_', '.')

source git: version.remote

build do
  env = with_standard_compiler_flags(with_embedded_path)
  if aix?
    env['M4'] = '/opt/freeware/bin/m4'
  elsif freebsd?
    # Should this just be in standard_compiler_flags?
    env['LDFLAGS'] += " -Wl,-rpath,#{install_dir}/embedded/lib"
  elsif windows?
    # XXX: OpenSSL explicitly sets -march=i486 and expects that to be honored.
    # It has OPENSSL_IA32_SSE2 controlling whether it emits optimized SSE2 code
    # and the 32-bit calling convention involving XMM registers is...  vague.
    # Do not enable SSE2 generally because the hand optimized assembly will
    # overwrite registers that mingw expects to get preserved.
    env['CFLAGS'] = "-I#{install_dir}/embedded/include"
    env['CPPFLAGS'] = env['CFLAGS']
    env['CXXFLAGS'] = env['CFLAGS']
  end

  configure_args = [
    "--prefix=#{install_dir}/embedded",
    'no-comp',
    'no-idea',
    'no-mdc2',
    'no-rc5',
    'no-ssl2',
    'no-ssl3',
    'no-zlib',
    'shared',
  ]

  configure_cmd =
    if aix?
      'perl ./Configure aix64-cc'
    elsif mac_os_x?
      './Configure darwin64-x86_64-cc'
    elsif smartos?
      '/bin/bash ./Configure solaris64-x86_64-gcc -static-libgcc'
    elsif omnios?
      '/bin/bash ./Configure solaris-x86-gcc'
    elsif solaris_11?
      platform = sparc? ? 'solaris64-sparcv9-gcc' : 'solaris64-x86_64-gcc'
      "/bin/bash ./Configure #{platform} -static-libgcc"
    elsif windows?
      platform = windows_arch_i386? ? 'mingw' : 'mingw64'
      "perl.exe ./Configure #{platform}"
    else
      prefix =
        if linux? && ppc64?
          './Configure linux-ppc64'
        elsif linux? && s390x?
          # With gcc > 4.3 on s390x there is an error building
          # with inline asm enabled
          './Configure linux64-s390x -DOPENSSL_NO_INLINE_ASM'
        else
          './config'
        end
      "#{prefix} disable-gost"
    end

  patch_env = if aix?
                # This enables omnibus to use 'makedepend'
                # from fileset 'X11.adt.imake' (AIX install media)
                env['PATH'] = "/usr/lpp/X11/bin:#{Gitlab::Util.get_env('PATH')}"
                penv = env.dup
                penv['PATH'] = "/opt/freeware/bin:#{env['PATH']}"
                penv
              else
                env
              end

  if windows?
    # Patch Makefile.org to update the compiler flags/options table for mingw.
    patch source: 'openssl-1.0.1q-fix-compiler-flags-table-for-msys.patch', env: env
  end

  # Out of abundance of caution, we put the feature flags first and then
  # the crazy platform specific compiler flags at the end.
  configure_args << env['CFLAGS'] << env['LDFLAGS']

  configure_command = configure_args.unshift(configure_cmd).join(' ')

  command configure_command, env: env, in_msys_bash: true

  patch source: 'openssl-1.0.1j-windows-relocate-dll.patch', env: env if windows?
  patch source: "openssl-1.1.1f-do-not-install-docs.patch", env: patch_env

  make 'depend', env: env
  # make -j N on openssl is not reliable
  make env: env
  if aix?
    # We have to sudo this because you can't actually run slibclean without being root.
    # Something in openssl changed in the build process so now it loads the libcrypto
    # and libssl libraries into AIX's shared library space during the first part of the
    # compile. This means we need to clear the space since it's not being used and we
    # can't install the library that is already in use. Ideally we would patch openssl
    # to make this not be an issue.
    # Bug Ref: http://rt.openssl.org/Ticket/Display.html?id=2986&user=guest&pass=guest
    command 'sudo /usr/sbin/slibclean', env: env
  end
  make 'install', env: env
end
