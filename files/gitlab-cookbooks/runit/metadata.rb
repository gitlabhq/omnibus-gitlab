name 'runit'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Installs runit and provides runit_service resource'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '5.1.3'

recipe 'runit', 'Installs and configures runit'

%w(ubuntu debian centos redhat amazon scientific oracle enterpriseenterprise zlinux).each do |os|
  supports os
end

source_url 'https://github.com/chef-cookbooks/runit'
issues_url 'https://github.com/chef-cookbooks/runit/issues'
chef_version '>= 12.1' if respond_to?(:chef_version)
