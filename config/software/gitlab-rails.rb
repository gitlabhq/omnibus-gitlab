#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014-2021 GitLab Inc.
# License:: Apache License, Version 2.0
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
require 'yaml'
require "#{Omnibus::Config.project_root}/lib/gitlab/version"
require "#{Omnibus::Config.project_root}/lib/gitlab/ohai_helper.rb"

EE = Build::Check.include_ee?

software_name = EE ? 'gitlab-rails-ee' : 'gitlab-rails'
version = Gitlab::Version.new(software_name)
gitlab_bundle_gemfile = Gitlab::Util.get_env('GITLAB_BUNDLE_GEMFILE') || 'Gemfile'

name 'gitlab-rails'

default_version version.print
source git: version.remote

combined_licenses_file = "#{install_dir}/embedded/lib/ruby/gems/gitlab-gem-licenses"

license 'MIT'
license_file 'LICENSE'

# TODO: Compare contents of this file with the output of license_finder and
# tackle the missing ones and stop using this workaround.
# https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6517
license_file combined_licenses_file

dependency 'pkg-config-lite'
dependency 'bundler'
dependency 'rubygems'
dependency 'libxml2'
dependency 'libxslt'
dependency 'curl'
dependency 'rsync'
dependency 'libicu'
dependency 'postgresql'
dependency 'postgresql_new'
dependency 'python-docutils'
dependency 'krb5'
dependency 'registry'
dependency 'unzip'
dependency 'libre2'
dependency 'gpgme'
dependency 'graphicsmagick'
dependency 'exiftool'

if EE
  dependency 'pgbouncer'
  dependency 'patroni'
end

