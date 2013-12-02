
name "gitlab"
maintainer "Achilleas Pipinellis"
homepage "http://gitlab.org"

replaces        "gitlab"
install_path    "/opt/gitlab"
build_version   6.3.0
build_iteration 1

# creates required build directories
dependency "preparation"

# GitLab dependencies/components
dependency "gitlab"

# version manifest file
dependency "version-manifest"

exclude "\.git*"
exclude "bundler\/git"
