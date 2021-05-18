#!/bin/bash

set -e

DEFAULT_IMAGE='registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/gitlab-ee:13.11.1-rfbranch.292570582.ad959b35-0'  # TODO change this to EE latest before merge
IMAGE="${IMAGE:-$DEFAULT_IMAGE}"

CLEANUP="${CLEANUP:-1}"
GITLAB_POST_RECONFIGURE_SCRIPT="${GITLAB_POST_RECONFIGURE_SCRIPT-'exit'}"  # set to '' to disable

cleanup() {
  local exitcode=$?

  [ "$CLEANUP" != "1" ] && { echo 'skipping cleanup'; exit $exitcode; }

  echo "exit code: $exitcode, running cleanup"
  docker-compose down
  exit $exitcode
}
trap cleanup EXIT


main() {
  export_vars
  start_pebble
  run_gitlab
}


export_vars() {
  export IMAGE
  export GITLAB_POST_RECONFIGURE_SCRIPT
}


start_pebble() {
  docker-compose up -d pebble challtestsrv
  curl -X POST -d '{"host":"gitlab.example.com", "addresses":["10.30.50.10"]}' \
    http://localhost:8055/add-a
}


run_gitlab() {
  docker-compose run --rm -T --service-ports gitlab
}


main
