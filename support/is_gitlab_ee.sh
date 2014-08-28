#!/bin/bash
[[ -n $ee ]] || grep -q '^source.*gitlab-ee.git"' config/software/gitlab-rails.rb
