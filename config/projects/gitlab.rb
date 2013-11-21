
name "gitlab"
maintainer "CHANGE ME"
homepage "CHANGEME.com"

replaces        "gitlab"
install_path    "/opt/gitlab"
build_version   Omnibus::BuildVersion.new.semver
build_iteration 1

# creates required build directories
dependency "preparation"

# gitlab dependencies/components
# dependency "somedep"

# version manifest file
dependency "version-manifest"

exclude "\.git*"
exclude "bundler\/git"
