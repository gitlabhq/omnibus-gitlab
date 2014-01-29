maintainer "GitLab.com"
maintainer_email "support@gitlab.com"
license "MIT"
description "Install and configure GitLab from Omnibus"
long_description "Install and configure GitLab from Omnibus"
version "0.0.1"
recipe "gitlab", "Configures GitLab from Omnibus"

supports "ubuntu"

depends "runit"
