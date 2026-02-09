require "#{Omnibus::Config.project_root}/lib/gitlab/ohai_helper.rb"

name 'valkey'

license 'BSD-3-Clause'
license_file 'COPYING'

skip_transitive_dependency_licensing true

dependency 'config_guess'
dependency 'openssl' unless Build::Check.use_system_ssl?

version = Gitlab::Version.new('valkey', '7.2.11')
default_version version.print(false)
source git: version.remote

# libatomic is a runtime_dependency of valkey for armhf/aarch64 platforms
if OhaiHelper.arm?
  whitelist_file "#{install_dir}/embedded/bin/valkey-benchmark"
  whitelist_file "#{install_dir}/embedded/bin/valkey-check-aof"
  whitelist_file "#{install_dir}/embedded/bin/valkey-check-rdb"
  whitelist_file "#{install_dir}/embedded/bin/valkey-cli"
  whitelist_file "#{install_dir}/embedded/bin/valkey-server"
end

build do
  env = with_standard_compiler_flags(with_embedded_path).merge(
    'PREFIX' => "#{install_dir}/embedded"
  )

  env['CFLAGS'] << ' -fno-omit-frame-pointer'

  # jemallocs page size must be >= to the runtime pagesize
  # Use large for arm/newer platforms based on debian rules:
  # https://salsa.debian.org/debian/jemalloc/-/blob/241fec81556098d6840e3684d2b4b69fea9258ef/debian/rules#L8-23
  env['JEMALLOC_CONFIGURE_OPTS'] = (OhaiHelper.arm64? ? ' --with-lg-page=16' : ' --with-lg-page=12')

  update_config_guess

  make_args = ['BUILD_TLS=yes']
  make "-j #{workers} #{make_args.join(' ')}", env: env

  # For now, we need both redis and valkey to coexist. Hence, skip the
  # symlinking of redis-* binaries to valkey-* counterparts.
  make "install USE_REDIS_SYMLINKS=no", env: env
end
