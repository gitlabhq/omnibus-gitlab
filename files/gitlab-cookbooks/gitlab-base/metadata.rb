name 'gitlab-base'
maintainer 'GitLab Inc'
maintainer_email 'support@gitlab.com'
license 'Apache 2.0'
description "Interface cookbook for basic functionality of GitLab"
long_description "Interface cookbook for basic functionality of GitLab"
version '0.1.0'
chef_version '>= 12.1' if respond_to?(:chef_version)

issues_url 'https://gitlab.com/gitlab-org/omnibus-gitlab/issues'
source_url 'https://gitlab.com/gitlab-org/omnibus-gitlab'

depends 'package'

# We explicitly depend on gitlab and gitlab-ee until they are refactored and
# deals with only GitLab Rails
depends 'gitlab'
depends 'gitlab-ee' if Dir.exist?("#{File.expand_path('..', __dir__)}/gitlab-ee")

cookbooks = Dir.children(File.expand_path("..", __dir__)).select { |f| File.directory?(f) } - %w[package gitlab gitlab-ee]
cookbooks.each do |cookbook|
  depends cookbook
end
