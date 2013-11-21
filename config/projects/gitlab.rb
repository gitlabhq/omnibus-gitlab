
name "gitlab"
maintainer "Achilleas Pipinellis"
homepage "http://gitlab.org"

replaces        "gitlab"
install_path    "/opt/gitlab"
build_version   Omnibus::BuildVersion.new.semver
build_iteration 1

# creates required build directories
dependency "preparation"

# gitlab dependencies/components
dependency "gitlab"

# version manifest file
dependency "version-manifest"

exclude "\.git*"
exclude "bundler\/git"
