#!/bin/bash
[[ -n $ee ]] || grep -q '^source.*"git@gitlab.com:subscribers/gitlab-ee.git"' config/software/gitlab-rails.rb
