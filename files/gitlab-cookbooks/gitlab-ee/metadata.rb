name "gitlab-ee"
maintainer "GitLab Inc"
maintainer_email "support@gitlab.com"
license "Apache 2.0"
description "Install and configure GitLab EE from Omnibus"
long_description "Install and configure GitLab EE from Omnibus"
version "0.0.1"
recipe "gitlab", "Configures GitLab EE from Omnibus"

supports "ubuntu"
supports "centos"

depends "package"
depends "gitlab"
depends 'consul'
depends 'repmgr'
