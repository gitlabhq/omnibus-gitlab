require "#{Omnibus::Config.project_root}/lib/gitlab/build/info"
require "#{Omnibus::Config.project_root}/lib/gitlab/build_iteration"
require "#{Omnibus::Config.project_root}/lib/gitlab/ohai_helper.rb"
require "#{Omnibus::Config.project_root}/lib/gitlab/openssl_helper"
require "#{Omnibus::Config.project_root}/lib/gitlab/util"
require "#{Omnibus::Config.project_root}/lib/gitlab/version"

name 'simple'
description 'Simple project to test omnibus changes'

maintainer 'GitLab, Inc. <support@gitlab.com>'
homepage 'https://about.gitlab.com/'

license 'MIT'

install_dir '/opt/simple'

dependency ''

build_version '0.1.1'
