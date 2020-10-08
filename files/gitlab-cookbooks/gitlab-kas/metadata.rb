name 'gitlab-kas'
maintainer 'GitLab.com'
maintainer_email 'support@gitlab.com'
license 'Apache 2.0'
description 'Installs/Configures GitLab KAS'
long_description 'Installs/Configures the GitLab Kubernetes Agent Server'
version '0.1.0'
chef_version '>= 12.1' if respond_to?(:chef_version)

issues_url 'https://gitlab.com/gitlab-org/omnibus-gitlab/issues'
source_url 'https://gitlab.com/gitlab-org/omnibus-gitlab'

depends 'package'
depends 'gitlab'