# libatomic is a runtime_dependency of the grpc gem for armhf/aarch64 platforms
whitelist_file /grpc_c\.so/ if OhaiHelper.arm?

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # Exclude rails directory from cache
  cache_dir = File.join('/var/cache/omnibus/cache/git_cache', install_dir, 'info/exclude')
  command "echo '/embedded/service/gitlab-rails' >> #{cache_dir}"

  command "echo $(git log --pretty=format:'%h' --abbrev=11 -n 1) > REVISION"
  # Set installation type to omnibus
  command "echo 'omnibus-gitlab' > INSTALLATION_TYPE"

  make "install -C workhorse PREFIX=#{install_dir}/embedded"

  bundle_without = %w(development test)
  bundle_without << 'mysql'

  if Build::Check.use_system_ssl?
    env['CMAKE_FLAGS'] = OpenSSLHelper.cmake_flags
    env['PKG_CONFIG_PATH'] = OpenSSLHelper.pkg_config_dirs
  end

  gem_source_compile_os = %w[
    el-8-aarch64
    amazon-2-aarch64
    debian-buster-aarch64
    raspbian-buster-aarch64
  ]

  # Currently rake-compiler-dock uses a Ubuntu 20.04 image to create the
  # native gem for the aarch64-linux platform. As a result, anything
  # using a glibc older than v2.29 will not work. We need to compile
  # gems for these platforms.
  bundle 'config force_ruby_platform true', env: env if gem_source_compile_os.include?(OhaiHelper.platform_dir)
  bundle 'config build.gpgme --use-system-libraries', env: env
  bundle "config build.nokogiri --use-system-libraries --with-xml2-include=#{install_dir}/embedded/include/libxml2 --with-xslt-include=#{install_dir}/embedded/include/libxslt", env: env
  bundle 'config build.grpc --with-ldflags="-latomic"', env: env if OhaiHelper.os_platform == 'raspbian'
  bundle "config set --local gemfile #{gitlab_bundle_gemfile}" if gitlab_bundle_gemfile != 'Gemfile'
  bundle "config set --local frozen 'true'"
  bundle "install --without #{bundle_without.join(' ')} --jobs #{workers} --retry 5", env: env

  block 'correct omniauth-jwt permissions' do
    # omniauth-jwt has some of its files 0600, make them 0644
    show = shellout!("#{embedded_bin('bundle')} show omniauth-jwt", env: env, returns: [0, 7])
    if show.exitstatus.zero?
      path = show.stdout.strip
      command "chmod -R g=u-w,o=u-w #{path}"
    end
  end

  # One of our gems, google-protobuf is known to have issues with older gcc versions
  # when using the pre-built extensions. We will remove it and rebuild it here.
  block 'reinstall google-protobuf gem' do
    require 'fileutils'

    unless gem_source_compile_os.include?(OhaiHelper.platform_dir)
      current_gem = shellout!("#{embedded_bin('bundle')} show | grep google-protobuf", env: env).stdout
      protobuf_version = current_gem[/google-protobuf \((.*)\)/, 1]
      shellout!("#{embedded_bin('gem')} uninstall --force google-protobuf", env: env)
      shellout!("#{embedded_bin('gem')} install google-protobuf --version #{protobuf_version} --platform=ruby", env: env)
    end

    # Delete unused shared objects included in grpc gem
    grpc_path = shellout!("#{embedded_bin('bundle')} show grpc", env: env).stdout.strip
    ruby_ver = shellout!("#{embedded_bin('ruby')} -e 'puts RUBY_VERSION.match(/\\d+\\.\\d+/)[0]'", env: env).stdout.chomp
    command "find #{File.join(grpc_path, 'src/ruby/lib/grpc')} ! -path '*/#{ruby_ver}/*' -name 'grpc_c.so' -type f -print -delete"
  end

  # In order to compile the assets, we need to get to a state where rake can
  # load the Rails environment.
  copy 'config/gitlab.yml.example', 'config/gitlab.yml'
  copy 'config/secrets.yml.example', 'config/secrets.yml'

  block 'render database.yml' do
    database_yml = YAML.safe_load(File.read("#{Omnibus::Config.source_dir}/gitlab-rails/config/database.yml.postgresql"))
    database_yml.each { |_, databases| databases.delete('geo') unless EE }

    File.write("#{Omnibus::Config.source_dir}/gitlab-rails/config/database.yml", YAML.dump(database_yml))
  end

  # Copy asset cache and node modules from cache location to source directory
  move "#{Omnibus::Config.project_root}/assets_cache", "#{Omnibus::Config.source_dir}/gitlab-rails/tmp/cache"
  move "#{Omnibus::Config.project_root}/node_modules", "#{Omnibus::Config.source_dir}/gitlab-rails"

  assets_compile_env = {
    'NODE_ENV' => 'production',
    'RAILS_ENV' => 'production',
    'PATH' => "#{install_dir}/embedded/bin:#{Gitlab::Util.get_env('PATH')}",
    'USE_DB' => 'false',
    'SKIP_STORAGE_VALIDATION' => 'true',
    'NODE_OPTIONS' => '--max_old_space_size=3584'
  }
  assets_compile_env['NO_SOURCEMAPS'] = 'true' if Gitlab::Util.get_env('NO_SOURCEMAPS')
  command 'yarn install --pure-lockfile --production'

  # process PO files and generate MO and JSON files
  bundle 'exec rake gettext:compile', env: assets_compile_env

  # By default, copy assets from the fetch-assets job
  # Compile from scratch if the COMPILE_ASSETS variable is set to to true
  if Gitlab::Util.get_env('COMPILE_ASSETS').eql?('true')
    # Up the default timeout from 10min to 4hrs for this command so it has the
    # opportunity to complete on the pi
    bundle 'exec rake gitlab:assets:compile', timeout: 14400, env: assets_compile_env
  else
    # Copy the asset files
    sync "#{Gitlab::Util.get_env('CI_PROJECT_DIR')}/#{Gitlab::Util.get_env('ASSET_PATH')}", 'public/assets/'
  end

  bundle "exec license_finder report --project_path=#{File.dirname(gitlab_bundle_gemfile)} --decisions-file=config/dependency_decisions.yml --format=json --columns name version licenses texts notice --save=rails-license.json", env: env
  command "license_finder report --decisions-file=#{Omnibus::Config.project_root}/support/dependency_decisions.yml --format=json --columns name version licenses texts notice --save=workhorse-license.json", cwd: "#{Omnibus::Config.source_dir}/gitlab-rails/workhorse"

  # Merge rails and workhorse license files.
  block "Merge license files of rails and workhorse" do
    require 'json'
    rails_licenses = JSON.parse(File.read("#{Omnibus::Config.source_dir}/gitlab-rails/rails-license.json"))['dependencies']
    workhorse_licenses = JSON.parse(File.read("#{Omnibus::Config.source_dir}/gitlab-rails/workhorse/workhorse-license.json"))['dependencies']
    output = { dependencies: rails_licenses.concat(workhorse_licenses).uniq }
    File.write("#{install_dir}/licenses/gitlab-rails.json", JSON.pretty_generate(output))
  end

  # Move folders for caching. GitLab CI permits only relative path for Cache
  # and Artifacts. So we need these folder in the root directory.
  move "#{Omnibus::Config.source_dir}/gitlab-rails/tmp/cache", "#{Omnibus::Config.project_root}/assets_cache"
  move "#{Omnibus::Config.source_dir}/gitlab-rails/node_modules", Omnibus::Config.project_root.to_s

  # Tear down now that gitlab:assets:compile is done.
  delete 'config/gitlab.yml'
  delete 'config/database.yml'
  delete 'config/secrets.yml'

  # Remove auto-generated files
  delete '.secret'
  delete '.gitlab_shell_secret'
  delete '.gitlab_workhorse_secret'
  delete '.gitlab_pages_secret'
  delete '.gitlab_kas_secret'
  delete '.gitlab_incoming_email_secret'
  delete '.gitlab_service_desk_email_secret'

  # Remove directories that will be created by `gitlab-ctl reconfigure`
  delete 'log'
  delete 'tmp'
  delete 'public/uploads'

  # Drop uncompressed sourcemap files. We will keep the gziped versions.
  command "find public/assets/webpack -name '*.map' -type f -print -delete"

  # Cleanup after bundle
  # Delete all .gem archives
  command "find #{install_dir} -name '*.gem' -type f -print -delete"
  # Delete all docs
  command "find #{install_dir}/embedded/lib/ruby/gems -name 'doc' -type d -print -exec rm -r {} +"

  # Because db/structure.sql is modified by `rake db:migrate` after installation,
  # keep a copy of structure.sql around in case we need it. (I am looking at you,
  # mysql-postgresql-converter.)
  copy 'db/structure.sql', 'db/structure.sql.bundled'
  copy 'ee/db/geo/structure.sql', 'ee/db/geo/structure.sql.bundled' if EE

  command "mkdir -p #{install_dir}/embedded/service/gitlab-rails"
  sync './', "#{install_dir}/embedded/service/gitlab-rails/", exclude: %w(
    .git
    .gitignore
    spec
    ee/spec
    features
    qa
    rubocop
    app/assets
    vendor/assets
    ee/app/assets
    workhorse
  )

  # Create a wrapper for the rake tasks of the Rails app
  erb dest: "#{install_dir}/bin/gitlab-rake",
      source: 'bundle_exec_wrapper.erb',
      mode: 0755,
      vars: { command: 'rake "$@"', install_dir: install_dir }

  # Create a wrapper for the rails command, useful for e.g. `rails console`
  erb dest: "#{install_dir}/bin/gitlab-rails",
      source: 'bundle_exec_wrapper.erb',
      mode: 0755,
      vars: { command: 'rails "$@"', install_dir: install_dir }

  # Create a wrapper for the rake command for backup and restore
  erb dest: "#{install_dir}/bin/gitlab-backup",
      source: 'rake_backup_wrapper.erb',
      mode: 0755,
      vars: { install_dir: install_dir }

  # Create a wrapper for the ruby command, useful for e.g. `ruby -e 'command'`
  erb dest: "#{install_dir}/bin/gitlab-ruby",
      source: 'bundle_exec_wrapper.erb',
      mode: 0755,
      vars: { command: 'ruby "$@"', install_dir: install_dir }

  # Generate the combined license file for all gems GitLab is using
  erb dest: "#{install_dir}/embedded/bin/gitlab-gem-license-generator",
      source: 'gem_license_generator.erb',
      mode: 0755,
      vars: { install_dir: install_dir, license_file: combined_licenses_file }

  command "#{install_dir}/embedded/bin/ruby #{install_dir}/embedded/bin/gitlab-gem-license-generator"
  delete "#{install_dir}/embedded/bin/gitlab-gem-license-generator"
end
