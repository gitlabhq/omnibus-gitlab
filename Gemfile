source 'https://rubygems.org'

require_relative "lib/gitlab/version"

omnibus_gem_version =  Gitlab::Version.new('omnibus', "omnibus-5-4-0")

gem 'omnibus', git: omnibus_gem_version.remote, branch: omnibus_gem_version.print(false)
gem 'omnibus-software', :git => 'git://github.com/opscode/omnibus-software.git', :branch => 'master'
gem 'ohai'
gem 'package_cloud'
gem 'thor', '0.18.1' # This specific version is required by package_cloud
gem 'json'
gem 'rspec'
gem 'rake'

group :test do
  gem 'byebug'
  gem 'chefspec'
end
