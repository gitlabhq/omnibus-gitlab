#!/bin/bash

set -e

DEFAULT_IMAGE="gitlab/gitlab-ee:nightly"
IMAGE="${IMAGE:-$DEFAULT_IMAGE}"

CLEANUP="${CLEANUP:-1}"
GITLAB_POST_RECONFIGURE_SCRIPT="${GITLAB_POST_RECONFIGURE_SCRIPT-'exit'}"  # set to '' to disable

cleanup() {
  local exitcode=$?

  [ "$CLEANUP" != "1" ] && { echo 'skipping cleanup'; exit $exitcode; }

  echo "exit code: $exitcode, running cleanup"
  docker compose down
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
  docker compose up -d pebble challtestsrv
}


run_gitlab() {
  docker compose run --rm -T --service-ports gitlab
}


main
