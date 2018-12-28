name 'crond'
maintainer 'GitLab.com'
maintainer_email 'support@gitlab.com'
license 'Apache-2.0'
description 'Installs/Configures go-crond for GitLab'
long_description 'Installs/Configures go-crond for GitLab'
version '0.1.0'
chef_version '>= 12.1' if respond_to?(:chef_version)

depends 'package'
depends 'gitlab'

issues_url 'https://gitlab.com/gitlab-org/omnibus-gitlab/issues'
source_url 'https://gitlab.com/gitlab-org/omnibus-gitlab'
