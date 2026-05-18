#!/usr/bin/env bats

OPENBAO_CONF="/var/opt/gitlab/nginx/conf/service_conf/gitlab-openbao.conf"

setup_file() {
  docker exec "${CONTAINER}" bash -c "
    mkdir -p /etc/gitlab
    cat > /etc/gitlab/gitlab.rb << 'GITLAB_RB'
external_url 'http://gitlab.example.com'
GITLAB_RB
    gitlab-ctl reconfigure
  "
  
  echo "---------------------------------" >&3
  echo "--- Without OAK configuration ---" >&3
  echo "---------------------------------" >&3
}

@test "OpenBao NGINX config file is absent without OAK configuration" {
  run docker exec "${CONTAINER}" test ! -f "${OPENBAO_CONF}"
  [ "$status" -eq 0 ]
}

@test "proxy is not active without OAK configuration" {
  run docker exec "${CONTAINER}" curl -s -o /dev/null -w "%{http_code}" \
    --header "Host: openbao.example.com" http://localhost:80/
  [ "$output" != "200" ]
}
