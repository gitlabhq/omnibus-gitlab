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

software_name = EE ? "gitlab-rails-ee":"gitlab-rails"
version = Gitlab::Version.new(software_name)

name "gitlab-rails"

default_version version.print
source git: version.remote

combined_licenses_file = "#{install_dir}/embedded/service/gem/gitlab-gem-licenses"
gems_directory = "#{install_dir}/embedded/service/gem/ruby/2.3.0/gems"

license "MIT"
license_file "LICENSE"
license_file combined_licenses_file

dependency "ruby"
dependency "bundler"
dependency "libxml2"
dependency "libxslt"
dependency "curl"
dependency "rsync"
dependency "libicu"
dependency "postgresql"
dependency "postgresql_new"
dependency "python-docutils"
dependency "krb5"
dependency "registry"

if EE
  dependency "mysql-client"
  dependency "unzip"
  dependency "gitlab-pages"
end


build do
  env = with_standard_compiler_flags(with_embedded_path)

  # GitLab assumes it can extract the Git revision of the currently version
  # from the Git repo the code lives in at boot. Because of our sync later on,
  # this assumption does not hold. The sed command below patches the GitLab
  # source code to include the Git revision of the code included in the omnibus
  # build.
  command "sed -i \"s/.*REVISION.*/REVISION = '$(git log --pretty=format:'%h' -n 1)'/\" config/initializers/2_app.rb"
  command "echo $(git log --pretty=format:'%h' -n 1) > REVISION"

  bundle_without = %w{development test}
  bundle_without << "mysql" unless EE
  bundle "config build.rugged --no-use-system-libraries", :env => env
  bundle "install --without #{bundle_without.join(" ")} --path=#{install_dir}/embedded/service/gem --jobs #{workers} --retry 5", :env => env

  # This patch makes the github-markup gem use and be compatible with Python3
  # We've sent part of the changes upstream: https://github.com/github/markup/pull/919
  patch source: 'gitlab-markup_gem-markups.patch', target: "#{gems_directory}/gitlab-markup-1.5.0/lib/github/markups.rb"

  # In order to precompile the assets, we need to get to a state where rake can
  # load the Rails environment.
  copy 'config/gitlab.yml.example', 'config/gitlab.yml'
  copy 'config/database.yml.postgresql', 'config/database.yml'
  copy 'config/secrets.yml.example', 'config/secrets.yml'

  assets_precompile_env = {
    "RAILS_ENV" => "production",
    "PATH" => "#{install_dir}/embedded/bin:#{ENV['PATH']}",
    "USE_DB" => "false",
    "SKIP_STORAGE_VALIDATION" => "true"
  }
  bundle "exec rake assets:precompile", :env => assets_precompile_env

  # Tear down now that the assets:precompile is done.
  delete 'config/gitlab.yml'
  delete 'config/database.yml'
  delete 'config/secrets.yml'

  # Remove auto-generated files
  delete '.secret'
  delete '.gitlab_shell_secret'

  # Remove directories that will be created by `gitlab-ctl reconfigure`
  delete 'log'
  delete 'tmp'
  delete 'public/uploads'

  # Because db/schema.rb is modified by `rake db:migrate` after installation,
  # keep a copy of schema.rb around in case we need it. (I am looking at you,
  # mysql-postgresql-converter.)
  copy 'db/schema.rb', 'db/schema.rb.bundled'

  command "mkdir -p #{install_dir}/embedded/service/gitlab-rails"
  sync "./", "#{install_dir}/embedded/service/gitlab-rails/", { exclude: [".git", ".gitignore"]}

  # Create a wrapper for the rake tasks of the Rails app
  erb :dest => "#{install_dir}/bin/gitlab-rake",
    :source => "bundle_exec_wrapper.erb",
    :mode => 0755,
    :vars => {:command => 'rake "$@"', :install_dir => install_dir}

  # Create a wrapper for the rails command, useful for e.g. `rails console`
  erb :dest => "#{install_dir}/bin/gitlab-rails",
    :source => "bundle_exec_wrapper.erb",
    :mode => 0755,
    :vars => {:command => 'rails "$@"', :install_dir => install_dir}

  # Generate the combined license file for all gems GitLab is using
  erb dest: "#{install_dir}/embedded/bin/gitlab-gem-license-generator",
    source: "gem_license_generator.erb",
    mode: 0755,
    vars: {install_dir: install_dir, license_file: combined_licenses_file, gems_directory: gems_directory}

  command "#{install_dir}/embedded/bin/ruby #{install_dir}/embedded/bin/gitlab-gem-license-generator"
  delete "#{install_dir}/embedded/bin/gitlab-gem-license-generator"
end
