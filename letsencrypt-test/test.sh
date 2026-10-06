#!/bin/bash

set -e

DEFAULT_IMAGE="gitlab/gitlab-ee:nightly"
IMAGE="${IMAGE:-$DEFAULT_IMAGE}"

CLEANUP="${CLEANUP:-1}"
GITLAB_POST_RECONFIGURE_SCRIPT="${GITLAB_POST_RECONFIGURE_SCRIPT-}"  # set to '' to disable

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
  wait_for_reconfigure gitlab 1200

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


# The container reports (healthy) as soon as its first health probe runs,
# which is before the initial reconfigure (and so the certificate) is done.
# Wait for the end of the reconfigure run itself instead.
wait_for_reconfigure() {
  local service="$1"
  local max="$2"
  local i=0

  echo "Waiting for $service to finish its initial reconfigure"
  until docker compose logs "$service" 2>/dev/null | grep -q "Reconfigured!"; do
    if [ -z "$(docker compose ps -q --status running "$service")" ]; then
      echo "$service stopped before the reconfigure finished"
      docker compose logs --tail 50 "$service"
      return 1
    fi
    i=$((i+1))
    [ "$i" -ge "$max" ] && { echo "$service did not finish reconfiguring after ${max}s"; return 1; }
    sleep 1
  done
}


main
