#!/bin/bash
[[ -n $cloud ]] || grep -q '^source.*"git@dev.gitlab.org:gitlab/gitlab-cloud.git"' config/software/gitlab-rails.rb
