name 'mattermost'
maintainer 'GitLab.com'
maintainer_email 'support@gitlab.com'
license 'Apache 2.0'
description 'Disables the legacy bundled Mattermost runit service.'
long_description 'Cleans up the runit service for the bundled Mattermost binary, which was removed in 19.0. To be deleted once the deprecation cycle ends.'
version '0.1.0'
chef_version '>= 12.1' if respond_to?(:chef_version)

depends 'package'

issues_url 'https://gitlab.com/gitlab-org/omnibus-gitlab/issues'
source_url 'https://gitlab.com/gitlab-org/omnibus-gitlab'
