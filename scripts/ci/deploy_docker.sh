#!/bin/env bash

set -eo pipefail

image_registry=${image_registry:-gitlab}

if [ "${image_registry}" = "${CI_REGISTRY_IMAGE}" ] ; then
  docker login -u gitlab-ci-token -p ${CI_JOB_TOKEN} ${CI_REGISTRY}
fi

# Split the result from rake task at = and assign to two variables image_name
# and image_tag
IFS== read -r image_name image_tag <<< $(bundle exec rake build:package:name_version 2>&1 | tail -n1)

GITLAB_HOME=/tmp/gitlab
mkdir -p $GITLAB_HOME

docker run --detach \
  --hostname gitlab.example.com \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'" \
  --publish 443:443 --publish 80:80 --publish 2222:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  ${image_registry}/${image_name}:${image_tag}

if [ "${deploy_instance}" != "true" ]; then
  exit 0;
fi

function get_health {
  state=$(docker inspect -f '{{ .State.Health.Status }}' gitlab)
  return_code=$?
  if [ ! ${return_code} -eq 0 ]; then
    echo "Getting health status failed."
    exit 1
  fi

  if [ "${state}" = "healthy" ]; then
    return 0
  else
    return 1
  fi
}

# Do not fail on the `return 1` above.
set +e

echo "Wait for GitLab to be healthy"
for i in `seq 600`; do
  get_health
  state=$?

  if [ ${state} -eq 0 ]; then
    echo "GitLab is running successfully."
    exit 0
  fi

  sleep 1
done

echo "GitLab not healthy after 10 minutes. Health status returned: $(docker inspect -f '{{ .State.Health.Status }}' gitlab)"
exit 1
