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
default_version "494f5130f0df28566d88a4396d2f0fd7689b5ad4" # 7.7.1-ee

EE = system("#{Config.project_root}/support/is_gitlab_ee.sh")

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

source :git => "git@dev.gitlab.org:gitlab/gitlab-ee.git"

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
  bundle "install --without #{bundle_without.join(" ")} --path=#{install_dir}/embedded/service/gem --jobs #{max_build_jobs}", :env => env

  # In order to precompile the assets, we need to get to a state where rake can
  # load the Rails environment.
  command "cp config/gitlab.yml.example config/gitlab.yml"
  command "cp config/database.yml.postgresql config/database.yml"

  # There is a bug in the acts-as-taggable-on gem that makes
  # rake assets:precompile check for a database connection. We do not have a
  # database at this point so that is a problem. This bug is fixed in
  # acts-as-taggable-on 3.0.0 by
  # https://github.com/mbleigh/acts-as-taggable-on/commit/ad02dc9bb24ec8e1e79e7e35e2d4bb5910a66d8e
  aato_patch = "#{Config.project_root}/config/patches/acts-as-taggable-on-ad02dc9bb24ec8e1e79e7e35e2d4bb5910a66d8e.diff"

  # To make this idempotent, we apply the patch (in case this is a first run) or
  # we revert and re-apply the patch (if this is a second or later run).
  command "git apply #{aato_patch} || (git apply -R #{aato_patch} && git apply #{aato_patch})",
    :cwd => "#{install_dir}/embedded/service/gem/ruby/2.1.0/gems/acts-as-taggable-on-2.4.1"

  assets_precompile_env = {
    "RAILS_ENV" => "production",
    "PATH" => "#{install_dir}/embedded/bin:#{ENV['PATH']}"
  }
  bundle "exec rake assets:precompile", :env => assets_precompile_env

  # Tear down now that the assets:precompile is done.
  command "rm config/gitlab.yml config/database.yml .secret"

  # Remove directories that will be created by `gitlab-ctl reconfigure`
  command "rm -rf log tmp public/uploads"

  # Because db/schema.rb is modified by `rake db:migrate` after installation,
  # keep a copy of schema.rb around in case we need it. (I am looking at you,
  # mysql-postgresql-converter.)
  command "cp db/schema.rb db/schema.rb.bundled"

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
