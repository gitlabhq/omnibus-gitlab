#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2014 GitLab.com
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
require "#{Omnibus::Config.project_root}/lib/gitlab/version"

EE = system("#{Omnibus::Config.project_root}/support/is_gitlab_ee.sh")

software_name = EE ? 'gitlab-rails-ee' : 'gitlab-rails'
version = Gitlab::Version.new(software_name)

name 'gitlab-rails'

default_version version.print
source git: version.remote

combined_licenses_file = "#{install_dir}/embedded/lib/ruby/gems/gitlab-gem-licenses"
gemcontents_cmd = "#{install_dir}/embedded/bin/gem contents"

license 'MIT'
license_file 'LICENSE'
license_file combined_licenses_file

dependency 'ruby'
dependency 'bundler'
dependency 'libxml2'
dependency 'libxslt'
dependency 'curl'
dependency 'rsync'
dependency 'libicu'
dependency 'postgresql'
dependency 'python-docutils'
dependency 'krb5'
dependency 'registry'
dependency 'gitlab-pages'
dependency 'unzip'
dependency 'libre2'
dependency 'gpgme'
dependency 'graphicsmagick'

if EE
  dependency 'mysql-client'
  dependency 'pgbouncer'
  dependency 'repmgr'
  dependency 'gitlab-elasticsearch-indexer'
end

build do
  env = with_standard_compiler_flags(with_embedded_path)

  command "echo $(git log --pretty=format:'%h' -n 1) > REVISION"
  # Set installation type to omnibus
  command "echo 'omnibus-gitlab' > INSTALLATION_TYPE"

  bundle_without = %w(development test)
  bundle_without << 'mysql' unless EE
  bundle 'config build.rugged --no-use-system-libraries', env: env
  bundle 'config build.gpgme --use-system-libraries', env: env
  bundle "config build.nokogiri --use-system-libraries --with-xml2-dir=#{install_dir}/embedded --with-xslt-dir=#{install_dir}/embedded", env: env
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

    current_gem = shellout!("#{embedded_bin('bundle')} show | grep google-protobuf", env: env).stdout
    protobuf_version = current_gem[/google-protobuf \((.*)\)/, 1]
    shellout!("#{embedded_bin('gem')} uninstall --force google-protobuf", env: env)
    shellout!("#{embedded_bin('gem')} install google-protobuf --version #{protobuf_version} --platform=ruby", env: env)

    # Delete unused shared objects included in grpc gem
    grpc_path = shellout!("#{embedded_bin('bundle')} show grpc", env: env).stdout.strip
    ruby_ver = shellout!("#{embedded_bin('ruby')} -e 'puts RUBY_VERSION.match(/\\d+\\.\\d+/)[0]'", env: env).stdout.chomp
    command "find #{File.join(grpc_path, 'src/ruby/lib/grpc')} ! -path '*/#{ruby_ver}/*' -name 'grpc_c.so' -type f -print -delete"
  end

  # This patch makes the github-markup gem use and be compatible with Python3
  # We've sent part of the changes upstream: https://github.com/github/markup/pull/919
  patch_file_path = File.join(
    Omnibus::Config.project_root,
    'config',
    'patches',
    'gitlab-rails',
    'gitlab-markup_gem-markups.patch'
  )
  # Not using the patch DSL as we need the path to the gems directory
  command "cat #{patch_file_path} | patch -p1 \"$(#{gemcontents_cmd} gitlab-markup | grep lib/github/markups.rb)\""

  # In order to compile the assets, we need to get to a state where rake can
  # load the Rails environment.
  copy 'config/gitlab.yml.example', 'config/gitlab.yml'
  copy 'config/database.yml.postgresql', 'config/database.yml'
  copy 'config/secrets.yml.example', 'config/secrets.yml'

  # Copy asset cache and node modules from cache location to source directory
  move "#{Omnibus::Config.project_root}/assets_cache", "#{Omnibus::Config.source_dir}/gitlab-rails/tmp/cache"
  move "#{Omnibus::Config.project_root}/node_modules", "#{Omnibus::Config.source_dir}/gitlab-rails"

  assets_compile_env = {
    'NODE_ENV' => 'production',
    'RAILS_ENV' => 'production',
    'PATH' => "#{install_dir}/embedded/bin:#{ENV['PATH']}",
    'USE_DB' => 'false',
    'SKIP_STORAGE_VALIDATION' => 'true'
  }
  assets_compile_env['NO_SOURCEMAPS'] = 'true' if ENV['NO_SOURCEMAPS']
  command 'yarn install --pure-lockfile --production'

  # process PO files and generate MO and JSON files
  bundle 'exec rake gettext:compile', env: assets_compile_env

  # Up the default timeout from 10min to 4hrs for this command so it has the
  # opportunity to complete on the pi
  bundle 'exec rake gitlab:assets:compile', timeout: 14400, env: assets_compile_env

  # Sync assets to S3 bucket if ASSET_SYNC_ENABLED env variable is set
  # Disabled until we can use it in production. For details,
  # check https://gitlab.com/gitlab-org/distribution/team-tasks/issues/90
  # bundle 'exec rake assets:sync', env: assets_compile_env if ENV['ASSET_SYNC_ENABLED'] == 'true'

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

  # Remove directories that will be created by `gitlab-ctl reconfigure`
  delete 'log'
  delete 'tmp'
  delete 'public/uploads'

  # Cleanup after bundle
  # Delete all .gem archives
  command "find #{install_dir} -name '*.gem' -type f -print -delete"
  # Delete all docs
  command "find #{install_dir}/embedded/lib/ruby/gems -name 'doc' -type d -print -exec rm -r {} +"

  # Because db/schema.rb is modified by `rake db:migrate` after installation,
  # keep a copy of schema.rb around in case we need it. (I am looking at you,
  # mysql-postgresql-converter.)
  copy 'db/schema.rb', 'db/schema.rb.bundled'
  copy 'ee/db/geo/schema.rb', 'ee/db/geo/schema.rb.bundled' if EE

  command "mkdir -p #{install_dir}/embedded/service/gitlab-rails"
  sync './', "#{install_dir}/embedded/service/gitlab-rails/", exclude: %w(
    .git
    .gitignore
    spec
    features
    qa
    rubocop
    app/assets
    vendor/assets
    ee/app/assets
  )

  # This directory will be deleted after all the licenses copied to it are
  # handled by the DependencyInformation task of omnibus. It won't be part
  # of the final package, thus causing a redundancy.
  command "mkdir -p #{install_dir}/licenses"
  copy 'vendor/licenses.csv', "#{install_dir}/licenses/gitlab-rails.csv"

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

  # Generate the combined license file for all gems GitLab is using
  erb dest: "#{install_dir}/embedded/bin/gitlab-gem-license-generator",
      source: 'gem_license_generator.erb',
      mode: 0755,
      vars: { install_dir: install_dir, license_file: combined_licenses_file }

  command "#{install_dir}/embedded/bin/ruby #{install_dir}/embedded/bin/gitlab-gem-license-generator"
  delete "#{install_dir}/embedded/bin/gitlab-gem-license-generator"
end
