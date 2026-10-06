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
  docker compose up -d gitlab
  wait_for_healthy gitlab 1200

  echo "Verifying the default RSA certificate key"
  docker compose exec -T gitlab openssl rsa \
    -in /etc/gitlab/ssl/gitlab.example.com.key -check -noout

  echo "Reconfiguring Let's Encrypt to use an EC certificate key"
  docker compose exec -T gitlab bash -c \
    "echo \"letsencrypt['key_type'] = 'ec'\" >> /etc/gitlab/gitlab.rb && gitlab-ctl reconfigure"

  echo "Verifying the EC certificate key"
  docker compose exec -T gitlab openssl ec \
    -in /etc/gitlab/ssl/gitlab.example.com.key -check -noout
}


wait_for_healthy() {
  local service="$1"
  local max="$2"
  local i=0

  echo "Waiting for $service to become healthy"
  while ! docker compose ps "$service" 2>/dev/null | grep -q "(healthy)"; do
    i=$((i+1))
    [ "$i" -ge "$max" ] && { echo "$service did not become healthy after ${max}s"; return 1; }
    sleep 1
  done
}


main
