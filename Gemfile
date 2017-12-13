source 'https://rubygems.org'

require_relative "lib/gitlab/version"

omnibus_gem_version = Gitlab::Version.new('omnibus', "gitlab-omnibus-ad5d3f98")

gem 'omnibus', git: omnibus_gem_version.remote, branch: omnibus_gem_version.print(false)
gem 'ohai'
gem 'package_cloud'
gem 'rainbow', '~> 2.1.0' # This is used by gitlab-ctl and the chef formatter
gem 'thor', '0.18.1' # This specific version is required by package_cloud
gem 'json'
gem 'rspec'
gem 'rake'
gem 'knapsack'
gem 'rubocop'
gem 'docker-api'
gem 'aws-sdk'
gem 'rubocop-rspec'
gem 'gitlab-qa'

group :test do
  gem 'byebug'
  gem 'chefspec'
  gem 'omnibus-ctl', '0.3.6'
  gem 'fantaskspec'
end
