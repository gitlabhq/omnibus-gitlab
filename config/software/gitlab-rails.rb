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

name "gitlab-rails"
default_version "e3e32921a2016a2a80b17532a500b067e4568ba4" # CE 7.11.0

EE = system("#{Omnibus::Config.project_root}/support/is_gitlab_ee.sh")

dependency "ruby"
dependency "bundler"
dependency "libxml2"
dependency "libxslt"
dependency "curl"
dependency "rsync"
dependency "libicu"
dependency "postgresql"
dependency "python-docutils"
dependency "mysql-client" if EE
dependency "rugged"
dependency "krb5"

source :git => "https://gitlab.com/gitlab-org/gitlab-ce.git"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # GitLab assumes it can extract the Git revision of the currently version
  # from the Git repo the code lives in at boot. Because of our rsync later on,
  # this assumption does not hold. The sed command below patches the GitLab
  # source code to include the Git revision of the code included in the omnibus
  # build.
  command "sed -i \"s/.*REVISION.*/REVISION = '$(git log --pretty=format:'%h' -n 1)'/\" config/initializers/2_app.rb"

  bundle_without = %w{development test}
  bundle_without << "mysql" unless EE
  bundle "install --without #{bundle_without.join(" ")} --path=#{install_dir}/embedded/service/gem --jobs #{workers}", :env => env

  # In order to precompile the assets, we need to get to a state where rake can
  # load the Rails environment.
  copy 'config/gitlab.yml.example', 'config/gitlab.yml'
  copy 'config/database.yml.postgresql', 'config/database.yml'

  assets_precompile_env = {
    "RAILS_ENV" => "production",
    "PATH" => "#{install_dir}/embedded/bin:#{ENV['PATH']}"
  }
  bundle "exec rake assets:precompile", :env => assets_precompile_env

  # Tear down now that the assets:precompile is done.
  delete 'config/gitlab.yml'
  delete 'config/database.yml'

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
  command "#{install_dir}/embedded/bin/rsync -a --delete --exclude=.git/*** --exclude=.gitignore ./ #{install_dir}/embedded/service/gitlab-rails/"

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
end
